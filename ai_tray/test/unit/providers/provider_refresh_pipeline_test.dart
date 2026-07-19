import 'dart:async';

import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/logging/console_app_logger.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/providers/core/models/provider_id.dart';
import 'package:ai_tray/features/providers/core/models/provider_models.dart';
import 'package:ai_tray/features/providers/core/ports/provider_ports.dart';
import 'package:ai_tray/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:ai_tray/features/settings/domain/models/app_settings.dart';
import 'package:ai_tray/features/usage/data/cache/usage_cache.dart';
import 'package:ai_tray/features/usage/data/parsers/usage_parser.dart';
import 'package:ai_tray/features/usage/data/repositories/usage_repository_impl.dart';
import 'package:ai_tray/features/usage/data/services/refresh_service.dart';
import 'package:ai_tray/features/usage/data/validators/usage_validator.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_outcome.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_phase.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'single-flight is isolated by provider and retries are bounded',
    () async {
      final claudeGate = Completer<void>();
      final copilotGate = Completer<void>();
      var selected = _FakeProvider(
        id: ProviderId.claude,
        percent: 20,
        gate: claudeGate.future,
      );
      final service = _service(selected, () => selected);

      final claudeFirst = service.refresh(
        settings: AppSettings.defaults(),
        currentStatus: RefreshStatus.initial(),
      );
      final claudeSecond = service.refresh(
        settings: AppSettings.defaults(),
        currentStatus: RefreshStatus.initial(),
      );
      expect(identical(claudeFirst, claudeSecond), isTrue);

      selected = _FakeProvider(
        id: ProviderId.copilot,
        percent: 70,
        gate: copilotGate.future,
      );
      final copilot = service.refresh(
        settings: AppSettings.defaults(),
        currentStatus: RefreshStatus.initial(),
      );
      copilotGate.complete();
      expect((await copilot).providerId, ProviderId.copilot);
      claudeGate.complete();
      expect((await claudeFirst).providerId, ProviderId.claude);
    },
  );

  test('failure falls back only to the matching provider cache', () async {
    final cache = InMemoryUsageCache();
    final claude = _FakeProvider(id: ProviderId.claude, percent: 20);
    final copilot = _FakeProvider(id: ProviderId.copilot, percent: 70);
    var selected = claude;
    final service = _service(selected, () => selected, cache: cache);

    await service.refresh(
      settings: AppSettings.defaults(),
      currentStatus: RefreshStatus.initial(),
    );
    selected = copilot;
    await service.refresh(
      settings: AppSettings.defaults(),
      currentStatus: RefreshStatus.initial(),
    );
    copilot.failure = const AppFailure(
      code: FailureCode.notAuthenticated,
      message: 'signed out',
    );
    final fallback = await service.refresh(
      settings: AppSettings.defaults(),
      currentStatus: RefreshStatus.initial(),
    );

    expect(fallback.status, RefreshOutcome.failure);
    expect(fallback.usage?.providerId, ProviderId.copilot);
    expect(fallback.usage?.sessionUsedPercent, 70);
    expect(fallback.usage?.isFromCache, isTrue);
  });

  test(
    'repository rejects a refresh completed after provider switch',
    () async {
      final gate = Completer<void>();
      var selected = _FakeProvider(
        id: ProviderId.claude,
        percent: 20,
        gate: gate.future,
      );
      final cache = InMemoryUsageCache();
      final logger = ConsoleAppLogger(defaultName: 'pipeline_test');
      final repository = UsageRepositoryImpl(
        refreshService: _service(selected, () => selected, cache: cache),
        cache: cache,
        settingsRepository: InMemorySettingsRepository(
          AppSettings.defaults().copyWith(autoRefreshEnabled: false),
        ),
        logger: logger,
        providerResolver: () => selected,
      );
      addTearDown(repository.dispose);

      final stale = repository.refresh();
      await Future<void>.delayed(Duration.zero);
      selected = _FakeProvider(id: ProviderId.copilot, percent: 70);
      final current = repository.refresh();
      await current;
      gate.complete();
      await stale;

      expect(
        repository.status.lastResult?.providerId,
        ProviderId.copilot,
      );
      expect(
        repository.status.lastResult?.usage?.sessionUsedPercent,
        70,
      );
    },
  );

  test(
    'ABA Claude→Copilot→Claude rejects the original Claude completion',
    () async {
      final originalGate = Completer<void>();
      final latestGate = Completer<void>();
      var selected = _FakeProvider(
        id: ProviderId.claude,
        percent: 11,
        gate: originalGate.future,
      );
      final cache = InMemoryUsageCache();
      final repository = UsageRepositoryImpl(
        refreshService: _service(selected, () => selected, cache: cache),
        cache: cache,
        settingsRepository: InMemorySettingsRepository(
          AppSettings.defaults().copyWith(autoRefreshEnabled: false),
        ),
        logger: ConsoleAppLogger(defaultName: 'pipeline_test'),
        providerResolver: () => selected,
      );
      addTearDown(repository.dispose);

      final original = repository.refresh();
      await Future<void>.delayed(Duration.zero);

      selected = _FakeProvider(id: ProviderId.copilot, percent: 55);
      await repository.refresh();

      selected = _FakeProvider(
        id: ProviderId.claude,
        percent: 88,
        gate: latestGate.future,
      );
      final latest = repository.refresh();
      await Future<void>.delayed(Duration.zero);

      originalGate.complete();
      await original;
      expect(
        repository.status.lastResult?.usage?.sessionUsedPercent,
        isNot(11),
      );

      latestGate.complete();
      await latest;
      expect(repository.status.lastResult?.providerId, ProviderId.claude);
      expect(repository.status.lastResult?.usage?.sessionUsedPercent, 88);
    },
  );

  test(
    'dispose during refresh does not mutate status after completion',
    () async {
      final gate = Completer<void>();
      final selected = _FakeProvider(
        id: ProviderId.claude,
        percent: 42,
        gate: gate.future,
      );
      final cache = InMemoryUsageCache();
      final repository = UsageRepositoryImpl(
        refreshService: _service(selected, () => selected, cache: cache),
        cache: cache,
        settingsRepository: InMemorySettingsRepository(
          AppSettings.defaults().copyWith(autoRefreshEnabled: false),
        ),
        logger: ConsoleAppLogger(defaultName: 'pipeline_test'),
        providerResolver: () => selected,
      );

      final inFlight = repository.refresh();
      await Future<void>.delayed(Duration.zero);
      expect(repository.status.phase, RefreshPhase.refreshing);
      repository.dispose();
      gate.complete();
      await inFlight;

      expect(repository.status.phase, RefreshPhase.refreshing);
      expect(repository.status.lastResult, isNull);
    },
  );

  test('provider-scoped hard backoff does not transfer after switch', () async {
    final claude = _FakeProvider(id: ProviderId.claude, percent: 20);
    final copilot = _FakeProvider(id: ProviderId.copilot, percent: 70);
    var selected = claude;
    final cache = InMemoryUsageCache();
    final repository = UsageRepositoryImpl(
      refreshService: _service(selected, () => selected, cache: cache),
      cache: cache,
      settingsRepository: InMemorySettingsRepository(
        AppSettings.defaults().copyWith(
          autoRefreshEnabled: false,
          refreshInterval: const Duration(seconds: 30),
        ),
      ),
      logger: ConsoleAppLogger(defaultName: 'pipeline_test'),
      providerResolver: () => selected,
    );
    addTearDown(repository.dispose);

    claude.failure = const AppFailure(
      code: FailureCode.timeout,
      message: 'timeout',
    );
    for (var i = 0; i < 3; i++) {
      await repository.refresh();
    }
    expect(repository.status.consecutiveHardFailures, 3);
    expect(
      repository.status.nextScheduledAt!
          .difference(DateTime.now().toUtc())
          .inSeconds,
      greaterThanOrEqualTo(170),
    );

    selected = copilot;
    await repository.refresh();
    expect(repository.status.consecutiveHardFailures, 0);
    expect(
      repository.status.nextScheduledAt!
          .difference(DateTime.now().toUtc())
          .inSeconds,
      lessThan(60),
    );
  });

  test('switch during Claude retry keeps retries on Claude', () async {
    final firstGate = Completer<void>();
    final retryGate = Completer<void>();
    var attempt = 0;
    late _FakeProvider claude;
    claude = _FakeProvider(
      id: ProviderId.claude,
      percent: 20,
      onFetch: () async {
        attempt += 1;
        if (attempt == 1) {
          await firstGate.future;
          return const Result.failure(
            AppFailure(code: FailureCode.timeout, message: 'timeout'),
          );
        }
        await retryGate.future;
        return const Result.success(
          UsageRawFetch(
            stdout: 'Current session: 33% used · resets tomorrow',
            stderr: '',
            exitCode: 0,
            duration: Duration.zero,
          ),
        );
      },
    );
    var selected = claude as AIProvider;
    final service = RefreshService(
      provider: claude,
      providerResolver: () => selected,
      validator: UsageValidator(),
      cache: InMemoryUsageCache(),
      logger: ConsoleAppLogger(defaultName: 'pipeline_test'),
      softRetryDelay: Duration.zero,
      hardRetryDelay: const Duration(milliseconds: 5),
    );

    final claudeRefresh = service.refresh(
      settings: AppSettings.defaults(),
      currentStatus: RefreshStatus.initial(),
    );
    await Future<void>.delayed(Duration.zero);
    selected = _FakeProvider(id: ProviderId.copilot, percent: 70);
    firstGate.complete();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(attempt, greaterThanOrEqualTo(1));
    retryGate.complete();
    final result = await claudeRefresh;
    expect(result.providerId, ProviderId.claude);
    expect(result.usage?.sessionUsedPercent, 33);
    expect(attempt, 2);
  });
}

RefreshService _service(
  AIProvider provider,
  AIProvider Function() resolver, {
  UsageCache? cache,
}) {
  return RefreshService(
    provider: provider,
    providerResolver: resolver,
    validator: UsageValidator(),
    cache: cache ?? InMemoryUsageCache(),
    logger: ConsoleAppLogger(defaultName: 'pipeline_test'),
    softRetryDelay: Duration.zero,
    hardRetryDelay: Duration.zero,
  );
}

final class _FakeProvider implements AIProvider {
  _FakeProvider({
    required this.id,
    required this.percent,
    this.gate,
    this.onFetch,
  });

  final ProviderId id;
  final double percent;
  final Future<void>? gate;
  final Future<Result<UsageRawFetch>> Function()? onFetch;
  AppFailure? failure;

  @override
  ProviderId get providerId => id;

  @override
  String get displayName => id.value;

  @override
  String get sourceLabel => '${id.value} test';

  @override
  bool get enabled => true;

  @override
  ProviderCapabilities get capabilities => ProviderCapabilities.claude;

  @override
  ProviderUsageParser get parser => const UsageParser();

  @override
  String get limitsUnavailableMessage => 'Unavailable';

  @override
  Future<Result<UsageRawFetch>> fetchUsageRaw({
    ProviderExecutionConfig config = const ProviderExecutionConfig(),
  }) async {
    final custom = onFetch;
    if (custom != null) {
      return custom();
    }
    await gate;
    final currentFailure = failure;
    if (currentFailure != null) return Result.failure(currentFailure);
    return Result.success(
      UsageRawFetch(
        stdout: 'Current session: $percent% used · resets tomorrow',
        stderr: '',
        exitCode: 0,
        duration: Duration.zero,
      ),
    );
  }

  @override
  Future<Result<AuthHealth>> healthCheck({
    ProviderExecutionConfig config = const ProviderExecutionConfig(),
  }) async {
    final currentFailure = failure;
    if (currentFailure != null) return Result.failure(currentFailure);
    return Result.success(
      AuthHealth(loggedIn: true, checkedAt: DateTime.utc(2026, 7, 16)),
    );
  }
}
