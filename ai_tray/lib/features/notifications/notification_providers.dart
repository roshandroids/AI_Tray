import 'package:ai_tray/core/logging/logging_providers.dart';
import 'package:ai_tray/features/notifications/data/repositories/shared_preferences_notification_history_repository.dart';
import 'package:ai_tray/features/notifications/domain/repositories/notification_history_repository.dart';
import 'package:ai_tray/features/settings/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bounded, persisted record of every notification the app has shown (V4
/// §9.4).
final notificationHistoryRepositoryProvider =
    Provider<NotificationHistoryRepository>((ref) {
      return SharedPreferencesNotificationHistoryRepository(
        ref.watch(sharedPreferencesProvider),
        logger: ref.watch(appLoggerProvider),
      );
    });
