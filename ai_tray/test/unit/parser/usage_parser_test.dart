import 'dart:convert';
import 'dart:io';

import 'package:ai_tray/features/usage/data/parsers/usage_parser.dart';
import 'package:ai_tray/features/usage/data/validators/usage_validator.dart';
import 'package:ai_tray/features/usage/domain/models/usage_shape.dart';
import 'package:ai_tray/features/usage/domain/models/validation_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final parser = UsageParser();
  final validator = UsageValidator();

  String fixture(String name) =>
      File('test/fixtures/claude_usage/$name').readAsStringSync();

  test('parses Shape A fixture with rate limits', () {
    final candidate = parser.parse(
      rawText: fixture('shape_a_with_rate_limits.txt'),
    );

    expect(candidate.parserState.shape, UsageShape.rateLimitsPresent);
    expect(candidate.parserState.rateLimitsPresent, isTrue);
    expect(candidate.sessionUsedPercent, 2.0);
    expect(candidate.weekly, isNotEmpty);
    expect(candidate.parserState.validation, ValidationStatus.valid);
  });

  test('parses Shape A decimal percent', () {
    final candidate = parser.parse(
      rawText: fixture('shape_a_decimal_percent.txt'),
    );
    expect(candidate.sessionUsedPercent, 47.5);
    expect(candidate.weekly.length, 2);
    final validated = validator.validate(
      candidate,
      fetchedAt: DateTime.utc(2026, 7, 12),
    );
    expect(validated.isSuccess, isTrue);
    expect(validated.valueOrNull?.sessionUsedPercent, 47.5);
  });

  test('parses Shape A with ASCII dot separator', () {
    final candidate = parser.parse(
      rawText: fixture('shape_a_dot_separator.txt'),
    );
    expect(candidate.parserState.shape, UsageShape.rateLimitsPresent);
    expect(candidate.sessionUsedPercent, 3.0);
    expect(candidate.weekly.single.usedPercent, 1.0);
    expect(candidate.weekly.single.resetsAtRaw, isNull);
  });

  test('parses Shape B fixture as contribution only', () {
    final candidate = parser.parse(
      rawText: fixture('shape_b_contribution_only.txt'),
    );

    expect(candidate.parserState.shape, UsageShape.contributionOnly);
    expect(candidate.sessionUsedPercent, isNull);
    expect(candidate.parserState.validation, ValidationStatus.incomplete);
  });

  test('parses minimal Shape B', () {
    final candidate = parser.parse(rawText: fixture('shape_b_minimal.txt'));
    expect(candidate.parserState.shape, UsageShape.contributionOnly);
    final validated = validator.validate(
      candidate,
      fetchedAt: DateTime.utc(2026, 7, 12),
    );
    expect(validated.isFailure, isTrue);
  });

  test('reads result text from JSON envelope', () {
    final envelope =
        jsonDecode(
              fixture('envelope_success.json'),
            )
            as Map<String, dynamic>;

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

  test('empty output is unknown/invalid', () {
    final candidate = parser.parse(rawText: fixture('empty.txt'));
    expect(candidate.parserState.shape, UsageShape.unknown);
    expect(candidate.parserState.validation, ValidationStatus.invalid);
  });

  test('auth prompt text is unknown (no invented %)', () {
    final candidate = parser.parse(rawText: fixture('auth_prompt_text.txt'));
    expect(candidate.parserState.shape, UsageShape.unknown);
    expect(candidate.sessionUsedPercent, isNull);
  });

  test('unrelated blurb is unknown', () {
    final candidate = parser.parse(rawText: fixture('unknown_blurb.txt'));
    expect(candidate.parserState.shape, UsageShape.unknown);
  });
}
