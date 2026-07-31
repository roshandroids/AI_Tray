import 'dart:io';

import 'package:ai_tray/features/sessions/data/parsers/jsonl_session_parser.dart';
import 'package:ai_tray/features/sessions/domain/ports/session_file_system.dart';
import 'package:flutter_test/flutter_test.dart';

/// Locks in parser tolerance behavior as regression tests (§21 Feature
/// 1.1.2, "Fixture-based resilience test suite"), against the four fixture
/// types this story's acceptance criteria require: a valid multi-message
/// transcript, an empty file, a file with one malformed line mid-stream,
/// and a file that ends abruptly mid-turn.
void main() {
  const parser = JsonlSessionParser();

  Stream<String> fixtureLines(String name) {
    final content = File(
      'test/fixtures/claude_sessions/$name',
    ).readAsStringSync();
    return Stream.fromIterable(
      content.split('\n').where((line) => line.trim().isNotEmpty),
    );
  }

  SessionFileRef refFor(String name) =>
      SessionFileRef.fromPath('/root/-home-claude-testproj/$name');

  test(
    'valid_multi_message.jsonl parses completely, no lines dropped',
    () async {
      final session = await parser.parseSession(
        file: refFor('valid_multi_message'),
        lines: fixtureLines('valid_multi_message.jsonl'),
      );

      expect(session.isComplete, isTrue);
      expect(session.messageCount, 4);
      expect(session.model, 'claude-opus-5');
      expect(session.gitBranch, 'feature/fix-bug');
      expect(session.projectPath, '/home/claude/testproj');
      expect(session.tokenTotals.inputTokens, 200);
      expect(session.tokenTotals.outputTokens, 55);
      expect(session.tokenTotals.cacheReadInputTokens, 200);
    },
  );

  test('empty.jsonl parses to a complete, zero-message session', () async {
    final session = await parser.parseSession(
      file: refFor('empty'),
      lines: fixtureLines('empty.jsonl'),
    );

    expect(session.isComplete, isTrue);
    expect(session.messageCount, 0);
    expect(session.lastActivityAt, isNull);
    expect(session.model, isNull);
  });

  test(
    'malformed_middle_line.jsonl skips the bad line but stays complete '
    '(the corruption is not at the end)',
    () async {
      final session = await parser.parseSession(
        file: refFor('malformed_middle_line'),
        lines: fixtureLines('malformed_middle_line.jsonl'),
      );

      expect(session.isComplete, isTrue);
      // 3 valid lines counted; the malformed line contributes nothing.
      expect(session.messageCount, 3);
      expect(session.model, 'claude-sonnet-5');
    },
  );

  test(
    'truncated_mid_turn.jsonl is marked incomplete, not treated as an error',
    () async {
      final session = await parser.parseSession(
        file: refFor('truncated_mid_turn'),
        lines: fixtureLines('truncated_mid_turn.jsonl'),
      );

      expect(session.isComplete, isFalse);
      // The truncated final line does not count; the two valid ones do.
      expect(session.messageCount, 2);
      expect(session.projectPath, '/home/claude/killedproj');
    },
  );

  test('summarize() runs on all four fixtures without reading content', () {
    for (final name in [
      'valid_multi_message.jsonl',
      'empty.jsonl',
      'malformed_middle_line.jsonl',
      'truncated_mid_turn.jsonl',
    ]) {
      final file = File('test/fixtures/claude_sessions/$name');
      final stat = SessionFileStat(
        sizeBytes: file.lengthSync(),
        modifiedAt: file.lastModifiedSync().toUtc(),
      );

      final summary = parser.summarize(
        file: refFor(name),
        stat: stat,
        directoryExists: (_) => false,
      );

      expect(summary.sessionId, name.replaceAll('.jsonl', ''));
      expect(summary.lastActivityAt, stat.modifiedAt);
    }
  });
}
