import 'package:ai_tray/features/sessions/domain/models/session_summary.dart';

/// Client-side filter over an already-loaded session list, by project path
/// (Feature 1.2.1, "Search/filter by project path" story).
///
/// Deterministic and side-effect free: never mutates [sessions], matches
/// against [SessionSummary.projectPath] (falling back to
/// [SessionSummary.sanitizedProjectDirName] when undecoded), and an empty
/// or blank [query] returns every session — the loaded list itself is
/// never discarded or overwritten by filtering.
List<SessionSummary> filterSessionsByProjectPath(
  List<SessionSummary> sessions,
  String query,
) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return sessions;
  return [
    for (final session in sessions)
      if ((session.projectPath ?? session.sanitizedProjectDirName)
          .toLowerCase()
          .contains(needle))
        session,
  ];
}
