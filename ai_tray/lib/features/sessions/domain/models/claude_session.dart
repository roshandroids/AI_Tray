import 'package:ai_tray/features/sessions/domain/models/session_token_totals.dart';
import 'package:meta/meta.dart';

/// Full detail for one Claude session, built by
/// `JsonlSessionParser.parseSession()`'s lazy detail pass (§10) — only
/// computed when a session is opened, since it reads the whole transcript.
@immutable
final class ClaudeSession {
  const ClaudeSession({
    required this.sessionId,
    required this.sanitizedProjectDirName,
    required this.messageCount,
    required this.tokenTotals,
    required this.isComplete,
    this.projectPath,
    this.lastActivityAt,
    this.isLive,
    this.model,
    this.gitBranch,
    this.title,
  });

  final String sessionId;
  final String sanitizedProjectDirName;

  /// Read directly from the transcript's own `cwd` field (confirmed
  /// present on every record, capability report §3B) — unlike
  /// `SessionSummary.projectPath`, this does not need
  /// `ClaudeProjectPathDecoder`'s best-effort reversal, since the detail
  /// pass reads real content instead of only the sanitized directory name.
  final String? projectPath;

  /// From the last line carrying a parseable `timestamp` — `null` only for
  /// a transcript with zero parseable lines (e.g. truly empty).
  final DateTime? lastActivityAt;

  /// Accurate count of `user`/`assistant` typed records — unlike
  /// `SessionSummary.messageCount`, this is a real count, not an estimate.
  final int messageCount;

  final bool? isLive;

  /// From the last assistant `message.model` seen.
  final String? model;

  /// From the last non-null `gitBranch` seen on any record.
  final String? gitBranch;

  /// Always `null` in this version — the on-disk field name for a
  /// user-assigned session title (`-n`/`--name`) is confirmed as a CLI
  /// flag but **not** confirmed as a persisted JSONL field name
  /// (capability report §3B). Never guessed (design principle 3).
  final String? title;

  final SessionTokenTotals tokenTotals;

  /// `false` when the transcript's last content line failed to parse as
  /// JSON — an ordinary state for a killed process (design principle 4),
  /// not corruption. A malformed line elsewhere in the file does not, by
  /// itself, make a session incomplete; only the final line does.
  final bool isComplete;

  ClaudeSession copyWith({
    String? sessionId,
    String? sanitizedProjectDirName,
    String? projectPath,
    DateTime? lastActivityAt,
    int? messageCount,
    bool? isLive,
    String? model,
    String? gitBranch,
    String? title,
    SessionTokenTotals? tokenTotals,
    bool? isComplete,
  }) {
    return ClaudeSession(
      sessionId: sessionId ?? this.sessionId,
      sanitizedProjectDirName:
          sanitizedProjectDirName ?? this.sanitizedProjectDirName,
      projectPath: projectPath ?? this.projectPath,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      messageCount: messageCount ?? this.messageCount,
      isLive: isLive ?? this.isLive,
      model: model ?? this.model,
      gitBranch: gitBranch ?? this.gitBranch,
      title: title ?? this.title,
      tokenTotals: tokenTotals ?? this.tokenTotals,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ClaudeSession &&
        other.sessionId == sessionId &&
        other.sanitizedProjectDirName == sanitizedProjectDirName &&
        other.projectPath == projectPath &&
        other.lastActivityAt == lastActivityAt &&
        other.messageCount == messageCount &&
        other.isLive == isLive &&
        other.model == model &&
        other.gitBranch == gitBranch &&
        other.title == title &&
        other.tokenTotals == tokenTotals &&
        other.isComplete == isComplete;
  }

  @override
  int get hashCode => Object.hash(
    sessionId,
    sanitizedProjectDirName,
    projectPath,
    lastActivityAt,
    messageCount,
    isLive,
    model,
    gitBranch,
    Object.hash(title, tokenTotals, isComplete),
  );

  @override
  String toString() =>
      'ClaudeSession(sessionId: $sessionId, messageCount: $messageCount, '
      'isComplete: $isComplete)';
}
