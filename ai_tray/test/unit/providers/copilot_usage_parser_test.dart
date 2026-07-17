import 'dart:convert';

import 'package:ai_tray/features/providers/copilot/mapper/copilot_usage_parser.dart';
import 'package:ai_tray/features/usage/domain/models/validation_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = CopilotUsageParser();

  test('maps finite and unlimited quota categories defensively', () {
    final candidate = parser.parse(
      rawText: jsonEncode({
        'schema_version': 1,
        'provider': 'copilot',
        'quota': {
          'premium': {
            'available': true,
            'remaining_percentage': 88.5,
            'unlimited': false,
            'entitlement_requests': 300,
            'used_requests': 34,
            'reset_at': '2026-08-01T00:00:00Z',
          },
          'chat': {
            'available': true,
            'remaining_percentage': 100,
            'unlimited': true,
          },
        },
      }),
    );

    expect(candidate.parserState.validation, ValidationStatus.valid);
    expect(candidate.sessionUsedPercent, 11.5);
    expect(candidate.metrics, hasLength(2));
    expect(candidate.metrics.first.primary, isTrue);
    expect(candidate.metrics.first.remaining, 266);
    expect(candidate.metrics.last.unlimited, isTrue);
  });

  test('omits unavailable optional categories', () {
    final candidate = parser.parse(
      rawText: '',
      envelopeJson: {
        'schema_version': 1,
        'provider': 'copilot',
        'quota': {
          'premium': {
            'available': true,
            'remaining_percentage': 90,
            'unlimited': false,
          },
          'chat': {'available': false},
        },
      },
    );

    expect(candidate.metrics, hasLength(1));
    expect(candidate.sessionUsedPercent, 10);
  });

  test('rejects malformed percentages and unsupported envelopes', () {
    for (final envelope in <Map<String, dynamic>>[
      {
        'schema_version': 2,
        'provider': 'copilot',
        'quota': <String, dynamic>{},
      },
      {
        'schema_version': 1,
        'provider': 'copilot',
        'quota': {
          'premium': {
            'available': true,
            'remaining_percentage': 120,
          },
        },
      },
    ]) {
      final candidate = parser.parse(rawText: '', envelopeJson: envelope);
      expect(candidate.parserState.validation, ValidationStatus.invalid);
      expect(candidate.metrics, isEmpty);
    }
  });

  test('rejects null and malformed JSON without throwing', () {
    final candidate = parser.parse(rawText: 'not-json');

    expect(candidate.parserState.validation, ValidationStatus.invalid);
    expect(candidate.parserState.messages, contains('copilot_invalid_json'));
  });
}
