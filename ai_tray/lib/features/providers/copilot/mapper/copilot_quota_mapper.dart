import 'package:ai_tray/features/providers/copilot/models/copilot_protocol_v1_dto.dart';
import 'package:ai_tray/features/providers/copilot/sdk/copilot_sdk.dart';
import 'package:ai_tray/features/providers/core/models/quota_models.dart';

/// Maps protocol-v1 DTOs into validated, SDK-independent quota models.
final class CopilotQuotaMapper {
  const CopilotQuotaMapper();

  /// Validates an unknown protocol result before constructing domain models.
  QuotaSnapshot mapResponse(Object? response) {
    if (response is! Map<String, Object?>) {
      throw _malformed('quota response');
    }
    _throwAuthenticationError(response['error']);
    if (!response.containsKey('premium') &&
        !response.containsKey('chat') &&
        !response.containsKey('completion')) {
      throw const CopilotSdkException(
        code: CopilotSdkErrorCode.schemaChanged,
        message: 'Copilot quota response schema is unsupported',
      );
    }
    return mapDto(CopilotQuotaResponseDto.fromJson(response));
  }

  /// Maps an allowlisted DTO, treating absent categories as unavailable.
  QuotaSnapshot mapDto(CopilotQuotaResponseDto dto) {
    final premium = _fields(dto.premium, 'premium');
    final chat = _fields(dto.chat, 'chat');
    final completion = _fields(dto.completion, 'completion');
    return QuotaSnapshot(
      premium: PremiumQuota(
        available: premium.available,
        entitlementRequests: premium.entitlementRequests,
        usedRequests: premium.usedRequests,
        remainingPercentage: premium.remainingPercentage,
        overage: premium.overage,
        overageAllowedWithExhaustedQuota:
            premium.overageAllowedWithExhaustedQuota,
        reset: premium.reset,
      ),
      chat: ChatQuota(
        available: chat.available,
        entitlementRequests: chat.entitlementRequests,
        usedRequests: chat.usedRequests,
        remainingPercentage: chat.remainingPercentage,
        overage: chat.overage,
        overageAllowedWithExhaustedQuota: chat.overageAllowedWithExhaustedQuota,
        reset: chat.reset,
      ),
      completion: CompletionQuota(
        available: completion.available,
        entitlementRequests: completion.entitlementRequests,
        usedRequests: completion.usedRequests,
        remainingPercentage: completion.remainingPercentage,
        overage: completion.overage,
        overageAllowedWithExhaustedQuota:
            completion.overageAllowedWithExhaustedQuota,
        reset: completion.reset,
      ),
    );
  }

  _QuotaFields _fields(Object? value, String category) {
    if (value == null) return const _QuotaFields.unavailable();
    if (value is! Map<String, Object?>) {
      throw _malformed('$category quota');
    }
    if (value['available'] == false) {
      return const _QuotaFields.unavailable();
    }
    if (value['available'] != true) {
      throw _schema('$category.available');
    }

    final entitlement = _nonNegativeInteger(value, 'entitlementRequests');
    final used = _nonNegativeInteger(value, 'usedRequests');
    final remaining = _finiteNumber(value, 'remainingPercentage');
    final overage = _nonNegativeInteger(value, 'overage');
    final overageAllowed = value['overageAllowedWithExhaustedQuota'];
    if (remaining < 0 || remaining > 100) {
      throw _malformed('$category.remainingPercentage');
    }
    if (overageAllowed is! bool) {
      throw _schema('$category.overageAllowedWithExhaustedQuota');
    }

    return _QuotaFields(
      available: true,
      entitlementRequests: entitlement,
      usedRequests: used,
      remainingPercentage: remaining,
      overage: overage,
      overageAllowedWithExhaustedQuota: overageAllowed,
      reset: _reset(value['resetDate'], category),
    );
  }

  int _nonNegativeInteger(Map<String, Object?> map, String key) {
    if (!map.containsKey(key)) throw _schema(key);
    final value = map[key];
    final integer = switch (value) {
      int() => value,
      double() when value.isFinite && value == value.roundToDouble() =>
        value.toInt(),
      _ => throw _malformed(key),
    };
    if (integer < 0) throw _malformed(key);
    return integer;
  }

  double _finiteNumber(Map<String, Object?> map, String key) {
    if (!map.containsKey(key)) throw _schema(key);
    final value = map[key];
    if (value is! num || !value.isFinite) throw _malformed(key);
    return value.toDouble();
  }

  QuotaReset? _reset(Object? value, String category) {
    if (value == null) return null;
    if (value is! String || value.trim().isEmpty) {
      throw _malformed('$category.resetDate');
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) throw _malformed('$category.resetDate');
    return QuotaReset(at: parsed.toUtc());
  }

  void _throwAuthenticationError(Object? value) {
    if (value is! Map<String, Object?> || value['code'] is! String) return;
    final code = value['code']! as String;
    if (code == 'authentication_failed' || code == 'authentication_expired') {
      throw CopilotSdkException(
        code: code == 'authentication_expired'
            ? CopilotSdkErrorCode.authenticationExpired
            : CopilotSdkErrorCode.authenticationFailed,
        message: 'Copilot authentication is required',
      );
    }
  }

  CopilotSdkException _schema(String field) {
    return CopilotSdkException(
      code: CopilotSdkErrorCode.schemaChanged,
      message: 'Copilot quota field "$field" is missing or unsupported',
    );
  }

  CopilotSdkException _malformed(String field) {
    return CopilotSdkException(
      code: CopilotSdkErrorCode.malformedResponse,
      message: 'Copilot quota field "$field" is malformed',
    );
  }
}

final class _QuotaFields {
  const _QuotaFields({
    required this.available,
    required this.entitlementRequests,
    required this.usedRequests,
    required this.remainingPercentage,
    required this.overage,
    required this.overageAllowedWithExhaustedQuota,
    required this.reset,
  });

  const _QuotaFields.unavailable()
    : available = false,
      entitlementRequests = null,
      usedRequests = null,
      remainingPercentage = null,
      overage = null,
      overageAllowedWithExhaustedQuota = null,
      reset = null;

  final bool available;
  final int? entitlementRequests;
  final int? usedRequests;
  final double? remainingPercentage;
  final int? overage;
  final bool? overageAllowedWithExhaustedQuota;
  final QuotaReset? reset;
}
