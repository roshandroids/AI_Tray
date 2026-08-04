import 'package:ai_tray/features/sessions/domain/models/session_summary.dart';
import 'package:meta/meta.dart';

/// All sessions sharing one project, for the Sessions browser's
/// group-by-project view (V3 redesign) — a purely presentational
/// aggregation, since there is no project entity in the domain model.
@immutable
final class ProjectGroup {
  const ProjectGroup({required this.key, required this.sessions});

  /// [SessionSummary.projectPath] (or [SessionSummary.sanitizedProjectDirName]
  /// when undecoded) — the same string already used to group by project
  /// elsewhere, so groups never split what a decoded/undecoded pair would
  /// otherwise treat as the same project.
  final String key;

  /// Sorted most-recent-first (inherited from the input list's own order).
  final List<SessionSummary> sessions;

  bool get hasLiveSession => sessions.any((s) => s.isLive ?? false);

  DateTime get lastActivityAt => sessions.first.lastActivityAt;
}

/// Groups an already most-recent-first [sessions] list by project.
///
/// Group order: any group containing a live session first, then by each
/// group's most recent session — pinning the current session's project to
/// the top rather than leaving it to land wherever recency happens to put
/// it (V3 "current session pinned" goal).
List<ProjectGroup> groupSessionsByProject(List<SessionSummary> sessions) {
  final byKey = <String, List<SessionSummary>>{};
  for (final session in sessions) {
    final key = session.projectPath ?? session.sanitizedProjectDirName;
    (byKey[key] ??= []).add(session);
  }

  final groups =
      [
        for (final entry in byKey.entries)
          ProjectGroup(key: entry.key, sessions: entry.value),
      ]..sort((a, b) {
        if (a.hasLiveSession != b.hasLiveSession) {
          return a.hasLiveSession ? -1 : 1;
        }
        return b.lastActivityAt.compareTo(a.lastActivityAt);
      });
  return groups;
}

/// A friendly project name derived from a decoded project path (its last
/// path segment) — never guessed from the sanitized directory name, which
/// is shown verbatim when decoding failed (design principle 3: never
/// invent data). Shared by `SessionSummary` (Browser) and `ClaudeSession`
/// (Detail), which carry the same two fields under the same names but
/// aren't otherwise related types.
String projectDisplayName({
  required String? projectPath,
  required String sanitizedProjectDirName,
}) {
  if (projectPath == null) return sanitizedProjectDirName;
  final segments = projectPath.split('/').where((s) => s.isNotEmpty).toList();
  return segments.isEmpty ? projectPath : segments.last;
}
