import 'package:ai_tray/core/logging/app_logger.dart';
import 'package:ai_tray/core/notifications/notification_gateway.dart';
import 'package:ai_tray/features/notifications/domain/repositories/notification_history_repository.dart';

/// Decorates a [NotificationGateway] so every notification the app shows —
/// the usage-threshold notification, queue-completion notifications, and
/// Diagnostics' "Test notification" button alike — lands in history (V4
/// §9.4), from one choke point instead of touching each call site.
///
/// A history-write failure is logged and swallowed, never thrown: the
/// notification itself already fired by the time the history write runs,
/// so a failure to log it is not worth surfacing to the caller.
final class HistoryRecordingNotificationGateway implements NotificationGateway {
  HistoryRecordingNotificationGateway(
    this._delegate,
    this._history, {
    required AppLogger logger,
  }) : _logger = logger;

  final NotificationGateway _delegate;
  final NotificationHistoryRepository _history;
  final AppLogger _logger;

  @override
  Future<void> notify({
    required String title,
    required String body,
    void Function()? onClick,
  }) async {
    await _delegate.notify(title: title, body: body, onClick: onClick);
    final result = await _history.record(title: title, body: body);
    final failure = result.failureOrNull;
    if (failure != null) {
      _logger.warning(
        'failed to record notification history',
        name: 'notification_history',
        error: failure,
      );
    }
  }
}
