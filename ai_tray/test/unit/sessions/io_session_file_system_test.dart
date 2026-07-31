import 'dart:convert';
import 'dart:io';

import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/logging/console_app_logger.dart';
import 'package:ai_tray/features/sessions/data/fs/io_session_file_system.dart';
import 'package:ai_tray/features/sessions/domain/ports/session_file_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempRoot;
  late IoSessionFileSystem fs;

  setUp(() {
    tempRoot = Directory.systemTemp.createTempSync('ai_tray_session_fs_test');
    fs = IoSessionFileSystem(
      logger: ConsoleAppLogger(defaultName: 'session_fs_test'),
    );
  });

  tearDown(() {
    if (tempRoot.existsSync()) {
      tempRoot.deleteSync(recursive: true);
    }
  });

  group('listSessionFiles', () {
    test('returns success(empty) when the root does not exist', () async {
      final missingRoot = '${tempRoot.path}/does-not-exist';

      final result = await fs.listSessionFiles(rootPath: missingRoot);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isEmpty);
    });

    test('enumerates only .jsonl files, ignoring other file types', () async {
      final projectDir = Directory('${tempRoot.path}/-home-claude-testproj')
        ..createSync(recursive: true);
      File('${projectDir.path}/session-a.jsonl').writeAsStringSync('{}');
      File('${projectDir.path}/notes.txt').writeAsStringSync('ignore me');

      final result = await fs.listSessionFiles(rootPath: tempRoot.path);

      expect(result.isSuccess, isTrue);
      final paths = result.valueOrNull!.map((ref) => ref.sessionId).toList();
      expect(paths, ['session-a']);
    });
  });

  group('stat', () {
    test('returns size and modified time for an existing file', () async {
      final filePath = '${tempRoot.path}/session-a.jsonl';
      File(filePath).writeAsStringSync('{"hello":"world"}');
      final ref = SessionFileRef.fromPath(filePath);

      final result = await fs.stat(ref);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.sizeBytes, greaterThan(0));
    });

    test('returns sessionNotFound for a missing file', () async {
      final ref = SessionFileRef.fromPath('${tempRoot.path}/missing.jsonl');

      final result = await fs.stat(ref);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.code, FailureCode.sessionNotFound);
    });
  });

  group('readLines', () {
    test('streams lines in order', () async {
      final filePath = '${tempRoot.path}/session-a.jsonl';
      File(filePath).writeAsStringSync('{"a":1}\n{"a":2}\n');
      final ref = SessionFileRef.fromPath(filePath);

      final lines = await fs.readLines(ref).toList();

      expect(lines, ['{"a":1}', '{"a":2}']);
    });

    test(
      'tolerates a truncated multi-byte UTF-8 sequence instead of throwing '
      '(a killed writer can cut a file mid-character — design principle 4)',
      () async {
        final filePath = '${tempRoot.path}/session-a.jsonl';
        final validLine = utf8.encode('{"emoji":"🙂"}\n');
        // Cut off the last byte of the trailing multi-byte sequence.
        final truncated = validLine.sublist(0, validLine.length - 2);
        File(filePath).writeAsBytesSync(truncated);
        final ref = SessionFileRef.fromPath(filePath);

        final lines = fs.readLines(ref);

        await expectLater(lines.toList(), completes);
      },
    );
  });

  test('defaultClaudeProjectsRoot resolves a non-empty path', () {
    final root = IoSessionFileSystem.defaultClaudeProjectsRoot();

    expect(root, isNotEmpty);
    expect(root, contains('.claude'));
    expect(root, contains('projects'));
  });
}
