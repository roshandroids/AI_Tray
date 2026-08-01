import 'package:ai_tray/core/notifications/notification_gateway.dart';

/// One recorded [FakeNotificationGateway.notify] call.
final class RecordedNotification {
  const RecordedNotification({
    required this.title,
    required this.body,
    this.onClick,
  });

  final String title;
  final String body;
  final void Function()? onClick;
}

/// In-memory [NotificationGateway] for tests — mirrors `FakeProcessRunner`/
/// `FakeSessionFileSystem`'s call-recording shape rather than a mock.
final class FakeNotificationGateway implements NotificationGateway {
  final List<RecordedNotification> calls = [];

  @override
  Future<void> notify({
    required String title,
    required String body,
    void Function()? onClick,
  }) async {
    calls.add(RecordedNotification(title: title, body: body, onClick: onClick));
  }
}
