import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/sessions/domain/models/session_summary.dart';

/// Merges `ClaudeSessionService.listLiveSessions` enrichment onto a
/// JSONL-derived summary list (Feature 1.1.3, second story).
///
/// Deterministic and side-effect free: never mutates [summaries], and a
/// failed/degraded [liveness] result returns [summaries] unchanged rather
/// than guessing — every [SessionSummary.isLive] stays exactly as it came
/// in (`null` unless a caller already set it), per design principle 3.
List<SessionSummary> mergeSessionLiveness(
  List<SessionSummary> summaries,
  Result<Set<String>> liveness,
) {
  return liveness.when(
    success: (liveIds) => [
      for (final summary in summaries)
        summary.copyWith(isLive: liveIds.contains(summary.sessionId)),
    ],
    onFailure: (_) => summaries,
  );
}
