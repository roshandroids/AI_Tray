import 'package:ai_tray/features/usage/domain/models/parser_state.dart';
import 'package:ai_tray/features/usage/domain/models/weekly_usage.dart';
import 'package:meta/meta.dart';

/// Provider parser output before usage validation and cache persistence.
///
/// Data Flow:
/// - A provider parser maps raw adapter output into this normalized candidate.
/// - The usage validator converts valid candidates into canonical usage models.
@immutable
final class ProviderUsageCandidate {
  const ProviderUsageCandidate({
    required this.parserState,
    required this.rawText,
    this.sessionUsedPercent,
    this.sessionResetsAtRaw,
    this.weekly = const [],
  });

  final ParserState parserState;
  final String rawText;
  final double? sessionUsedPercent;
  final String? sessionResetsAtRaw;
  final List<WeeklyUsage> weekly;
}
