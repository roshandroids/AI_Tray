import 'dart:async';

import 'package:ai_tray/core/logging/console_app_logger.dart';
import 'package:ai_tray/features/providers/copilot/diagnostics/copilot_diagnostics.dart';
import 'package:ai_tray/features/providers/copilot/sdk/copilot_sdk.dart';
import 'package:ai_tray/features/providers/core/cache/provider_cache.dart';
import 'package:ai_tray/features/providers/core/models/provider_id.dart';
import 'package:ai_tray/features/providers/core/models/provider_models.dart';
import 'package:ai_tray/features/providers/core/models/quota_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'metadata cache coalesces, expires, and never retains failures',
    () async {
      var now = DateTime.utc(2026, 7, 16);
      var loads = 0;
      final cache = ProviderMetadataCache<int>(
        ttl: const Duration(minutes: 1),
        clock: () => now,
      );

      Future<int> load() async {
        loads += 1;
        return 7;
      }

      expect(
        await Future.wait([
          cache.getOrLoad(ProviderId.copilot, load),
          cache.getOrLoad(ProviderId.copilot, load),
        ]),
        [7, 7],
      );
      expect(loads, 1);
      expect(await cache.getOrLoad(ProviderId.copilot, load), 7);
      expect(loads, 1);

      now = now.add(const Duration(minutes: 2));
      expect(await cache.getOrLoad(ProviderId.copilot, load), 7);
      expect(loads, 2);

      cache.invalidate();
      await expectLater(
        cache.getOrLoad(
          ProviderId.copilot,
          () => Future.error(StateError('x')),
        ),
        throwsStateError,
      );
      expect(cache.read(ProviderId.copilot), isNull);
    },
  );

  test(
    'pure diagnostics covers disabled, success, and timeout states',
    () async {
      final sdk = _DiagnosticsSdk();
      final service = CopilotDiagnosticsService(
        sdk: sdk,
        logger: ConsoleAppLogger(defaultName: 'diagnostics_test'),
        timeout: const Duration(milliseconds: 10),
        clock: () => DateTime.utc(2026, 7, 16),
      );

      final disabled = await service.inspect(enabled: false);
      expect(disabled.providerEnabled, isFalse);
      expect(sdk.initializeCalls, 0);

      final available = await service.inspect(enabled: true);
      expect(available.available, isTrue);
      expect(available.authStatus, 'Authenticated');
      expect(available.sdkVersion, '1.0.7');

      sdk.quota = Completer<QuotaSnapshot>().future;
      final timeout = await service.inspect(enabled: true, forceRefresh: true);
      expect(timeout.available, isFalse);
      expect(timeout.quotaRpcStatus, 'Timed out');
    },
  );
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
      checkedAt: DateTime.utc(2026, 7, 16),
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
