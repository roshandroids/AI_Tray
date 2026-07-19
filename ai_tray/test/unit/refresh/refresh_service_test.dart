import 'dart:convert';
import 'dart:io';

import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/logging/app_logger.dart';
import 'package:ai_tray/core/logging/console_app_logger.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/providers/data/claude/claude_cli_adapter.dart';
import 'package:ai_tray/features/providers/data/process/fake_process_runner.dart';
import 'package:ai_tray/features/providers/data/process/process_runner.dart';
import 'package:ai_tray/features/providers/domain/models/provider_id.dart';
import 'package:ai_tray/features/settings/domain/models/app_settings.dart';
import 'package:ai_tray/features/usage/data/cache/usage_cache.dart';
import 'package:ai_tray/features/usage/data/parsers/usage_parser.dart';
import 'package:ai_tray/features/usage/data/services/refresh_service.dart';
import 'package:ai_tray/features/usage/data/validators/usage_validator.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_outcome.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_status.dart';
import 'package:ai_tray/features/usage/domain/models/usage_info.dart';
import 'package:ai_tray/features/usage/domain/models/usage_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeProcessRunner runner;
  late InMemoryUsageCache cache;
  late RefreshService service;
  late String shapeA;
  late String shapeB;

  setUp(() {
    runner = FakeProcessRunner();
    cache = InMemoryUsageCache();
    shapeA = File(
      'test/fixtures/claude_usage/shape_a_with_rate_limits.txt',
    ).readAsStringSync();
    shapeB = File(
      'test/fixtures/claude_usage/shape_b_contribution_only.txt',
    ).readAsStringSync();
    service = RefreshService(
      provider: ClaudeCliAdapter(
        processRunner: runner,
        logger: ConsoleAppLogger(defaultName: 'test'),
      ),
      parser: const UsageParser(),
      validator: UsageValidator(),
      cache: cache,
      logger: ConsoleAppLogger(defaultName: 'test'),
      softRetryDelay: Duration.zero,
      hardRetryDelay: Duration.zero,
    );
  });

  Map<String, dynamic> envelopeFor(String resultText) => {
    'type': 'result',
    'subtype': 'success',
    'is_error': false,
    'result': resultText,
    'total_cost_usd': 0,
    'duration_api_ms': 0,
  };

  test('Shape A success writes cache', () async {
    runner.handler = (exe, args) {
      expect(args, contains('/usage'));
      expect(args, isNot(contains('--bare')));
      return Result.success(
        ProcessRunResult(
          exitCode: 0,
          stdout: jsonEncode(envelopeFor(shapeA)),
          stderr: '',
          duration: const Duration(milliseconds: 10),
        ),
      );
    };

    final result = await service.refresh(
      settings: AppSettings.defaults(),
      currentStatus: RefreshStatus.initial(),
    );

    expect(result.status, RefreshOutcome.success);
    expect(result.usage?.sessionUsedPercent, 2.0);
    expect(result.usage?.isFromCache, isFalse);
    final cached = await cache.read();
    expect(cached.valueOrNull?.sessionUsedPercent, 2.0);
  });

  test('Shape B softFailure keeps LKG cache', () async {
    await cache.write(
      UsageInfo(
        sessionUsedPercent: 11,
        fetchedAt: DateTime.utc(2026, 7, 1),
        source: UsageSource.cli,
        isFromCache: true,
        providerId: ProviderId.claude,
      ),
    );

    runner.handler = (exe, args) {
      return Result.success(
        ProcessRunResult(
          exitCode: 0,
          stdout: jsonEncode(envelopeFor(shapeB)),
          stderr: '',
          duration: const Duration(milliseconds: 10),
        ),
      );
    };

    final result = await service.refresh(
      settings: AppSettings.defaults(),
      currentStatus: RefreshStatus.initial(),
    );

    expect(result.status, RefreshOutcome.softFailure);
    expect(result.error?.code, FailureCode.incompleteOutput);
    expect(result.usage?.sessionUsedPercent, 11);
    expect(result.usage?.isFromCache, isTrue);
  });

  test('timeout hard failure keeps LKG after prior success', () async {
    runner.handler = (exe, args) {
      return Result.success(
        ProcessRunResult(
          exitCode: 0,
          stdout: jsonEncode(envelopeFor(shapeA)),
          stderr: '',
          duration: const Duration(milliseconds: 10),
        ),
      );
    };
    await service.refresh(
      settings: AppSettings.defaults(),
      currentStatus: RefreshStatus.initial(),
    );

    runner.handler = (exe, args) {
      return const Result.failure(
        AppFailure(
          code: FailureCode.timeout,
          message: 'timed out',
        ),
      );
    };

    final result = await service.refresh(
      settings: AppSettings.defaults(),
      currentStatus: RefreshStatus.initial(),
    );

    expect(result.status, RefreshOutcome.failure);
    expect(result.error?.code, FailureCode.timeout);
    expect(result.usage?.sessionUsedPercent, 2.0);
  });

  test('unknown output does not write invented cache', () async {
    runner.handler = (exe, args) {
      return Result.success(
        ProcessRunResult(
          exitCode: 0,
          stdout: jsonEncode(envelopeFor('Total cost: \$0\nUsage: 0 input')),
          stderr: '',
          duration: Duration.zero,
        ),
      );
    };

    final result = await service.refresh(
      settings: AppSettings.defaults(),
      currentStatus: RefreshStatus.initial(),
    );

    expect(result.status, RefreshOutcome.failure);
    expect(result.error?.code, FailureCode.unknownCliOutput);
    final cached = await cache.read();
    expect(cached.valueOrNull, isNull);
  });

  test('cache write failure is logged and refresh still succeeds', () async {
    final logger = _RecordingLogger();
    final failingCache = _FailingWriteCache();
    service = RefreshService(
      provider: ClaudeCliAdapter(
        processRunner: runner,
        logger: ConsoleAppLogger(defaultName: 'test'),
      ),
      parser: const UsageParser(),
      validator: UsageValidator(),
      cache: failingCache,
      logger: logger,
      softRetryDelay: Duration.zero,
      hardRetryDelay: Duration.zero,
    );
    runner.handler = (exe, args) {
      return Result.success(
        ProcessRunResult(
          exitCode: 0,
          stdout: jsonEncode(envelopeFor(shapeA)),
          stderr: '',
          duration: const Duration(milliseconds: 10),
        ),
      );
    };

    final result = await service.refresh(
      settings: AppSettings.defaults(),
      currentStatus: RefreshStatus.initial(),
    );

    expect(result.status, RefreshOutcome.success);
    expect(result.usage?.sessionUsedPercent, 2.0);
    expect(
      logger.messages.any((m) => m.contains('operation=cache_write')),
      isTrue,
    );
  });
}

final class _FailingWriteCache implements UsageCache {
  @override
  Future<Result<UsageInfo?>> read({ProviderId? providerId}) async {
    return const Result.success(null);
  }

  @override
  Future<Result<Unit>> write(UsageInfo usage) async {
    return const Result.failure(
      AppFailure(
        code: FailureCode.cacheUnavailable,
        message: 'write failed',
      ),
    );
  }

  @override
  Future<Result<Unit>> clear({ProviderId? providerId}) async {
    return const Result.success(Unit.unit);
  }
}

final class _RecordingLogger implements AppLogger {
  final List<String> messages = [];

  @override
  void debug(
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
  }) {
    messages.add(message);
  }

  @override
  void info(
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
  }) {
    messages.add(message);
  }

  @override
  void warning(
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
  }) {
    messages.add(message);
  }

  @override
  void error(
    String message, {
    String? name,
    Object? error,
    StackTrace? stackTrace,
    AppFailure? failure,
  }) {
    messages.add(message);
  }
}
