import 'dart:convert';

import 'package:ai_tray/features/providers/core/models/provider_models.dart';
import 'package:ai_tray/features/providers/core/ports/provider_ports.dart';
import 'package:ai_tray/features/usage/domain/models/parser_state.dart';
import 'package:ai_tray/features/usage/domain/models/usage_shape.dart';
import 'package:ai_tray/features/usage/domain/models/validation_status.dart';

/// Parses the app-owned Copilot quota envelope into normalized usage metrics.
final class CopilotUsageParser implements ProviderUsageParser {
  const CopilotUsageParser();

  @override
  ProviderUsageCandidate parse({
    required String rawText,
    Map<String, dynamic>? envelopeJson,
  }) {
    final envelope = envelopeJson ?? _decode(rawText);
    if (envelope == null) return _invalid(rawText, 'copilot_invalid_json');
    if (envelope['schema_version'] != 1 || envelope['provider'] != 'copilot') {
      return _invalid(rawText, 'copilot_envelope_unsupported');
    }

    final quota = _map(envelope['quota']);
    final premium = _map(quota?['premium']);
    final premiumRemaining = _remainingPercent(premium);
    if (premium == null ||
        premium['available'] != true ||
        premiumRemaining == null) {
      return _invalid(rawText, 'copilot_premium_quota_missing');
    }

    final metrics = <ProviderUsageMetric>[
      _metric(
        premium,
        key: 'copilot-premium',
        label: 'Premium requests / AI credits',
        primary: true,
        remainingPercent: premiumRemaining,
      ),
    ];
    _addOptionalMetric(metrics, quota, key: 'chat', label: 'Chat quota');
    _addOptionalMetric(
      metrics,
      quota,
      key: 'completion',
      label: 'Completion quota',
    );

    final primary = metrics.first;
    return ProviderUsageCandidate(
      parserState: ParserState(
        shape: UsageShape.rateLimitsPresent,
        rateLimitsPresent: true,
        matchedSessionLine: true,
        matchedWeekLineCount: metrics.length - 1,
        validation: ValidationStatus.valid,
        rawTextLength: rawText.length,
        messages: const ['copilot_quota_parsed'],
      ),
      rawText: rawText,
      sessionUsedPercent: primary.usedPercent,
      sessionResetsAtRaw: primary.resetsAtRaw,
      metrics: metrics,
    );
  }

  void _addOptionalMetric(
    List<ProviderUsageMetric> metrics,
    Map<String, dynamic>? quota, {
    required String key,
    required String label,
  }) {
    final value = _map(quota?[key]);
    if (value == null || value['available'] != true) return;
    final unlimited = value['unlimited'] == true;
    final remaining = _remainingPercent(value);
    if (!unlimited && remaining == null) return;
    metrics.add(
      _metric(
        value,
        key: 'copilot-$key',
        label: label,
        primary: false,
        remainingPercent: unlimited ? null : remaining,
      ),
    );
  }

  ProviderUsageMetric _metric(
    Map<String, dynamic> value, {
    required String key,
    required String label,
    required bool primary,
    required double? remainingPercent,
  }) {
    final unlimited = value['unlimited'] == true;
    final resetRaw = value['reset_at'] as String?;
    return ProviderUsageMetric(
      key: key,
      label: label,
      usedPercent: unlimited ? 0 : 100 - remainingPercent!,
      primary: primary,
      resetsAt: resetRaw == null ? null : DateTime.tryParse(resetRaw)?.toUtc(),
      resetsAtRaw: resetRaw,
      value: _nonNegative(value['used_requests']),
      total: _nonNegative(value['entitlement_requests']),
      unit: 'requests',
      remainingPercent: remainingPercent,
      unlimited: unlimited,
    );
  }

  Map<String, dynamic>? _decode(String rawText) {
    try {
      return _map(jsonDecode(rawText));
    } on FormatException {
      return null;
    }
  }

  Map<String, dynamic>? _map(Object? value) {
    return value is Map<String, dynamic> ? value : null;
  }

  double? _remainingPercent(Map<String, dynamic>? value) {
    final remaining = value?['remaining_percentage'];
    if (remaining is! num ||
        !remaining.isFinite ||
        remaining < 0 ||
        remaining > 100) {
      return null;
    }
    return remaining.toDouble();
  }

  num? _nonNegative(Object? value) {
    if (value is! num || !value.isFinite || value < 0) return null;
    return value;
  }

  ProviderUsageCandidate _invalid(String rawText, String message) {
    return ProviderUsageCandidate(
      parserState: ParserState.empty().copyWith(
        rawTextLength: rawText.length,
        messages: [message],
      ),
      rawText: rawText,
    );
  }
}
