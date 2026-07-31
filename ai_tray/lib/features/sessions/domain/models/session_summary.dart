import 'package:meta/meta.dart';

/// List-view projection of one Claude session, built by
/// `JsonlSessionParser.summarize()`'s index pass (§10) — file metadata
/// only, no transcript content is read to produce this.
@immutable
final class SessionSummary {
  const SessionSummary({
    required this.sessionId,
    required this.sanitizedProjectDirName,
    required this.lastActivityAt,
    required this.messageCount,
    this.projectPath,
    this.isLive,
  });

  /// Derived from the transcript's filename (`SessionFileRef.sessionId`).
  final String sessionId;

  /// Raw, still-encoded project directory name — always available, even
  /// when [projectPath] could not be confidently decoded (design
  /// principle 3: never invent data).
  final String sanitizedProjectDirName;

  /// Best-effort decoded project path (`ClaudeProjectPathDecoder`), or
  /// `null` if the reversal was ambiguous. Fall back to
  /// [sanitizedProjectDirName] for display when this is `null`.
  final String? projectPath;

  /// File modification time — the cheapest available signal for "last
  /// activity" per §10; never requires reading transcript content.
  final DateTime lastActivityAt;

  /// **Estimate**, derived from file size, not a real count — the index
  /// pass never reads transcript content. `ClaudeSession.messageCount`
  /// (produced by the full-transcript pass) is the accurate count.
  final int messageCount;

  /// `null` until `agents --json --all` enrichment merges a value in
  /// (Feature 1.1.3) — absence is never treated as "not live" (design
  /// principle 3).
  final bool? isLive;

  SessionSummary copyWith({
    String? sessionId,
    String? sanitizedProjectDirName,
    String? projectPath,
    DateTime? lastActivityAt,
    int? messageCount,
    bool? isLive,
  }) {
    return SessionSummary(
      sessionId: sessionId ?? this.sessionId,
      sanitizedProjectDirName:
          sanitizedProjectDirName ?? this.sanitizedProjectDirName,
      projectPath: projectPath ?? this.projectPath,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      messageCount: messageCount ?? this.messageCount,
      isLive: isLive ?? this.isLive,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SessionSummary &&
        other.sessionId == sessionId &&
        other.sanitizedProjectDirName == sanitizedProjectDirName &&
        other.projectPath == projectPath &&
        other.lastActivityAt == lastActivityAt &&
        other.messageCount == messageCount &&
        other.isLive == isLive;
  }

  @override
  int get hashCode => Object.hash(
    sessionId,
    sanitizedProjectDirName,
    projectPath,
    lastActivityAt,
    messageCount,
    isLive,
  );

  @override
  String toString() =>
      'SessionSummary(sessionId: $sessionId, projectPath: '
      '${projectPath ?? sanitizedProjectDirName})';
}
