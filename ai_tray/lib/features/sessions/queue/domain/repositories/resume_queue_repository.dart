import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/sessions/domain/models/resume_outcome.dart';
import 'package:ai_tray/features/sessions/queue/domain/models/resume_queue_item.dart';
import 'package:ai_tray/features/usage/data/cache/usage_cache.dart' show Unit;

/// Bounded, persisted Resume Queue (§9 of
/// `docs/planning/v2-vision-and-roadmap.md`). Modeled on
/// `SettingsRepository`'s read/write shape; storage is
/// `SharedPreferences`-backed (one JSON array under a single key), unlike
/// `SessionRepository`, which owns no persisted state at all.
abstract interface class ResumeQueueRepository {
  Future<Result<List<ResumeQueueItem>>> list();

  /// Adds a new item. Fails with a visible error — never silently evicts
  /// a `pending`/`running` item — if the bounded list is full and nothing
  /// `succeeded`/`failed` is eligible to evict (§9).
  Future<Result<ResumeQueueItem>> enqueue({
    required String sessionId,
    required String cwd,
    required String prompt,
    required double maxBudgetUsd,
    bool forkSession = true,
  });

  Future<Result<Unit>> updateStatus(
    String id, {
    required ResumeQueueStatus status,
    DateTime? executedAt,
    ResumeOutcome? result,
  });

  Future<Result<Unit>> remove(String id);
}
