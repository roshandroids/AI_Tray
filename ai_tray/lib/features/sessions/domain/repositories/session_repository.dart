import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/sessions/domain/models/claude_session.dart';
import 'package:ai_tray/features/sessions/domain/models/session_summary.dart';

/// Read projection over Claude session transcripts (§9 of
/// `docs/planning/v2-vision-and-roadmap.md`). Owns no cache of its own —
/// JSONL files remain the sole source of truth (design principle 3); every
/// call re-derives the list from disk plus a best-effort liveness
/// enrichment. Shared by `browser/` and `detail/`.
abstract interface class SessionRepository {
  /// The full session list for the Session Browser.
  ///
  /// Sourced entirely from JSONL files under `~/.claude/projects/`, with
  /// `SessionSummary.isLive` merged in from `ClaudeSessionService` when
  /// that enrichment call succeeds. A failure here means the JSONL index
  /// pass itself failed (e.g. a permission error) — never a liveness
  /// enrichment failure, which degrades silently instead of failing this
  /// call (design principle 3).
  Future<Result<List<SessionSummary>>> listSessions();

  /// The full detail for one session, by [sessionId], for the Session
  /// Detail view (Feature 1.2.2).
  ///
  /// Returns `FailureCode.sessionNotFound` if the transcript has been
  /// deleted or moved since it was last listed — a real race between
  /// listing and reading a session, not a hypothetical one (§21, Feature
  /// 1.2.2).
  Future<Result<ClaudeSession>> readSession(String sessionId);
}
