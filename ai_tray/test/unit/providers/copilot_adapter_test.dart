import 'dart:async';

import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/logging/console_app_logger.dart';
import 'package:ai_tray/features/providers/copilot/adapter/copilot_adapter.dart';
import 'package:ai_tray/features/providers/copilot/sdk/copilot_sdk.dart';
import 'package:ai_tray/features/providers/core/models/provider_models.dart';
import 'package:ai_tray/features/providers/core/models/quota_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeCopilotSdk sdk;
  late CopilotSdkAdapter adapter;

  setUp(() {
    sdk = _FakeCopilotSdk();
    adapter = CopilotSdkAdapter(
      sdk: sdk,
      logger: ConsoleAppLogger(defaultName: 'copilot_adapter_test'),
      clock: () => DateTime.utc(2026, 7, 16, 12),
      timeout: const Duration(milliseconds: 30),
      retryPolicy: const CopilotRetryPolicy(delay: Duration.zero),
    );
  });

  test('lazily initializes and emits an app-owned quota envelope', () async {
    final result = await adapter.fetchUsageRaw();

    expect(result.isSuccess, isTrue);
    expect(sdk.initializeCalls, 1);
    expect(sdk.quotaCalls, 1);
    final envelope = result.valueOrNull!.envelopeJson!;
    expect(envelope['schema_version'], 1);
    expect(envelope['provider'], 'copilot');
    expect(result.valueOrNull!.stdout, isNot(contains('token')));
  });

  test(
    'coalesces concurrent initialization and bounds transient retry',
    () async {
      final gate = Completer<void>();
      sdk.initializeGate = gate.future;
      sdk.quotaErrors.add(
        const CopilotSdkException(
          code: CopilotSdkErrorCode.operationFailed,
          message: 'safe',
          retryable: true,
        ),
      );

      final first = adapter.fetchUsageRaw();
      final second = adapter.fetchUsageRaw();
      await Future<void>.delayed(Duration.zero);
      expect(sdk.initializeCalls, 1);
      gate.complete();

      expect((await first).isSuccess, isTrue);
      expect((await second).isSuccess, isTrue);
      expect(sdk.quotaCalls, 3);
    },
  );

  test('does not retry authentication and schema failures', () async {
    for (final entry in const [
      (CopilotSdkErrorCode.authenticationFailed, FailureCode.notAuthenticated),
      (CopilotSdkErrorCode.malformedResponse, FailureCode.unknownCliOutput),
    ]) {
      sdk.quotaErrors.add(
        CopilotSdkException(code: entry.$1, message: 'safe'),
      );
      expect((await adapter.fetchUsageRaw()).failureOrNull?.code, entry.$2);
    }
    expect(sdk.quotaCalls, 2);
  });

  test('times out, cancels, and stops after the retry bound', () async {
    sdk.quotaGate = Completer<QuotaSnapshot>().future;

    final result = await adapter.fetchUsageRaw();
    await Future<void>.delayed(Duration.zero);

    expect(result.failureOrNull?.code, FailureCode.timeout);
    expect(sdk.quotaCalls, 2);
    expect(sdk.cancelledTokens, 2);
  });

  test('maps health states and shuts down exactly once', () async {
    expect((await adapter.healthCheck()).valueOrNull?.loggedIn, isTrue);
    sdk.health = ProviderHealth(
      healthy: true,
      authenticated: false,
      message: 'signed out',
      checkedAt: DateTime.utc(2026, 7, 16),
    );
    expect(
      (await adapter.healthCheck()).failureOrNull?.code,
      FailureCode.notAuthenticated,
    );

    await adapter.shutdown();
    await adapter.shutdown();
    expect(sdk.shutdownCalls, 1);
  });
}

final class _FakeCopilotSdk implements CopilotSdk {
  int initializeCalls = 0;
  int quotaCalls = 0;
  int shutdownCalls = 0;
  int cancelledTokens = 0;
  Future<void>? initializeGate;
  Future<QuotaSnapshot>? quotaGate;
  final List<CopilotSdkException> quotaErrors = [];
  ProviderHealth health = ProviderHealth(
    healthy: true,
    authenticated: true,
    message: 'ready',
    checkedAt: DateTime.utc(2026, 7, 16),
  );

  @override
  Future<void> initialize() async {
    initializeCalls += 1;
    await initializeGate;
  }

  @override
  Future<QuotaSnapshot> getQuota({
    CopilotSdkCancellationToken? cancellationToken,
  }) async {
    quotaCalls += 1;
    if (cancellationToken != null) {
      unawaited(
        cancellationToken.whenCancelled.then((_) => cancelledTokens += 1),
      );
    }
    if (quotaErrors.isNotEmpty) throw quotaErrors.removeAt(0);
    return quotaGate ?? _quota;
  }

  @override
  Future<ProviderHealth> getHealth({
    CopilotSdkCancellationToken? cancellationToken,
  }) async => health;

  @override
  Future<SessionUsage> getSessionUsage(
    String sessionId, {
    CopilotSdkCancellationToken? cancellationToken,
  }) => throw UnimplementedError();

  @override
  Future<VersionInfo> getVersion({
    CopilotSdkCancellationToken? cancellationToken,
  }) => throw UnimplementedError();

  @override
  Future<void> shutdown() async => shutdownCalls += 1;
}

const _quota = QuotaSnapshot(
  premium: PremiumQuota(
    available: true,
    entitlementRequests: 300,
    usedRequests: 75,
    remainingPercentage: 75,
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
