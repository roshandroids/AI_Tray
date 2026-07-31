import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/sessions/domain/ports/session_file_system.dart';

/// In-memory [SessionFileSystem] for unit tests. Seed an in-memory
/// directory tree with [addFile] before exercising a repository or parser
/// against it; [removeFile] simulates a session disappearing between calls.
final class FakeSessionFileSystem implements SessionFileSystem {
  final Map<String, _FakeFile> _files = {};

  /// Records every call made, for assertions in tests.
  final List<String> calls = [];

  void addFile(
    String path, {
    required List<String> lines,
    DateTime? modifiedAt,
  }) {
    _files[path] = _FakeFile(
      lines: List<String>.from(lines),
      modifiedAt: modifiedAt ?? DateTime.now().toUtc(),
    );
  }

  void removeFile(String path) => _files.remove(path);

  @override
  Future<Result<List<SessionFileRef>>> listSessionFiles({
    required String rootPath,
  }) async {
    calls.add('listSessionFiles($rootPath)');
    final refs = _files.keys
        .where((path) => path.startsWith(rootPath) && path.endsWith('.jsonl'))
        .map(SessionFileRef.fromPath)
        .toList(growable: false);
    return Result.success(refs);
  }

  @override
  Future<Result<SessionFileStat>> stat(SessionFileRef file) async {
    calls.add('stat(${file.path})');
    final found = _files[file.path];
    if (found == null) {
      return const Result.failure(
        AppFailure(
          code: FailureCode.sessionNotFound,
          message: 'Session transcript is no longer available',
        ),
      );
    }
    return Result.success(
      SessionFileStat(
        sizeBytes: found.lines.join('\n').length,
        modifiedAt: found.modifiedAt,
      ),
    );
  }

  @override
  Stream<String> readLines(SessionFileRef file) {
    calls.add('readLines(${file.path})');
    final found = _files[file.path];
    if (found == null) {
      return Stream<String>.error(
        StateError('FakeSessionFileSystem has no file at ${file.path}'),
      );
    }
    return Stream.fromIterable(found.lines);
  }
}

final class _FakeFile {
  _FakeFile({required this.lines, required this.modifiedAt});

  final List<String> lines;
  final DateTime modifiedAt;
}
