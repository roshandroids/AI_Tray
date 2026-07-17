import 'package:ai_tray/features/providers/data/copilot/sdk/copilot_sdk.dart';
import 'package:ai_tray/features/providers/data/copilot/sdk/copilot_sdk_v1.dart';
import 'package:ai_tray/features/providers/data/copilot/sdk/sidecar_process_transport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps every protocol-v1 result into SDK-free domain models', () async {
    final transport = _FakeTransport({
      'quota.get': {
        'premium': quota(resetDate: '2026-08-01T00:00:00Z'),
        'chat': quota(entitlement: 0, overageAllowed: true),
        'completion': quota(entitlement: 0, overageAllowed: true),
      },
      'session.usage': {
        'sessionId': 'session-1',
        'totalPremiumRequestCost': 1.5,
        'totalUserRequests': 2,
        'totalApiDurationMs': 300,
        'sessionStartTime': '2026-07-16T00:00:00Z',
        'currentModel': 'gpt-test',
        'lastCallInputTokens': 40,
        'lastCallOutputTokens': 20,
      },
      'health.get': {
        'healthy': true,
        'authenticated': true,
        'message': 'ready',
        'checkedAt': '2026-07-16T01:00:00Z',
      },
      'version.get': {
        'protocolVersion': 1,
        'bridgeVersion': '1.0.0',
        'sdkVersion': '1.0.7',
        'cliVersion': '1.0.71',
      },
    });
    final sdk = CopilotSdkV1(transport: transport);

    await sdk.initialize();
    final quotaResult = await sdk.getQuota();
    final usage = await sdk.getSessionUsage('session-1');
    final health = await sdk.getHealth();
    final version = await sdk.getVersion();
    await sdk.shutdown();

    expect(quotaResult.premium.entitlementRequests, 300);
    expect(quotaResult.premium.reset?.at, DateTime.utc(2026, 8));
    expect(quotaResult.chat.isUnlimited, isTrue);
    expect(usage.totalPremiumRequestCost, 1.5);
    expect(usage.totalApiDuration, const Duration(milliseconds: 300));
    expect(health.authenticated, isTrue);
    expect(version.sdkVersion, '1.0.7');
    expect(transport.initialized, isTrue);
    expect(transport.stopped, isTrue);
    expect(transport.paramsByMethod['session.usage'], {
      'sessionId': 'session-1',
    });
  });

  test('rejects malformed and incompatible protocol responses', () async {
    final malformed = CopilotSdkV1(
      transport: _FakeTransport({
        'quota.get': {
          'premium': quota(remaining: 101),
          'chat': quota(),
          'completion': quota(),
        },
      }),
    );

    await expectLater(
      malformed.getQuota(),
      throwsA(
        isA<CopilotSdkException>().having(
          (error) => error.code,
          'code',
          CopilotSdkErrorCode.malformedResponse,
        ),
      ),
    );

    final incompatible = CopilotSdkV1(
      transport: _FakeTransport({
        'version.get': {
          'protocolVersion': 2,
          'bridgeVersion': '2.0.0',
          'sdkVersion': '1.0.7',
          'cliVersion': null,
        },
      }),
    );
    await expectLater(
      incompatible.getVersion(),
      throwsA(
        isA<CopilotSdkException>().having(
          (error) => error.code,
          'code',
          CopilotSdkErrorCode.protocolMismatch,
        ),
      ),
    );
  });
}

Map<String, Object?> quota({
  int entitlement = 300,
  double remaining = 90,
  bool overageAllowed = false,
  String? resetDate,
}) {
  return {
    'available': true,
    'entitlementRequests': entitlement,
    'usedRequests': 10,
    'remainingPercentage': remaining,
    'overage': 0,
    'overageAllowedWithExhaustedQuota': overageAllowed,
    'resetDate': resetDate,
  };
}

final class _FakeTransport implements SidecarTransport {
  _FakeTransport(this.responses);

  final Map<String, Object?> responses;
  bool initialized = false;
  bool stopped = false;
  final Map<String, Map<String, Object?>> paramsByMethod = {};

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<Object?> request(
    String method, {
    Map<String, Object?> params = const {},
    CopilotSdkCancellationToken? cancellationToken,
  }) async {
    paramsByMethod[method] = params;
    return responses[method];
  }

  @override
  Future<void> shutdown() async {
    stopped = true;
  }
}
