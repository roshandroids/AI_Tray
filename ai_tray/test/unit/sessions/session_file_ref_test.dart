import 'package:ai_tray/features/sessions/domain/ports/session_file_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SessionFileRef.fromPath', () {
    test('derives sessionId and sanitizedProjectDirName on POSIX paths', () {
      final ref = SessionFileRef.fromPath(
        '/Users/roshan/.claude/projects/-home-claude-testproj/abc-123.jsonl',
      );

      expect(ref.sessionId, 'abc-123');
      expect(ref.sanitizedProjectDirName, '-home-claude-testproj');
      expect(
        ref.path,
        '/Users/roshan/.claude/projects/-home-claude-testproj/abc-123.jsonl',
      );
    });

    test('derives the same fields on Windows-style paths', () {
      final ref = SessionFileRef.fromPath(
        r'C:\Users\roshan\.claude\projects\-home-claude-testproj\abc-123.jsonl',
      );

      expect(ref.sessionId, 'abc-123');
      expect(ref.sanitizedProjectDirName, '-home-claude-testproj');
    });

    test('falls back to the raw filename when there is no .jsonl suffix', () {
      final ref = SessionFileRef.fromPath('/a/b/not-a-transcript.txt');

      expect(ref.sessionId, 'not-a-transcript.txt');
    });

    test('handles a bare filename with no directory gracefully', () {
      final ref = SessionFileRef.fromPath('abc.jsonl');

      expect(ref.sessionId, 'abc');
      expect(ref.sanitizedProjectDirName, '');
    });

    test('equality and hashCode are based on path alone', () {
      final a = SessionFileRef.fromPath('/a/b/c.jsonl');
      final b = SessionFileRef.fromPath('/a/b/c.jsonl');
      final c = SessionFileRef.fromPath('/a/b/d.jsonl');

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('SessionFileStat', () {
    test('equality is value-based', () {
      final modifiedAt = DateTime.utc(2026, 7, 31);
      final a = SessionFileStat(sizeBytes: 10, modifiedAt: modifiedAt);
      final b = SessionFileStat(sizeBytes: 10, modifiedAt: modifiedAt);
      final c = SessionFileStat(sizeBytes: 11, modifiedAt: modifiedAt);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });
}
