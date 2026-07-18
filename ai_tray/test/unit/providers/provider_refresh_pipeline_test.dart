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
  });

  final ProviderId id;
  final double percent;
  final Future<void>? gate;
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
