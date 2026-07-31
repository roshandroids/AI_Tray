import 'package:meta/meta.dart';

/// Aggregated `message.usage` token counters across a transcript, mapped
/// directly from the fields confirmed in
/// `docs/claude_code_cli_capability_report.md` §3B.
@immutable
final class SessionTokenTotals {
  const SessionTokenTotals({
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.cacheCreationInputTokens = 0,
    this.cacheReadInputTokens = 0,
  });

  final int inputTokens;
  final int outputTokens;
  final int cacheCreationInputTokens;
  final int cacheReadInputTokens;

  @override
  bool operator ==(Object other) {
    return other is SessionTokenTotals &&
        other.inputTokens == inputTokens &&
        other.outputTokens == outputTokens &&
        other.cacheCreationInputTokens == cacheCreationInputTokens &&
        other.cacheReadInputTokens == cacheReadInputTokens;
  }

  @override
  int get hashCode => Object.hash(
    inputTokens,
    outputTokens,
    cacheCreationInputTokens,
    cacheReadInputTokens,
  );

  @override
  String toString() =>
      'SessionTokenTotals(input: $inputTokens, output: $outputTokens, '
      'cacheCreate: $cacheCreationInputTokens, '
      'cacheRead: $cacheReadInputTokens)';
}
