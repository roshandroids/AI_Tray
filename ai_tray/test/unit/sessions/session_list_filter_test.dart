import 'package:ai_tray/features/sessions/browser/presentation/session_list_filter.dart';
import 'package:ai_tray/features/sessions/domain/models/session_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  SessionSummary summary({
    required String sessionId,
    String? projectPath,
    String sanitizedProjectDirName = '-home-claude-fallback',
  }) {
    return SessionSummary(
      sessionId: sessionId,
      sanitizedProjectDirName: sanitizedProjectDirName,
      projectPath: projectPath,
      lastActivityAt: DateTime.utc(2026, 7, 31),
      messageCount: 1,
    );
  }

  test('empty query returns every session, unfiltered', () {
    final sessions = [
      summary(sessionId: 'a', projectPath: '/home/claude/one'),
      summary(sessionId: 'b', projectPath: '/home/claude/two'),
    ];

    expect(filterSessionsByProjectPath(sessions, ''), sessions);
    expect(filterSessionsByProjectPath(sessions, '   '), sessions);
  });

  test('narrows to sessions whose project path contains the query', () {
    final sessions = [
      summary(sessionId: 'a', projectPath: '/home/claude/ai-tray'),
      summary(sessionId: 'b', projectPath: '/home/claude/other-repo'),
    ];

    final result = filterSessionsByProjectPath(sessions, 'ai-tray');

    expect(result, [sessions[0]]);
  });

  test('matching is case-insensitive', () {
    final sessions = [summary(sessionId: 'a', projectPath: '/home/AI-Tray')];

    expect(filterSessionsByProjectPath(sessions, 'ai-tray'), sessions);
  });

  test('falls back to sanitizedProjectDirName when projectPath is null', () {
    final sessions = [
      summary(
        sessionId: 'a',
        sanitizedProjectDirName: '-home-claude-undecoded',
      ),
    ];

    expect(filterSessionsByProjectPath(sessions, 'undecoded'), sessions);
  });

  test('no match narrows to an empty list, never throws', () {
    final sessions = [summary(sessionId: 'a', projectPath: '/home/claude/x')];

    expect(filterSessionsByProjectPath(sessions, 'nonexistent'), isEmpty);
  });

  test('is pure — does not mutate the input list', () {
    final sessions = [summary(sessionId: 'a', projectPath: '/home/claude/x')];

    filterSessionsByProjectPath(sessions, 'y');

    expect(sessions, hasLength(1));
  });

  test('is deterministic — same inputs produce equal outputs', () {
    final sessions = [
      summary(sessionId: 'a', projectPath: '/home/claude/one'),
      summary(sessionId: 'b', projectPath: '/home/claude/two'),
    ];

    final first = filterSessionsByProjectPath(sessions, 'claude');
    final second = filterSessionsByProjectPath(sessions, 'claude');

    expect(first, second);
  });
}
