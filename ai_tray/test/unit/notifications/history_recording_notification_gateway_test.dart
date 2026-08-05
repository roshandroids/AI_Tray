import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/logging/console_app_logger.dart';
import 'package:ai_tray/core/notifications/fake_notification_gateway.dart';
import 'package:ai_tray/features/notifications/data/history_recording_notification_gateway.dart';
import 'package:ai_tray/features/notifications/data/repositories/fake_notification_history_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shows the notification and records it to history', () async {
    final delegate = FakeNotificationGateway();
    final history = FakeNotificationHistoryRepository();
    final gateway = HistoryRecordingNotificationGateway(
      delegate,
      history,
      logger: ConsoleAppLogger(defaultName: 'gateway_test'),
    );

    await gateway.notify(title: 'AI Tray', body: 'Session usage at 90%');

    expect(delegate.calls, hasLength(1));
    expect(delegate.calls.single.body, 'Session usage at 90%');
    expect(history.recordCallCount, 1);
    final entries = (await history.list()).valueOrNull!;
    expect(entries.single.body, 'Session usage at 90%');
  });

  test(
    'a history-write failure is swallowed, not thrown — the notification '
    'already fired',
    () async {
      final delegate = FakeNotificationGateway();
      final history = FakeNotificationHistoryRepository()
        ..recordFailure = FailureCode.unknown;
      final gateway = HistoryRecordingNotificationGateway(
        delegate,
        history,
        logger: ConsoleAppLogger(defaultName: 'gateway_test'),
      );

      await gateway.notify(title: 'AI Tray', body: 'test');

      expect(delegate.calls, hasLength(1));
    },
  );
}
