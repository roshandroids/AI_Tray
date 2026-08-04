import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/logging/app_logger.dart';
import 'package:ai_tray/core/notifications/notification_gateway.dart';
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
///
/// Notifies on every terminal outcome (Feature 2.3.1) via
/// [NotificationGateway], with an `onClick` closure that calls
/// `onOpenSessionDetail` — a plain callback, not a `ref`, so this class
/// stays a plain, Riverpod-free unit like every other data-layer class in
/// this codebase (`ClaudeSessionService`, `FileSystemSessionRepository`);
/// `queue_providers.dart` is where that callback gets wired to
/// `sessionDetailOpenRequestProvider`.
final class ResumeQueueExecutor {
  ResumeQueueExecutor({
    required ResumeQueueRepository repository,
    required ClaudeSessionService sessionService,
    required AppLogger logger,
    required bool Function(String path) directoryExists,
    required NotificationGateway notificationGateway,
    void Function(String sessionId)? onOpenSessionDetail,
  }) : _repository = repository,
       _sessionService = sessionService,
       _logger = logger,
       _directoryExists = directoryExists,
       _notificationGateway = notificationGateway,
       _onOpenSessionDetail = onOpenSessionDetail;

  final ResumeQueueRepository _repository;
  final ClaudeSessionService _sessionService;
  final AppLogger _logger;
  final bool Function(String path) _directoryExists;
  final NotificationGateway _notificationGateway;
  final void Function(String sessionId)? _onOpenSessionDetail;

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
      await _notifyCompletion(next, succeeded: false);
      return;
    }

    await _repository.updateStatus(
      next.id,
      status: ResumeQueueStatus.running,
      startedAt: DateTime.now().toUtc(),
    );

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
      await _notifyCompletion(next, succeeded: true);
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
    await _notifyCompletion(next, succeeded: false);
  }

  Future<void> _notifyCompletion(
    ResumeQueueItem item, {
    required bool succeeded,
  }) async {
    await _notificationGateway.notify(
      title: 'AI Tray',
      body: succeeded
          ? 'Queued resume completed for ${item.sessionId}'
          : 'Queued resume failed for ${item.sessionId}',
      onClick: () => _onOpenSessionDetail?.call(item.sessionId),
    );
  }
}
