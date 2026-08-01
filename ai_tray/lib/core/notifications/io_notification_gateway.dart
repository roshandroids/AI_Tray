import 'package:ai_tray/core/logging/app_logger.dart';
import 'package:ai_tray/core/notifications/notification_gateway.dart';
import 'package:local_notifier/local_notifier.dart';

/// Production [NotificationGateway] wrapping `local_notifier`. Behavior
/// preserved from the pre-gateway `TrayController.maybeNotify`: any
/// failure is logged and swallowed, never thrown into the caller — a
/// missed notification is not worth crashing a background refresh over.
final class IoNotificationGateway implements NotificationGateway {
  IoNotificationGateway({required AppLogger logger}) : _logger = logger;

  final AppLogger _logger;

  @override
  Future<void> notify({
    required String title,
    required String body,
    void Function()? onClick,
  }) async {
    try {
      final notification = LocalNotification(title: title, body: body);
      if (onClick != null) notification.onClick = onClick;
      await notification.show();
    } on Exception catch (error) {
      _logger.warning('notification failed: $error', name: 'notifications');
    }
  }
}
