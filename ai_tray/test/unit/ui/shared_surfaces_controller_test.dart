import 'dart:async';

import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/logging/buffered_app_logger.dart';
import 'package:ai_tray/core/logging/logging_providers.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/diagnostics/presentation/copilot_diagnostics_controller.dart';
import 'package:ai_tray/features/providers/copilot/diagnostics/copilot_diagnostics.dart';
import 'package:ai_tray/features/providers/copilot/sdk/copilot_sdk.dart';
import 'package:ai_tray/features/providers/core/models/provider_models.dart';
import 'package:ai_tray/features/providers/core/models/quota_models.dart';
import 'package:ai_tray/features/providers/provider_providers.dart';
import 'package:ai_tray/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:ai_tray/features/settings/domain/models/app_settings.dart';
import 'package:ai_tray/features/settings/domain/repositories/settings_repository.dart';
import 'package:ai_tray/features/settings/presentation/settings_controller.dart';
import 'package:ai_tray/features/settings/settings_providers.dart';
import 'package:ai_tray/features/usage/data/cache/usage_cache.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    SettingsNotifier.operationTimeout = const Duration(seconds: 10);
  });

  test('settings load, save, timeout, and retry recover cleanly', () async {
    SettingsNotifier.operationTimeout = const Duration(milliseconds: 40);
    final repository = _ControllableSettingsRepository();
    var launchCalls = 0;
    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(repository),
        applyLaunchAtLoginProvider.overrideWithValue((_) async {
          launchCalls += 1;
        }),
        applyPresentationSettingsProvider.overrideWithValue(() async {}),
        bufferedAppLoggerProvider.overrideWithValue(BufferedAppLogger()),
      ],
    );
    addTearDown(container.dispose);

    final loaded = await container.read(settingsControllerProvider.future);
    expect(loaded.copilotEnabled, isTrue);
    expect(
      container.read(settingsControllerProvider.notifier).lastSettings,
      loaded,
    );

    final updated = loaded.copyWith(copilotEnabled: false);
    expect(
      await container.read(settingsControllerProvider.notifier).save(updated),
      isTrue,
    );
    expect(launchCalls, 1);
    expect((await repository.read()).copilotEnabled, isFalse);

    repository.failWrite = true;
    expect(
      await container
          .read(settingsControllerProvider.notifier)
          .save(updated.copyWith(autoRefreshEnabled: false)),
      isFalse,
    );
    expect(
      container.read(settingsControllerProvider).error,
      isA<AppFailure>().having(
        (failure) => failure.code,
        'code',
        FailureCode.cacheUnavailable,
      ),
    );
    expect(
      container.read(settingsControllerProvider.notifier).lastSettings,
      updated,
    );

    repository
      ..failWrite = false
      ..writeCompleter = Completer<void>();
    final timeoutSave = container
        .read(settingsControllerProvider.notifier)
        .save(updated.copyWith(showStaleIndicator: false));
    expect(await timeoutSave, isFalse);
    expect(
      container.read(settingsControllerProvider).error,
      isA<AppFailure>().having(
        (failure) => failure.code,
        'code',
        FailureCode.timeout,
      ),
    );
    repository.writeCompleter?.complete();

    repository.readCompleter = Completer<void>();
    await container.read(settingsControllerProvider.notifier).retry();
    expect(container.read(settingsControllerProvider).hasError, isTrue);
    repository.readCompleter?.complete();

    repository.readCompleter = null;
    await container.read(settingsControllerProvider.notifier).retry();
    expect(container.read(settingsControllerProvider).hasValue, isTrue);
    expect(
      container.read(settingsControllerProvider).value!.copilotEnabled,
      isFalse,
    );
  });

  test(
    'copilot diagnostics notifier maps disabled success and failures',
    () async {
      final sdk = _DiagnosticsSdk();
      final service = CopilotDiagnosticsService(
        sdk: sdk,
        logger: BufferedAppLogger(),
        timeout: const Duration(milliseconds: 20),
        clock: () => DateTime.utc(2026, 7, 17),
      );

      final disabledContainer = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(
            InMemorySettingsRepository(
              AppSettings.defaults().copyWith(copilotEnabled: false),
            ),
          ),
          copilotDiagnosticsServiceProvider.overrideWithValue(service),
          bufferedAppLoggerProvider.overrideWithValue(BufferedAppLogger()),
        ],
      );
      addTearDown(disabledContainer.dispose);

      final disabled = await disabledContainer.read(
        copilotDiagnosticsProvider.future,
      );
      expect(disabled.providerEnabled, isFalse);
      expect(sdk.initializeCalls, 0);

      final enabledContainer = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(
            InMemorySettingsRepository(),
          ),
          copilotDiagnosticsServiceProvider.overrideWithValue(service),
          bufferedAppLoggerProvider.overrideWithValue(BufferedAppLogger()),
        ],
      );
      addTearDown(enabledContainer.dispose);

      final success = await enabledContainer.read(
        copilotDiagnosticsProvider.future,
      );
      expect(success.available, isTrue);
      expect(success.sdkVersion, '1.0.7');
      expect(success.authStatus, 'Authenticated');

      sdk.quota = Completer<QuotaSnapshot>().future;
      await enabledContainer.read(copilotDiagnosticsProvider.notifier).retry();
      final timedOut = enabledContainer.read(copilotDiagnosticsProvider).value;
      expect(timedOut, isNotNull);
      expect(timedOut!.available, isFalse);
      expect(timedOut.quotaRpcStatus, 'Timed out');
    },
  );
}

final class _ControllableSettingsRepository implements SettingsRepository {
  AppSettings _settings = AppSettings.defaults();
  bool failWrite = false;
  Completer<void>? readCompleter;
  Completer<void>? writeCompleter;

  @override
  Future<AppSettings> read() async {
    final gate = readCompleter;
    if (gate != null) await gate.future;
    return _settings;
  }

  @override
  Future<Result<Unit>> write(AppSettings settings) async {
    final gate = writeCompleter;
    if (gate != null) await gate.future;
    if (failWrite) {
      return const Result.failure(
        AppFailure(
          code: FailureCode.cacheUnavailable,
          message: "Couldn't save settings",
        ),
      );
    }
    _settings = settings;
    return const Result.success(Unit.unit);
  }
}

final class _DiagnosticsSdk implements CopilotSdk {
  int initializeCalls = 0;
  Future<QuotaSnapshot> quota = Future.value(_quota);

  @override
  Future<void> initialize() async => initializeCalls += 1;

  @override
  Future<QuotaSnapshot> getQuota({
    CopilotSdkCancellationToken? cancellationToken,
  }) => quota;

  @override
  Future<ProviderHealth> getHealth({
    CopilotSdkCancellationToken? cancellationToken,
  }) async {
    return ProviderHealth(
      healthy: true,
      authenticated: true,
      message: 'ready',
      checkedAt: DateTime.utc(2026, 7, 17),
    );
  }

  @override
  Future<VersionInfo> getVersion({
    CopilotSdkCancellationToken? cancellationToken,
  }) async {
    return const VersionInfo(
      protocolVersion: 1,
      bridgeVersion: '1.0.0',
      sdkVersion: '1.0.7',
    );
  }

  @override
  Future<SessionUsage> getSessionUsage(
    String sessionId, {
    CopilotSdkCancellationToken? cancellationToken,
  }) => throw UnimplementedError();

  @override
  Future<void> shutdown() async {}
}

const _quota = QuotaSnapshot(
  premium: PremiumQuota(
    available: true,
    entitlementRequests: 300,
    usedRequests: 30,
    remainingPercentage: 90,
    overage: 0,
    overageAllowedWithExhaustedQuota: false,
    reset: null,
  ),
  chat: ChatQuota(
    available: false,
    entitlementRequests: null,
    usedRequests: null,
    remainingPercentage: null,
    overage: null,
    overageAllowedWithExhaustedQuota: null,
    reset: null,
  ),
  completion: CompletionQuota(
    available: false,
    entitlementRequests: null,
    usedRequests: null,
    remainingPercentage: null,
    overage: null,
    overageAllowedWithExhaustedQuota: null,
    reset: null,
  ),
);
