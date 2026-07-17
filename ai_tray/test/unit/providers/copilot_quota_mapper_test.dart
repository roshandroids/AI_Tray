import 'package:ai_tray/features/providers/copilot/mapper/copilot_quota_mapper.dart';
import 'package:ai_tray/features/providers/copilot/sdk/copilot_sdk.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = CopilotQuotaMapper();

  test('maps finite, unlimited, and missing quota categories', () {
    final snapshot = mapper.mapResponse({
      'premium': _quota(resetDate: '2026-08-01T00:00:00-04:00'),
      'chat': _quota(entitlement: 0, overageAllowed: true),
    });

    expect(snapshot.premium.remainingPercentage, 75);
    expect(snapshot.premium.reset?.at, DateTime.utc(2026, 8, 1, 4));
    expect(snapshot.chat.isUnlimited, isTrue);
    expect(snapshot.completion.available, isFalse);
  });

  test('rejects malformed, non-finite, and out-of-range values', () {
    for (final invalid in <Object?>[
      'not-an-object',
      {
        'premium': _quota(remaining: double.nan),
      },
      {
        'premium': _quota(remaining: 101),
      },
      {
        'premium': _quota(resetDate: 'not-a-date'),
      },
    ]) {
      expect(
        () => mapper.mapResponse(invalid),
        throwsA(
          isA<CopilotSdkException>().having(
            (error) => error.code,
            'code',
            CopilotSdkErrorCode.malformedResponse,
          ),
        ),
      );
    }
  });

  test('distinguishes authentication and schema failures', () {
    expect(
      () => mapper.mapResponse({
        'error': {'code': 'authentication_expired'},
      }),
      throwsA(
        isA<CopilotSdkException>().having(
          (error) => error.code,
          'code',
          CopilotSdkErrorCode.authenticationExpired,
        ),
      ),
    );
    expect(
      () => mapper.mapResponse({'unexpected': true}),
      throwsA(
        isA<CopilotSdkException>().having(
          (error) => error.code,
          'code',
          CopilotSdkErrorCode.schemaChanged,
        ),
      ),
    );
    expect(
      () => mapper.mapResponse({
        'premium': {
          'available': true,
          'entitlementRequests': 300,
        },
      }),
      throwsA(
        isA<CopilotSdkException>().having(
          (error) => error.code,
          'code',
          CopilotSdkErrorCode.schemaChanged,
        ),
      ),
    );
  });
}

Map<String, Object?> _quota({
  int entitlement = 300,
  double remaining = 75,
  bool overageAllowed = false,
  String? resetDate,
}) {
  return {
    'available': true,
    'entitlementRequests': entitlement,
    'usedRequests': 25,
    'remainingPercentage': remaining,
    'overage': 0,
    'overageAllowedWithExhaustedQuota': overageAllowed,
    'resetDate': resetDate,
  };
}
