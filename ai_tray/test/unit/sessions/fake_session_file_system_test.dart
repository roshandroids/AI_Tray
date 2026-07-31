import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/features/sessions/data/fs/fake_session_file_system.dart';
import 'package:ai_tray/features/sessions/domain/ports/session_file_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FakeSessionFileSystem', () {
    test(
      'listSessionFiles returns only seeded .jsonl files under the root',
      () async {
        final fs = FakeSessionFileSystem()
          ..addFile(
            '/root/-proj/a.jsonl',
            lines: const ['{"line":1}'],
          )
          ..addFile(
            '/root/-proj/notes.txt',
            lines: const ['not a session'],
          )
          ..addFile(
            '/other-root/-proj/b.jsonl',
            lines: const ['{"line":1}'],
          );

        final result = await fs.listSessionFiles(rootPath: '/root');

        expect(result.isSuccess, isTrue);
        expect(
          result.valueOrNull?.map((ref) => ref.path).toList(),
          ['/root/-proj/a.jsonl'],
        );
      },
    );

    test('stat returns seeded metadata for an existing file', () async {
      final modifiedAt = DateTime.utc(2026, 7, 31, 12);
      final fs = FakeSessionFileSystem()
        ..addFile(
          '/root/-proj/a.jsonl',
          lines: const ['12345'],
          modifiedAt: modifiedAt,
        );
      final ref = SessionFileRef.fromPath('/root/-proj/a.jsonl');

      final result = await fs.stat(ref);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.modifiedAt, modifiedAt);
      expect(result.valueOrNull?.sizeBytes, '12345'.length);
    });

    test('stat returns sessionNotFound for a file that was removed', () async {
      final fs = FakeSessionFileSystem()
        ..addFile('/root/-proj/a.jsonl', lines: const ['x'])
        ..removeFile('/root/-proj/a.jsonl');
      final ref = SessionFileRef.fromPath('/root/-proj/a.jsonl');

      final result = await fs.stat(ref);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.code, FailureCode.sessionNotFound);
    });

    test('readLines streams seeded lines in order', () async {
      final fs = FakeSessionFileSystem()
        ..addFile(
          '/root/-proj/a.jsonl',
          lines: const ['{"a":1}', '{"a":2}'],
        );
      final ref = SessionFileRef.fromPath('/root/-proj/a.jsonl');

      final lines = await fs.readLines(ref).toList();

      expect(lines, ['{"a":1}', '{"a":2}']);
    });

    test('readLines errors for a file that was never seeded', () async {
      final fs = FakeSessionFileSystem();
      final ref = SessionFileRef.fromPath('/root/-proj/missing.jsonl');

      await expectLater(fs.readLines(ref).toList(), throwsStateError);
    });

    test('records calls for assertion', () async {
      final fs = FakeSessionFileSystem()
        ..addFile('/root/-proj/a.jsonl', lines: const ['x']);
      final ref = SessionFileRef.fromPath('/root/-proj/a.jsonl');

      await fs.listSessionFiles(rootPath: '/root');
      await fs.stat(ref);

      expect(fs.calls, [
        'listSessionFiles(/root)',
        'stat(/root/-proj/a.jsonl)',
      ]);
    });
  });
}
