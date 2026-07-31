import 'package:ai_tray/core/result/result.dart';
import 'package:meta/meta.dart';

/// Reference to one Claude Code session transcript file, identified by its
/// on-disk path under
/// `~/.claude/projects/<sanitized-project-dir>/<session-id>.jsonl`
/// (layout confirmed in `docs/claude_code_cli_capability_report.md` §3B).
@immutable
final class SessionFileRef {
  /// Derives [sessionId] and [sanitizedProjectDirName] from [path] alone,
  /// so `IoSessionFileSystem` and `FakeSessionFileSystem` always agree on
  /// what a given path means. Accepts both `/` and `\` separators without
  /// depending on `dart:io.Platform`, keeping this a pure domain type.
  factory SessionFileRef.fromPath(String path) {
    final segments = path
        .split(RegExp(r'[\\/]'))
        .where((segment) => segment.isNotEmpty)
        .toList(growable: false);
    final fileName = segments.isEmpty ? path : segments.last;
    const suffix = '.jsonl';
    final sessionId = fileName.endsWith(suffix)
        ? fileName.substring(0, fileName.length - suffix.length)
        : fileName;
    final sanitizedProjectDirName = segments.length >= 2
        ? segments[segments.length - 2]
        : '';
    return SessionFileRef._(
      path: path,
      sessionId: sessionId,
      sanitizedProjectDirName: sanitizedProjectDirName,
    );
  }

  const SessionFileRef._({
    required this.path,
    required this.sessionId,
    required this.sanitizedProjectDirName,
  });

  /// Absolute path to the `.jsonl` transcript file.
  final String path;

  /// Session id, derived from the file name (without the `.jsonl` suffix).
  final String sessionId;

  /// Raw, still-encoded project directory name (`/` sanitized to `-` by
  /// Claude Code). See `ClaudeProjectPathDecoder` (`data/fs/`) to attempt
  /// reversing it for display — this type never guesses at the real path
  /// itself (design principle 3).
  final String sanitizedProjectDirName;

  @override
  bool operator ==(Object other) =>
      other is SessionFileRef && other.path == path;

  @override
  int get hashCode => path.hashCode;

  @override
  String toString() => 'SessionFileRef($path)';
}

/// Size and last-modified time for one session transcript file.
@immutable
final class SessionFileStat {
  const SessionFileStat({required this.sizeBytes, required this.modifiedAt});

  final int sizeBytes;
  final DateTime modifiedAt;

  @override
  bool operator ==(Object other) {
    return other is SessionFileStat &&
        other.sizeBytes == sizeBytes &&
        other.modifiedAt == modifiedAt;
  }

  @override
  int get hashCode => Object.hash(sizeBytes, modifiedAt);

  @override
  String toString() =>
      'SessionFileStat(sizeBytes: $sizeBytes, modifiedAt: $modifiedAt)';
}

/// Testable filesystem boundary for Claude session transcripts — no
/// Claude-specific parsing here, mirrors `ProcessRunner`'s port+fake shape
/// (`features/providers/data/process/process_runner.dart`).
abstract interface class SessionFileSystem {
  /// Enumerates every `.jsonl` session file under [rootPath].
  ///
  /// A [rootPath] that does not exist is a normal, empty state (e.g. a
  /// fresh Claude Code install with no sessions yet) and returns
  /// `Result.success(const [])`, not a failure. Only a genuine read error
  /// (permission denied, I/O error) returns `Result.failure`.
  Future<Result<List<SessionFileRef>>> listSessionFiles({
    required String rootPath,
  });

  /// Size and modified time for [file].
  ///
  /// Returns a failure coded `sessionNotFound` if the file no longer
  /// exists — a real race between listing and reading a session (a file
  /// can be deleted or moved between the two calls).
  Future<Result<SessionFileStat>> stat(SessionFileRef file);

  /// Streams [file]'s contents one line at a time, in order.
  ///
  /// Decodes with a malformed-tolerant UTF-8 decoder: a transcript can end
  /// mid multi-byte character if the writing process was killed
  /// (design principle 4 — a killed process is an accepted, ordinary
  /// state), so this never throws on decode. It does not wrap I/O errors
  /// (e.g. the file disappearing mid-read) — those surface as a normal
  /// stream error event for the caller to handle.
  Stream<String> readLines(SessionFileRef file);
}
