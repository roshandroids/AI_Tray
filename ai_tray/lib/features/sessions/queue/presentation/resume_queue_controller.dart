import 'package:ai_tray/core/logging/logging_providers.dart';
import 'package:ai_tray/features/sessions/queue/domain/models/resume_queue_item.dart';
import 'package:ai_tray/features/sessions/queue/queue_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Owns loading, refresh, enqueue, and run-next actions for the Resume
/// Queue page (Feature 2.2.2) — same `AsyncNotifier` shape as
/// `SessionBrowserController`.
///
/// Enqueuing never triggers execution by itself — an item sits `pending`
/// until the user presses "Run next" (this controller's [runNext]) or a
/// future auto-execute setting is turned on (design principle 2: "an item
/// sitting in the queue is inert until the user turns on auto-execute or
/// presses 'run' themselves"). No auto-execute toggle exists yet in this
/// pass — see the implementation log for why that's a deliberate scope
/// decision, not an oversight.
final class ResumeQueueController extends AsyncNotifier<List<ResumeQueueItem>> {
  @override
  Future<List<ResumeQueueItem>> build() => _load();

  Future<void> refresh() async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  /// Adds a new item. Returns `false` (without throwing) on failure —
  /// e.g. the bounded queue is full with nothing eligible to evict — so
  /// the enqueue form can show an inline error instead of crashing.
  Future<bool> enqueue({
    required String sessionId,
    required String cwd,
    required String prompt,
    required double maxBudgetUsd,
  }) async {
    final result = await ref
        .read(resumeQueueRepositoryProvider)
        .enqueue(
          sessionId: sessionId,
          cwd: cwd,
          prompt: prompt,
          maxBudgetUsd: maxBudgetUsd,
        );
    final failure = result.failureOrNull;
    if (failure != null) {
      ref
          .read(appLoggerProvider)
          .warning(
            'enqueue failed sessionId=$sessionId',
            name: 'resume_queue',
            error: failure,
          );
      return false;
    }
    await refresh();
    return true;
  }

  /// Runs the oldest pending item via the executor (single-flight; a
  /// second concurrent call while one is in flight is a no-op — see
  /// `ResumeQueueExecutor`), then reloads the list.
  Future<void> runNext() async {
    await ref.read(resumeQueueExecutorProvider).runNext();
    await refresh();
  }

  /// Removes one item — a queued-but-not-yet-run item, or a
  /// succeeded/failed item the user wants cleared from history. Callers
  /// must not offer this for a `running` item (no cooperative
  /// cancellation exists yet — deferred to v3 per the roadmap). Returns
  /// `false` (without throwing) on failure so the page can show an
  /// inline error instead of crashing.
  Future<bool> remove(String id) async {
    final result = await ref.read(resumeQueueRepositoryProvider).remove(id);
    final failure = result.failureOrNull;
    if (failure != null) {
      ref
          .read(appLoggerProvider)
          .warning(
            'remove failed id=$id',
            name: 'resume_queue',
            error: failure,
          );
      return false;
    }
    await refresh();
    return true;
  }

  /// Cancels a `pending` item — unlike [remove], it stays in the list
  /// (marked `cancelled`) so it shows up in the queue's history (V4
  /// §6.1) instead of disappearing. Returns `false` (without throwing) on
  /// failure so the page can show an inline error instead of crashing.
  Future<bool> cancel(String id) async {
    final result = await ref.read(resumeQueueRepositoryProvider).cancel(id);
    final failure = result.failureOrNull;
    if (failure != null) {
      ref
          .read(appLoggerProvider)
          .warning(
            'cancel failed id=$id',
            name: 'resume_queue',
            error: failure,
          );
      return false;
    }
    await refresh();
    return true;
  }

  /// Resets a `failed` item back to `pending` so "Run next" can pick it
  /// up again, clearing its previous outcome (design principle 4: a
  /// retry starts clean, it doesn't carry the old failure forward).
  /// Returns `false` (without throwing) on failure so the page can show
  /// an inline error instead of crashing.
  Future<bool> retry(String id) async {
    final result = await ref.read(resumeQueueRepositoryProvider).retry(id);
    final failure = result.failureOrNull;
    if (failure != null) {
      ref
          .read(appLoggerProvider)
          .warning('retry failed id=$id', name: 'resume_queue', error: failure);
      return false;
    }
    await refresh();
    return true;
  }

  Future<List<ResumeQueueItem>> _load() async {
    final result = await ref.read(resumeQueueRepositoryProvider).list();
    final failure = result.failureOrNull;
    if (failure != null) {
      ref
          .read(appLoggerProvider)
          .warning(
            'resume queue load failed',
            name: 'resume_queue',
            error: failure,
          );
      throw StateError(failure.message);
    }
    return result.valueOrNull ?? const [];
  }
}

final resumeQueueControllerProvider =
    AsyncNotifierProvider<ResumeQueueController, List<ResumeQueueItem>>(
      ResumeQueueController.new,
    );
