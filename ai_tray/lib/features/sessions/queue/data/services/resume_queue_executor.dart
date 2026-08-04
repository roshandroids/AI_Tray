import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/logging/app_logger.dart';
import 'package:ai_tray/features/sessions/data/process/claude_session_service.dart';
import 'package:ai_tray/features/sessions/queue/domain/models/resume_queue_item.dart';
import 'package:ai_tray/features/sessions/queue/domain/repositories/resume_queue_repository.dart';

/// Runs the oldest pending queue item at a time (§21, Feature 2.2.2's
/// "Sequential executor" story — the highest-risk story in M2, since the
/// safety model has to compose correctly here).
///
/// Reuses `RefreshService`'s single-flight shape, adapted: `RefreshService`
/// coalesces concurrent calls into the *same* in-flight future because
/// callers want that one shared result. Here there's no single shared
/// result to hand back (each call could be for a different item), so a
/// second concurrent [runNext] simply becomes a no-op instead of joining —
/// the actual guarantee needed is "only one item executes at a time"
/// (acceptance criterion (c)), not "callers all see the same outcome".
final class ResumeQueueExecutor {
  ResumeQueueExecutor({
    required ResumeQueueRepository repository,
    required ClaudeSessionService sessionService,
    required AppLogger logger,
    required bool Function(String path) directoryExists,
  }) : _repository = repository,
       _sessionService = sessionService,
       _logger = logger,
       _directoryExists = directoryExists;

  final ResumeQueueRepository _repository;
  final ClaudeSessionService _sessionService;
  final AppLogger _logger;
  final bool Function(String path) _directoryExists;

  Future<void>? _running;

  Future<void> runNext() {
    final existing = _running;
    if (existing != null) return existing;
    late final Future<void> tracked;
    tracked = _runNextInternal().whenComplete(() {
      if (identical(_running, tracked)) _running = null;
    });
    _running = tracked;
    return tracked;
  }

  Future<void> _runNextInternal() async {
    final listResult = await _repository.list();
    final items = listResult.valueOrNull ?? const <ResumeQueueItem>[];
    ResumeQueueItem? next;
    for (final item in items) {
      if (item.status == ResumeQueueStatus.pending) {
        next = item;
        break;
      }
    }
    if (next == null) return;

    if (!_directoryExists(next.cwd)) {
      // Fail fast and surface — never create the directory or substitute
      // another one (design principle 2).
      _logger.warning(
        'queue item working directory missing sessionId=${next.sessionId}',
        name: 'resume_queue_executor',
        error: const AppFailure(
          code: FailureCode.workingDirectoryMissing,
          message: 'The stored working directory no longer exists',
        ),
      );
      await _repository.updateStatus(
        next.id,
        status: ResumeQueueStatus.failed,
        executedAt: DateTime.now().toUtc(),
      );
      return;
    }

    await _repository.updateStatus(next.id, status: ResumeQueueStatus.running);

    final result = await _sessionService.resume(
      sessionId: next.sessionId,
      prompt: next.prompt,
      workingDirectory: next.cwd,
      forkSession: next.forkSession,
      maxBudgetUsd: next.maxBudgetUsd,
    );
    final executedAt = DateTime.now().toUtc();

    if (result.isSuccess) {
      await _repository.updateStatus(
        next.id,
        status: ResumeQueueStatus.succeeded,
        executedAt: executedAt,
        result: result.valueOrNull,
      );
      return;
    }

    _logger.warning(
      'queue item resume failed sessionId=${next.sessionId}',
      name: 'resume_queue_executor',
      error: result.failureOrNull,
    );
    await _repository.updateStatus(
      next.id,
      status: ResumeQueueStatus.failed,
      executedAt: executedAt,
    );
  }
}
