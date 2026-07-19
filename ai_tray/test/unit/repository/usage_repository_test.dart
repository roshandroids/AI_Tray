import 'dart:convert';
import 'dart:io';

import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/logging/console_app_logger.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/providers/data/claude/claude_cli_adapter.dart';
import 'package:ai_tray/features/providers/data/process/fake_process_runner.dart';
import 'package:ai_tray/features/providers/data/process/process_runner.dart';
import 'package:ai_tray/features/settings/domain/models/app_settings.dart';
import 'package:ai_tray/features/settings/domain/repositories/settings_repository.dart';
import 'package:ai_tray/features/usage/data/cache/usage_cache.dart';
import 'package:ai_tray/features/usage/data/parsers/usage_parser.dart';
import 'package:ai_tray/features/usage/data/repositories/usage_repository_impl.dart';
import 'package:ai_tray/features/usage/data/services/refresh_service.dart';
import 'package:ai_tray/features/usage/data/validators/usage_validator.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_outcome.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_phase.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository(this.settings);

  AppSettings settings;

  @override
  Future<AppSettings> read() async => settings;

  @override
  Future<Result<Unit>> write(AppSettings value) async {
    settings = value;
    return const Result.success(Unit.unit);
  }
}

void main() {
  late FakeProcessRunner runner;
  late InMemoryUsageCache cache;
  late _FakeSettingsRepository settingsRepo;
  late UsageRepositoryImpl repository;
  late String shapeA;

  setUp(() {
    runner = FakeProcessRunner();
    cache = InMemoryUsageCache();
    settingsRepo = _FakeSettingsRepository(
      AppSettings(
        autoRefreshEnabled: false,
        refreshInterval: const Duration(seconds: 30),
        notificationsEnabled: false,
        launchAtLogin: false,
        showStaleIndicator: true,
      ),
    );
    shapeA = File(
      'test/fixtures/claude_usage/shape_a_with_rate_limits.txt',
    ).readAsStringSync();

    final logger = ConsoleAppLogger(defaultName: 'repo_test');
    final provider = ClaudeCliAdapter(processRunner: runner, logger: logger);
    repository = UsageRepositoryImpl(
      refreshService: RefreshService(
        provider: provider,
        parser: const UsageParser(),
        validator: UsageValidator(),
        cache: cache,
        logger: logger,
        softRetryDelay: Duration.zero,
        hardRetryDelay: Duration.zero,
      ),
      cache: cache,
      settingsRepository: settingsRepo,
      logger: logger,
      providerResolver: () => provider,
    );
  });

  tearDown(() {
    repository.dispose();
  });

  Map<String, dynamic> envelopeFor(String resultText) => {
    'type': 'result',
    'subtype': 'success',
    'is_error': false,
    'result': resultText,
    'total_cost_usd': 0,
    'duration_api_ms': 0,
  };

  test('refresh success updates status and cache', () async {
    runner.handler = (exe, args) {
      return Result.success(
        ProcessRunResult(
          exitCode: 0,
          stdout: jsonEncode(envelopeFor(shapeA)),
          stderr: '',
          duration: const Duration(milliseconds: 5),
        ),
      );
    };

    final result = await repository.refresh(manual: true);
    expect(result.status, RefreshOutcome.success);
    expect(repository.status.phase, RefreshPhase.idle);
    expect(repository.status.lastResult?.usage?.sessionUsedPercent, 2.0);
  });

  test('cli missing pauses auto-refresh', () async {
    settingsRepo.settings = AppSettings(
      autoRefreshEnabled: true,
      refreshInterval: const Duration(seconds: 30),
      notificationsEnabled: false,
      launchAtLogin: false,
      showStaleIndicator: true,
    );

    runner.handler = (exe, args) {
      return const Result.failure(
        AppFailure(
          code: FailureCode.cliNotInstalled,
          message: 'missing',
        ),
      );
    };

    final result = await repository.refresh(manual: true);
    expect(result.status, RefreshOutcome.failure);
    expect(result.error?.code, FailureCode.cliNotInstalled);
    expect(repository.status.nextScheduledAt, isNull);
  });

  test('timeout failure retains prior cache in result', () async {
    runner.handler = (exe, args) {
      return Result.success(
        ProcessRunResult(
          exitCode: 0,
          stdout: jsonEncode(envelopeFor(shapeA)),
          stderr: '',
          duration: Duration.zero,
        ),
      );
    };
    await repository.refresh(manual: true);

    runner.handler = (exe, args) {
      return const Result.failure(
        AppFailure(
          code: FailureCode.timeout,
          message: 'timeout',
        ),
      );
    };

    final result = await repository.refresh(manual: true);
    expect(result.status, RefreshOutcome.failure);
    expect(result.usage?.sessionUsedPercent, 2.0);
    expect(result.usage?.isFromCache, isTrue);
  });

  test('resume recovery refreshes once when schedule is overdue', () async {
    settingsRepo.settings = AppSettings(
      autoRefreshEnabled: true,
      refreshInterval: const Duration(seconds: 30),
      notificationsEnabled: false,
      launchAtLogin: false,
      showStaleIndicator: true,
    );
    var fetches = 0;
    runner.handler = (exe, args) {
      fetches += 1;
      return Result.success(
        ProcessRunResult(
          exitCode: 0,
          stdout: jsonEncode(envelopeFor(shapeA)),
          stderr: '',
          duration: Duration.zero,
        ),
      );
    };

    await repository.refresh(manual: true);
    expect(fetches, greaterThanOrEqualTo(1));
    final baseline = fetches;
    final overdue = DateTime.now().toUtc().add(const Duration(minutes: 1));
    await repository.recoverScheduleIfOverdue(now: overdue);
    expect(fetches, greaterThan(baseline));

    final afterOverdue = fetches;
    await repository.recoverScheduleIfOverdue(
      now: DateTime.now().toUtc().subtract(const Duration(seconds: 5)),
    );
    expect(fetches, afterOverdue);
  });
}
