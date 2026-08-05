import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/sessions/domain/models/resume_outcome.dart';
import 'package:ai_tray/features/sessions/queue/domain/models/resume_queue_item.dart';
import 'package:ai_tray/features/sessions/queue/domain/repositories/resume_queue_repository.dart';
import 'package:ai_tray/features/usage/data/cache/usage_cache.dart' show Unit;

/// In-memory [ResumeQueueRepository] for tests — mirrors
/// `FakeSessionRepository`'s configurable-response shape.
final class FakeResumeQueueRepository implements ResumeQueueRepository {
  FakeResumeQueueRepository({List<ResumeQueueItem> items = const []})
    : _items = List.of(items);

  final List<ResumeQueueItem> _items;
  int _idCounter = 0;

  /// Set to make the next [enqueue] call fail with this code.
  FailureCode? enqueueFailure;

  /// Set to make every [list] call fail with this code.
  FailureCode? listFailure;

  /// Set to make the next [remove] call fail with this code.
  FailureCode? removeFailure;

  /// Calls made, for assertions.
  int listCallCount = 0;

  @override
  Future<Result<List<ResumeQueueItem>>> list() async {
    listCallCount++;
    final failureCode = listFailure;
    if (failureCode != null) {
      return Result.failure(
        AppFailure(code: failureCode, message: 'list failed'),
      );
    }
    return Result.success(List.unmodifiable(_items));
  }

  @override
  Future<Result<ResumeQueueItem>> enqueue({
    required String sessionId,
    required String cwd,
    required String prompt,
    required double maxBudgetUsd,
    bool forkSession = true,
  }) async {
    final failureCode = enqueueFailure;
    if (failureCode != null) {
      return Result.failure(
        AppFailure(code: failureCode, message: 'enqueue failed'),
      );
    }
    final item = ResumeQueueItem(
      id: 'fake-${_idCounter++}',
      sessionId: sessionId,
      cwd: cwd,
      prompt: prompt,
      maxBudgetUsd: maxBudgetUsd,
      createdAt: DateTime.now().toUtc(),
      forkSession: forkSession,
    );
    _items.add(item);
    return Result.success(item);
  }

  @override
  Future<Result<Unit>> updateStatus(
    String id, {
    required ResumeQueueStatus status,
    DateTime? startedAt,
    DateTime? executedAt,
    ResumeOutcome? result,
  }) async {
    for (var i = 0; i < _items.length; i++) {
      if (_items[i].id == id) {
        _items[i] = _items[i].copyWith(
          status: status,
          startedAt: startedAt,
          executedAt: executedAt,
          result: result,
        );
        break;
      }
    }
    return const Result.success(Unit.unit);
  }

  @override
  Future<Result<Unit>> remove(String id) async {
    final failureCode = removeFailure;
    if (failureCode != null) {
      return Result.failure(
        AppFailure(code: failureCode, message: 'remove failed'),
      );
    }
    _items.removeWhere((i) => i.id == id);
    return const Result.success(Unit.unit);
  }

  @override
  Future<Result<Unit>> cancel(String id) async {
    for (var i = 0; i < _items.length; i++) {
      if (_items[i].id == id) {
        _items[i] = _items[i].copyWith(status: ResumeQueueStatus.cancelled);
        break;
      }
    }
    return const Result.success(Unit.unit);
  }

  @override
  Future<Result<Unit>> retry(String id) async {
    for (var i = 0; i < _items.length; i++) {
      if (_items[i].id == id) {
        final item = _items[i];
        _items[i] = ResumeQueueItem(
          id: item.id,
          sessionId: item.sessionId,
          cwd: item.cwd,
          prompt: item.prompt,
          maxBudgetUsd: item.maxBudgetUsd,
          createdAt: item.createdAt,
          forkSession: item.forkSession,
        );
        break;
      }
    }
    return const Result.success(Unit.unit);
  }
}
