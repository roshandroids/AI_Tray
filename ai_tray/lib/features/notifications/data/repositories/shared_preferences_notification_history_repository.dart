import 'dart:convert';

import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/logging/app_logger.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/notifications/domain/models/notification_history_entry.dart';
import 'package:ai_tray/features/notifications/domain/repositories/notification_history_repository.dart';
import 'package:ai_tray/features/usage/data/cache/usage_cache.dart' show Unit;
import 'package:shared_preferences/shared_preferences.dart';

/// Production [NotificationHistoryRepository]: one JSON array under a
/// single, versioned `SharedPreferences` key — same shape as
/// `SharedPreferencesResumeQueueRepository`.
final class SharedPreferencesNotificationHistoryRepository
    implements NotificationHistoryRepository {
  SharedPreferencesNotificationHistoryRepository(
    this._prefs, {
    required AppLogger logger,
  }) : _logger = logger;

  static const _key = 'notification_history_v1';

  /// Bounded — oldest entry evicted first once full.
  static const maxSize = 100;

  final SharedPreferences _prefs;
  final AppLogger _logger;

  @override
  Future<Result<List<NotificationHistoryEntry>>> list() async {
    try {
      final raw = _prefs.getString(_key);
      if (raw == null || raw.isEmpty) return const Result.success([]);

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const Result.failure(
          AppFailure(
            code: FailureCode.cacheUnavailable,
            message: "Couldn't load notification history",
          ),
        );
      }

      final entries = <NotificationHistoryEntry>[];
      for (final entry in decoded) {
        if (entry is! Map) continue;
        final parsed = NotificationHistoryEntry.tryFromJson(
          Map<String, Object?>.from(entry),
        );
        if (parsed == null) {
          _logger.warning(
            'skipping malformed notification history entry',
            name: 'notification_history',
          );
          continue;
        }
        entries.add(parsed);
      }
      return Result.success(entries);
    } on FormatException {
      return const Result.failure(
        AppFailure(
          code: FailureCode.cacheUnavailable,
          message: "Couldn't load notification history",
        ),
      );
    } on Exception {
      return const Result.failure(
        AppFailure(
          code: FailureCode.cacheUnavailable,
          message: "Couldn't load notification history",
        ),
      );
    }
  }

  @override
  Future<Result<Unit>> record({
    required String title,
    required String body,
  }) async {
    final listResult = await list();
    final listFailure = listResult.failureOrNull;
    if (listFailure != null) return Result.failure(listFailure);
    var entries = listResult.valueOrNull ?? const <NotificationHistoryEntry>[];

    if (entries.length >= maxSize) {
      entries = entries.sublist(entries.length - maxSize + 1);
    }

    final newEntry = NotificationHistoryEntry(
      title: title,
      body: body,
      sentAt: DateTime.now().toUtc(),
    );
    return _writeAll([...entries, newEntry]);
  }

  @override
  Future<Result<Unit>> clear() => _writeAll(const []);

  Future<Result<Unit>> _writeAll(List<NotificationHistoryEntry> entries) async {
    try {
      final encoded = jsonEncode(entries.map((e) => e.toJson()).toList());
      final saved = await _prefs.setString(_key, encoded);
      if (!saved) {
        return const Result.failure(
          AppFailure(
            code: FailureCode.cacheUnavailable,
            message: "Couldn't save notification history",
          ),
        );
      }
      return const Result.success(Unit.unit);
    } on Exception {
      return const Result.failure(
        AppFailure(
          code: FailureCode.cacheUnavailable,
          message: "Couldn't save notification history",
        ),
      );
    }
  }
}
