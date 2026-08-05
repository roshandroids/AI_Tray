import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/notifications/domain/models/notification_history_entry.dart';
import 'package:ai_tray/features/notifications/domain/repositories/notification_history_repository.dart';
import 'package:ai_tray/features/usage/data/cache/usage_cache.dart' show Unit;

/// In-memory [NotificationHistoryRepository] for tests.
final class FakeNotificationHistoryRepository
    implements NotificationHistoryRepository {
  FakeNotificationHistoryRepository({
    List<NotificationHistoryEntry> entries = const [],
  }) : _entries = List.of(entries);

  final List<NotificationHistoryEntry> _entries;

  /// Set to make every [list] call fail with this code.
  FailureCode? listFailure;

  /// Set to make the next [record] call fail with this code.
  FailureCode? recordFailure;

  /// Set to make the next [clear] call fail with this code.
  FailureCode? clearFailure;

  /// Calls made, for assertions.
  int recordCallCount = 0;

  @override
  Future<Result<List<NotificationHistoryEntry>>> list() async {
    final failureCode = listFailure;
    if (failureCode != null) {
      return Result.failure(
        AppFailure(code: failureCode, message: 'list failed'),
      );
    }
    return Result.success(List.unmodifiable(_entries));
  }

  @override
  Future<Result<Unit>> record({
    required String title,
    required String body,
  }) async {
    recordCallCount++;
    final failureCode = recordFailure;
    if (failureCode != null) {
      return Result.failure(
        AppFailure(code: failureCode, message: 'record failed'),
      );
    }
    _entries.add(
      NotificationHistoryEntry(
        title: title,
        body: body,
        sentAt: DateTime.now().toUtc(),
      ),
    );
    return const Result.success(Unit.unit);
  }

  @override
  Future<Result<Unit>> clear() async {
    final failureCode = clearFailure;
    if (failureCode != null) {
      return Result.failure(
        AppFailure(code: failureCode, message: 'clear failed'),
      );
    }
    _entries.clear();
    return const Result.success(Unit.unit);
  }
}
