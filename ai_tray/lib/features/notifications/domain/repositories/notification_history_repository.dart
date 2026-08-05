import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/notifications/domain/models/notification_history_entry.dart';
import 'package:ai_tray/features/usage/data/cache/usage_cache.dart' show Unit;

/// Bounded, persisted record of every notification the app has shown (V4
/// §9.4) — same "read-modify-write one JSON array" shape as
/// `ResumeQueueRepository`.
abstract interface class NotificationHistoryRepository {
  Future<Result<List<NotificationHistoryEntry>>> list();

  /// Appends a new entry, evicting the oldest once the bounded list is
  /// full. Unlike the resume queue, every entry here is already terminal
  /// (a notification that already fired) — there is nothing to protect
  /// from eviction.
  Future<Result<Unit>> record({required String title, required String body});

  Future<Result<Unit>> clear();
}
