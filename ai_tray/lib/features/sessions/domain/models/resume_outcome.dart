import 'package:ai_tray/features/sessions/domain/models/session_token_totals.dart';
import 'package:meta/meta.dart';

/// Outcome of one `claude --resume ... --output-format json` invocation,
/// mapped directly from the CLI's own JSON result envelope (confirmed live
/// in `docs/reports/claude_code_cli_capability_report.md` §3D).
///
/// Named at the `sessions/` root (not inside `resume/` or `queue/`)
/// because it is produced by two real callers today — the attended
/// "Resume now" action (Feature 2.2.1) and, later, the unattended queue
/// executor (Feature 2.2.2) — and both need the identical shape (§8).
@immutable
final class ResumeOutcome {
  const ResumeOutcome({
    required this.sessionId,
    required this.isError,
    required this.costUsd,
    required this.tokens,
    required this.numTurns,
    required this.resultText,
    this.stopReason,
  });

  /// Echoes the CLI's own `session_id` — confirmed unchanged across a
  /// resume (capability report §2: "a true resume, not a new session"),
  /// except when `forkSession` was requested, in which case the CLI
  /// assigns a new id and this field reflects that new one.
  final String sessionId;

  /// From the envelope's `is_error`. A resume can complete (a result
  /// envelope is still produced) while reporting an error, e.g. "Not
  /// logged in" — distinct from a process-level failure (non-zero exit,
  /// timeout), which never reaches this model at all.
  final bool isError;

  /// From `total_cost_usd`.
  final double costUsd;

  /// From `usage` — reuses the same aggregated-token shape
  /// `ClaudeSession.tokenTotals` already uses, since it's the identical
  /// set of counters (`input_tokens`, `output_tokens`,
  /// `cache_creation_input_tokens`, `cache_read_input_tokens`).
  final SessionTokenTotals tokens;

  /// From `num_turns`.
  final int numTurns;

  /// From `stop_reason` — `null` if the envelope didn't carry one (schema
  /// drift across CLI versions is explicitly unconfirmed per the
  /// capability report; never guessed).
  final String? stopReason;

  /// From `result` — the CLI's own final status/output string.
  final String resultText;

  @override
  bool operator ==(Object other) {
    return other is ResumeOutcome &&
        other.sessionId == sessionId &&
        other.isError == isError &&
        other.costUsd == costUsd &&
        other.tokens == tokens &&
        other.numTurns == numTurns &&
        other.stopReason == stopReason &&
        other.resultText == resultText;
  }

  @override
  int get hashCode => Object.hash(
    sessionId,
    isError,
    costUsd,
    tokens,
    numTurns,
    stopReason,
    resultText,
  );

  @override
  String toString() =>
      'ResumeOutcome(sessionId: $sessionId, isError: $isError, '
      'costUsd: $costUsd, numTurns: $numTurns)';
}
