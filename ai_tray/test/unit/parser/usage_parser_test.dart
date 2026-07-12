import 'dart:convert';
import 'dart:io';

import 'package:ai_tray/features/usage/data/parsers/usage_parser.dart';
import 'package:ai_tray/features/usage/domain/models/usage_shape.dart';
import 'package:ai_tray/features/usage/domain/models/validation_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final parser = UsageParser();

  test('parses Shape A fixture with rate limits', () {
    final text = File(
      'test/fixtures/claude_usage/shape_a_with_rate_limits.txt',
    ).readAsStringSync();

    final candidate = parser.parse(rawText: text);

    expect(candidate.parserState.shape, UsageShape.rateLimitsPresent);
    expect(candidate.parserState.rateLimitsPresent, isTrue);
    expect(candidate.sessionUsedPercent, 2.0);
    expect(candidate.weekly, isNotEmpty);
    expect(candidate.parserState.validation, ValidationStatus.valid);
  });

  test('parses Shape B fixture as contribution only', () {
    final text = File(
      'test/fixtures/claude_usage/shape_b_contribution_only.txt',
    ).readAsStringSync();

    final candidate = parser.parse(rawText: text);

    expect(candidate.parserState.shape, UsageShape.contributionOnly);
    expect(candidate.sessionUsedPercent, isNull);
    expect(candidate.parserState.validation, ValidationStatus.incomplete);
  });

  test('reads result text from JSON envelope', () {
    final envelope = jsonDecode(
      File('test/fixtures/claude_usage/envelope_success.json').readAsStringSync(),
    ) as Map<String, dynamic>;

    final candidate = parser.parse(rawText: '{}', envelopeJson: envelope);

    expect(candidate.parserState.rateLimitsPresent, isTrue);
    expect(candidate.sessionUsedPercent, 2.0);
  });

  test('detects bare cost summary as unknown', () {
    const text = '''
Total cost:            \$0.0000
Total duration (API):  0s
Usage:                 0 input, 0 output
''';
    final candidate = parser.parse(rawText: text);
    expect(candidate.parserState.shape, UsageShape.unknown);
  });
}
