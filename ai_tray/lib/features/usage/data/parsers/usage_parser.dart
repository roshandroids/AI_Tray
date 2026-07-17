import 'package:ai_tray/features/providers/domain/models/provider_usage_candidate.dart';
import 'package:ai_tray/features/providers/domain/ports/provider_usage_parser.dart';
import 'package:ai_tray/features/usage/domain/models/parser_state.dart';
import 'package:ai_tray/features/usage/domain/models/usage_shape.dart';
import 'package:ai_tray/features/usage/domain/models/validation_status.dart';
import 'package:ai_tray/features/usage/domain/models/weekly_usage.dart';

/// Parses Claude `/usage` free-text (and JSON envelope `result`).
final class UsageParser implements ProviderUsageParser {
  const UsageParser();

  static final _sessionRe = RegExp(
    r'Current session:\s*(\d+(?:\.\d+)?)%\s*used\s*[·\.]\s*resets\s+(.+)',
    caseSensitive: false,
  );
  static final _weekRe = RegExp(
    r'Current week\s*\(([^)]+)\):\s*(\d+(?:\.\d+)?)%\s*used'
    r'(?:\s*[·\.]\s*resets\s+(.+))?',
    caseSensitive: false,
  );

  @override
  ProviderUsageCandidate parse({
    required String rawText,
    Map<String, dynamic>? envelopeJson,
  }) {
    final text = _extractText(rawText: rawText, envelopeJson: envelopeJson);
    final session = _sessionRe.firstMatch(text);
    final weeks = <WeeklyUsage>[];
    for (final match in _weekRe.allMatches(text)) {
      final resetsRaw = match.group(3)?.trim();
      weeks.add(
        WeeklyUsage(
          label: match.group(1)!.trim(),
          usedPercent: double.parse(match.group(2)!),
          resetsAtRaw: (resetsRaw == null || resetsRaw.isEmpty)
              ? null
              : resetsRaw,
        ),
      );
    }

    final rateLimitsPresent = session != null || weeks.isNotEmpty;
    final UsageShape shape;
    if (rateLimitsPresent) {
      shape = UsageShape.rateLimitsPresent;
    } else if (text.contains('subscription to power your Claude Code usage') ||
        text.contains("What's contributing to your limits usage")) {
      shape = UsageShape.contributionOnly;
    } else if (text.trim().isEmpty) {
      shape = UsageShape.unknown;
    } else if (text.contains('Total cost:') && text.contains('Usage:')) {
      // `--bare` / cost summary — wrong payload.
      shape = UsageShape.unknown;
    } else {
      shape = UsageShape.unknown;
    }

    final validation = switch (shape) {
      UsageShape.rateLimitsPresent => ValidationStatus.valid,
      UsageShape.contributionOnly => ValidationStatus.incomplete,
      UsageShape.unknown => ValidationStatus.invalid,
    };

    return ProviderUsageCandidate(
      rawText: text,
      sessionUsedPercent: session == null
          ? null
          : double.parse(session.group(1)!),
      sessionResetsAtRaw: session?.group(2)?.trim(),
      weekly: weeks,
      parserState: ParserState(
        shape: shape,
        rateLimitsPresent: rateLimitsPresent,
        matchedSessionLine: session != null,
        matchedWeekLineCount: weeks.length,
        validation: validation,
        rawTextLength: text.length,
        messages: [
          if (shape == UsageShape.contributionOnly) 'shape_b_contribution_only',
          if (shape == UsageShape.unknown) 'unrecognized_usage_payload',
        ],
      ),
    );
  }

  String _extractText({
    required String rawText,
    Map<String, dynamic>? envelopeJson,
  }) {
    final result = envelopeJson?['result'];
    if (result is String && result.isNotEmpty) {
      return result;
    }
    return rawText;
  }
}
