import 'dart:convert';
import 'dart:io';

import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/logging/app_logger.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/sessions/domain/ports/session_file_system.dart';

/// Production [SessionFileSystem] backed by `dart:io`.
final class IoSessionFileSystem implements SessionFileSystem {
  IoSessionFileSystem({required AppLogger logger}) : _logger = logger;

  final AppLogger _logger;

  /// Resolves `~/.claude/projects` cross-platform (macOS/Linux via `HOME`,
  /// Windows via `USERPROFILE`). Callers decide whether to use this default
  /// or an overridden root; this class never hardcodes it internally so it
  /// stays fully testable against an arbitrary temp directory.
  static String defaultClaudeProjectsRoot() {
    final home =
        Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '';
    final sep = Platform.pathSeparator;
    return '$home$sep.claude${sep}projects';
  }

  @override
  Future<Result<List<SessionFileRef>>> listSessionFiles({
    required String rootPath,
  }) async {
    final root = Directory(rootPath);
    if (!root.existsSync()) {
      // No sessions yet is a normal state, not a failure.
      return const Result.success([]);
    }
    try {
      final refs = <SessionFileRef>[];
      await for (final entity in root.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is! File || !entity.path.endsWith('.jsonl')) continue;
        refs.add(SessionFileRef.fromPath(entity.path));
      }
      return Result.success(refs);
    } on Exception catch (error, stackTrace) {
      _logger.warning(
        'session file enumeration failed: $error',
        name: 'session_fs',
        error: error,
        stackTrace: stackTrace,
      );
      return const Result.failure(
        AppFailure(
          code: FailureCode.unknown,
          message: 'Could not read Claude session files',
        ),
      );
    }
  }

  @override
  Future<Result<SessionFileStat>> stat(SessionFileRef file) async {
    try {
      // Sync stat avoids dart:io's known-slow async stat path for a single,
      // quick metadata lookup (very_good_analysis avoid_slow_async_io).
      final fileStat = File(file.path).statSync();
      if (fileStat.type == FileSystemEntityType.notFound) {
        return const Result.failure(
          AppFailure(
            code: FailureCode.sessionNotFound,
            message: 'Session transcript is no longer available',
          ),
        );
      }
      return Result.success(
        SessionFileStat(
          sizeBytes: fileStat.size,
          modifiedAt: fileStat.modified.toUtc(),
        ),
      );
    } on Exception catch (error, stackTrace) {
      _logger.warning(
        'session file stat failed: $error',
        name: 'session_fs',
        error: error,
        stackTrace: stackTrace,
      );
      return const Result.failure(
        AppFailure(
          code: FailureCode.unknown,
          message: 'Could not read session file metadata',
        ),
      );
    }
  }

  @override
  Stream<String> readLines(SessionFileRef file) {
    return File(file.path)
        .openRead()
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter());
  }
}
