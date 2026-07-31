import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/logging/app_logger.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/sessions/data/fs/io_session_file_system.dart';
import 'package:ai_tray/features/sessions/data/parsers/jsonl_session_parser.dart';
import 'package:ai_tray/features/sessions/data/process/claude_session_service.dart';
import 'package:ai_tray/features/sessions/data/process/session_liveness_merger.dart';
import 'package:ai_tray/features/sessions/domain/models/claude_session.dart';
import 'package:ai_tray/features/sessions/domain/models/session_summary.dart';
import 'package:ai_tray/features/sessions/domain/ports/session_file_system.dart';
import 'package:ai_tray/features/sessions/domain/repositories/session_repository.dart';

/// Production [SessionRepository]: composes Feature 1.1.1's
/// [SessionFileSystem], Feature 1.1.2's [JsonlSessionParser] index pass, and
/// Feature 1.1.3's [ClaudeSessionService] liveness enrichment — no new
/// filesystem or CLI logic of its own (reuse over invention, §9).
final class FileSystemSessionRepository implements SessionRepository {
  FileSystemSessionRepository({
    required SessionFileSystem fileSystem,
    required ClaudeSessionService sessionService,
    required AppLogger logger,
    required bool Function(String path) directoryExists,
    String? rootPath,
    JsonlSessionParser parser = const JsonlSessionParser(),
  }) : _fileSystem = fileSystem,
       _sessionService = sessionService,
       _logger = logger,
       _directoryExists = directoryExists,
       _rootPath = rootPath ?? IoSessionFileSystem.defaultClaudeProjectsRoot(),
       _parser = parser;

  final SessionFileSystem _fileSystem;
  final ClaudeSessionService _sessionService;
  final AppLogger _logger;
  final bool Function(String path) _directoryExists;
  final String _rootPath;
  final JsonlSessionParser _parser;

  @override
  Future<Result<List<SessionSummary>>> listSessions() async {
    final filesResult = await _fileSystem.listSessionFiles(
      rootPath: _rootPath,
    );
    final failure = filesResult.failureOrNull;
    if (failure != null) return Result.failure(failure);
    final files = filesResult.valueOrNull ?? const [];

    final summaries = <SessionSummary>[];
    for (final file in files) {
      final statResult = await _fileSystem.stat(file);
      final stat = statResult.valueOrNull;
      if (stat == null) {
        // A session can be deleted or moved between listing and stat'ing
        // it (design principle 4's "killed process" reasoning extends to
        // ordinary cleanup too) — skip it, don't fail the whole list.
        _logger.warning(
          'skipping session with unreadable stat: ${file.path}',
          name: 'session_repository',
        );
        continue;
      }
      summaries.add(
        _parser.summarize(
          file: file,
          stat: stat,
          directoryExists: _directoryExists,
        ),
      );
    }

    final liveness = await _sessionService.listLiveSessions();
    return Result.success(mergeSessionLiveness(summaries, liveness));
  }

  @override
  Future<Result<ClaudeSession>> readSession(String sessionId) async {
    final filesResult = await _fileSystem.listSessionFiles(
      rootPath: _rootPath,
    );
    final failure = filesResult.failureOrNull;
    if (failure != null) return Result.failure(failure);
    final files = filesResult.valueOrNull ?? const [];

    SessionFileRef? match;
    for (final file in files) {
      if (file.sessionId == sessionId) {
        match = file;
        break;
      }
    }
    if (match == null) {
      return const Result.failure(
        AppFailure(
          code: FailureCode.sessionNotFound,
          message: 'Session transcript is no longer available',
        ),
      );
    }

    final session = await _parser.parseSession(
      file: match,
      lines: _fileSystem.readLines(match),
    );
    final liveness = await _sessionService.listLiveSessions();
    return Result.success(
      liveness.when(
        success: (liveIds) =>
            session.copyWith(isLive: liveIds.contains(sessionId)),
        onFailure: (_) => session,
      ),
    );
  }
}
