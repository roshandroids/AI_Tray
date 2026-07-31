import 'package:ai_tray/core/notifications/fake_notification_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('records title, body, and onClick for each call', () async {
    final gateway = FakeNotificationGateway();
    var clicked = false;

    await gateway.notify(
      title: 'AI Tray',
      body: 'Session usage at 90%',
      onClick: () => clicked = true,
    );

    expect(gateway.calls, hasLength(1));
    expect(gateway.calls.single.title, 'AI Tray');
    expect(gateway.calls.single.body, 'Session usage at 90%');
    gateway.calls.single.onClick?.call();
    expect(clicked, isTrue);
  });

  test('onClick is optional and defaults to null', () async {
    final gateway = FakeNotificationGateway();

    await gateway.notify(title: 'AI Tray', body: 'no click handler');

    expect(gateway.calls.single.onClick, isNull);
  });

  test('records every call in order', () async {
    final gateway = FakeNotificationGateway();

    await gateway.notify(title: 'first', body: '1');
    await gateway.notify(title: 'second', body: '2');

    expect(gateway.calls.map((c) => c.title), ['first', 'second']);
  });
}
