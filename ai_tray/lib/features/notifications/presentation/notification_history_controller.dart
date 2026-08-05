import 'package:ai_tray/core/logging/logging_providers.dart';
import 'package:ai_tray/features/notifications/domain/models/notification_history_entry.dart';
import 'package:ai_tray/features/notifications/notification_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Owns loading, refresh, and clear for the Notifications page (V4 §9.4) —
/// same `AsyncNotifier` shape as `ResumeQueueController`.
final class NotificationHistoryController
    extends AsyncNotifier<List<NotificationHistoryEntry>> {
  @override
  Future<List<NotificationHistoryEntry>> build() => _load();

  Future<void> refresh() async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<bool> clear() async {
    final result = await ref
        .read(notificationHistoryRepositoryProvider)
        .clear();
    final failure = result.failureOrNull;
    if (failure != null) {
      ref
          .read(appLoggerProvider)
          .warning(
            'clear notification history failed',
            name: 'notification_history',
            error: failure,
          );
      return false;
    }
    await refresh();
    return true;
  }

  Future<List<NotificationHistoryEntry>> _load() async {
    final result = await ref.read(notificationHistoryRepositoryProvider).list();
    final failure = result.failureOrNull;
    if (failure != null) {
      ref
          .read(appLoggerProvider)
          .warning(
            'notification history load failed',
            name: 'notification_history',
            error: failure,
          );
      throw StateError(failure.message);
    }
    // Most-recently-sent first, matching the queue history's convention.
    final entries = result.valueOrNull ?? const [];
    return entries.reversed.toList();
  }
}

final notificationHistoryControllerProvider =
    AsyncNotifierProvider<
      NotificationHistoryController,
      List<NotificationHistoryEntry>
    >(NotificationHistoryController.new);
