import 'dart:convert';
import 'dart:io';

import 'package:ai_tray/core/logging/console_app_logger.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/providers/data/claude/claude_cli_adapter.dart';
import 'package:ai_tray/features/providers/data/process/fake_process_runner.dart';
import 'package:ai_tray/features/providers/data/process/process_runner.dart';
import 'package:ai_tray/features/settings/domain/models/app_settings.dart';
import 'package:ai_tray/features/usage/data/cache/usage_cache.dart';
import 'package:ai_tray/features/usage/data/parsers/usage_parser.dart';
import 'package:ai_tray/features/usage/data/services/refresh_service.dart';
import 'package:ai_tray/features/usage/data/validators/usage_validator.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_outcome.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_status.dart';
import 'package:flutter_test/flutter_test.dart';

/// Compressed long-running stability proxy (S-002).
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
        logger: ConsoleAppLogger(defaultName: 'stability'),
      ),
      parser: const UsageParser(),
      validator: UsageValidator(),
      cache: cache,
      logger: ConsoleAppLogger(defaultName: 'stability'),
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

  void respondWith(String text) {
    runner.handler = (exe, args) {
      return Result.success(
        ProcessRunResult(
          exitCode: 0,
          stdout: jsonEncode(envelopeFor(text)),
          stderr: '',
          duration: const Duration(milliseconds: 1),
        ),
      );
    };
  }

  test(
    '500 cycles: Shape A then sticky Shape B keep LKG, never invent %',
    () async {
      respondWith(shapeA);
      var status = RefreshStatus.initial();
      final first = await service.refresh(
        settings: AppSettings.defaults(),
        currentStatus: status,
      );
      expect(first.status, RefreshOutcome.success);
      status = status.copyWith(lastResult: first);

      respondWith(shapeB);
      var softs = 0;
      for (var i = 0; i < 250; i++) {
        final result = await service.refresh(
          settings: AppSettings.defaults(),
          currentStatus: status,
        );
        expect(result.status, RefreshOutcome.softFailure);
        expect(result.usage?.sessionUsedPercent, 2.0);
        expect(result.usage?.isFromCache, isTrue);
        softs++;
        status = status.copyWith(lastResult: result);
      }

      respondWith(shapeA);
      var successes = 0;
      for (var i = 0; i < 249; i++) {
        final result = await service.refresh(
          settings: AppSettings.defaults(),
          currentStatus: status,
        );
        expect(result.status, RefreshOutcome.success);
        expect(result.usage?.sessionUsedPercent, 2.0);
        expect(result.usage?.isFromCache, isFalse);
        successes++;
        status = status.copyWith(lastResult: result);
      }

      expect(softs, 250);
      expect(successes, 249);
      final cached = await cache.read();
      expect(cached.valueOrNull?.sessionUsedPercent, 2.0);
    },
  );

  test('single-flight coalesces concurrent refresh calls', () async {
    var starts = 0;
    runner.handler = (exe, args) async {
      starts++;
      await Future<void>.delayed(const Duration(milliseconds: 30));
      return Result.success(
        ProcessRunResult(
          exitCode: 0,
          stdout: jsonEncode(envelopeFor(shapeA)),
          stderr: '',
          duration: const Duration(milliseconds: 30),
        ),
      );
    };

    final settings = AppSettings.defaults();
    final status = RefreshStatus.initial();
    final results = await Future.wait([
      service.refresh(settings: settings, currentStatus: status),
      service.refresh(settings: settings, currentStatus: status),
      service.refresh(settings: settings, currentStatus: status),
    ]);

    expect(starts, 1);
    expect(results.map((r) => r.status), everyElement(RefreshOutcome.success));
  });
}
