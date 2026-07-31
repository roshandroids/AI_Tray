import 'package:ai_tray/features/sessions/data/parsers/jsonl_session_parser.dart';
import 'package:ai_tray/features/sessions/domain/ports/session_file_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = JsonlSessionParser();
  final ref = SessionFileRef.fromPath(
    '/root/-home-claude-testproj/abc123.jsonl',
  );

  group('summarize (index pass)', () {
    test('never reads content — derives fields from ref + stat only', () {
      final stat = SessionFileStat(
        sizeBytes: 4000,
        modifiedAt: DateTime.utc(2026, 7, 31, 10),
      );

      final summary = parser.summarize(
        file: ref,
        stat: stat,
        directoryExists: (path) => path == '/home/claude/testproj',
      );

      expect(summary.sessionId, 'abc123');
      expect(summary.sanitizedProjectDirName, '-home-claude-testproj');
      expect(summary.projectPath, '/home/claude/testproj');
      expect(summary.lastActivityAt, stat.modifiedAt);
      expect(summary.isLive, isNull);
    });

    test('falls back to null projectPath when decoding is ambiguous', () {
      final stat = SessionFileStat(
        sizeBytes: 100,
        modifiedAt: DateTime.utc(2026, 7, 31),
      );

      final summary = parser.summarize(
        file: ref,
        stat: stat,
        directoryExists: (_) => false,
      );

      expect(summary.projectPath, isNull);
      expect(summary.sanitizedProjectDirName, '-home-claude-testproj');
    });

    test('messageCount is a size-based estimate, at least 1 for a non-empty '
        'file', () {
      final stat = SessionFileStat(
        sizeBytes: 1,
        modifiedAt: DateTime.utc(2026, 7, 31),
      );

      final summary = parser.summarize(
        file: ref,
        stat: stat,
        directoryExists: (_) => false,
      );

      expect(summary.messageCount, greaterThanOrEqualTo(1));
    });

    test('messageCount is 0 for a zero-byte file', () {
      final stat = SessionFileStat(
        sizeBytes: 0,
        modifiedAt: DateTime.utc(2026, 7, 31),
      );

      final summary = parser.summarize(
        file: ref,
        stat: stat,
        directoryExists: (_) => false,
      );

      expect(summary.messageCount, 0);
    });
  });

  group('parseSession (detail pass)', () {
    Stream<String> linesOf(List<String> lines) => Stream.fromIterable(lines);

    test(
      'aggregates message count, model, gitBranch, cwd, and tokens',
      () async {
        const userLine =
            '{"type":"user","cwd":"/home/claude/testproj",'
            '"gitBranch":"main","timestamp":"2026-07-31T10:00:00.000Z",'
            '"message":{"role":"user"}}';
        const assistantLine =
            '{"type":"assistant","cwd":"/home/claude/testproj",'
            '"gitBranch":"main","timestamp":"2026-07-31T10:00:05.000Z",'
            '"message":{"role":"assistant","model":"claude-opus-5",'
            '"usage":{"input_tokens":10,"output_tokens":5,'
            '"cache_creation_input_tokens":1,"cache_read_input_tokens":2}}}';

        final session = await parser.parseSession(
          file: ref,
          lines: linesOf([userLine, assistantLine]),
        );

        expect(session.messageCount, 2);
        expect(session.model, 'claude-opus-5');
        expect(session.gitBranch, 'main');
        expect(session.projectPath, '/home/claude/testproj');
        expect(session.tokenTotals.inputTokens, 10);
        expect(session.tokenTotals.outputTokens, 5);
        expect(session.tokenTotals.cacheCreationInputTokens, 1);
        expect(session.tokenTotals.cacheReadInputTokens, 2);
        expect(session.isComplete, isTrue);
        expect(
          session.title,
          isNull,
          reason: 'on-disk field name unconfirmed',
        );
      },
    );

    test(
      'ignores non-user/assistant record types for message count',
      () async {
        final session = await parser.parseSession(
          file: ref,
          lines: linesOf([
            '{"type":"system","timestamp":"2026-07-31T10:00:00.000Z"}',
            '{"type":"user","message":{"role":"user"}}',
          ]),
        );

        expect(session.messageCount, 1);
      },
    );

    test(
      'a malformed line in the middle is skipped, but isComplete stays '
      'true when the last line parses fine',
      () async {
        final session = await parser.parseSession(
          file: ref,
          lines: linesOf([
            '{"type":"user","message":{"role":"user"}}',
            'not json at all {{{',
            '{"type":"assistant","message":{"role":"assistant"}}',
          ]),
        );

        expect(session.messageCount, 2);
        expect(session.isComplete, isTrue);
      },
    );

    test(
      'a truncated final line marks isComplete false (killed-process state, '
      'not corruption)',
      () async {
        final session = await parser.parseSession(
          file: ref,
          lines: linesOf([
            '{"type":"user","message":{"role":"user"}}',
            '{"type":"assistant","message":{"role":"assistant","content":"cut',
          ]),
        );

        expect(session.messageCount, 1);
        expect(session.isComplete, isFalse);
      },
    );

    test('an empty stream produces a zero-message, complete session', () async {
      final session = await parser.parseSession(file: ref, lines: linesOf([]));

      expect(session.messageCount, 0);
      expect(session.isComplete, isTrue);
      expect(session.lastActivityAt, isNull);
    });

    test('blank lines between records do not affect isComplete', () async {
      final session = await parser.parseSession(
        file: ref,
        lines: linesOf([
          '{"type":"user","message":{"role":"user"}}',
          '',
          '   ',
        ]),
      );

      expect(session.isComplete, isTrue);
    });

    test('a stream error is tolerated, not rethrown', () async {
      // Exception, not Error — matches what a real dart:io read failure
      // (e.g. FileSystemException) is; a genuine Error (programming bug)
      // is deliberately left to propagate rather than be swallowed.
      Stream<String> erroringLines() async* {
        yield '{"type":"user","message":{"role":"user"}}';
        throw Exception('simulated read failure');
      }

      final session = await parser.parseSession(
        file: ref,
        lines: erroringLines(),
      );

      expect(session.messageCount, 1);
      expect(session.isComplete, isFalse);
    });
  });
}
