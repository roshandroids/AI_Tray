import 'package:ai_tray/features/sessions/detail/presentation/session_detail_open_request.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts as null (no request yet)', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(sessionDetailOpenRequestProvider), isNull);
  });

  test('open() records the requested session id', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(sessionDetailOpenRequestProvider.notifier).open('abc');

    expect(container.read(sessionDetailOpenRequestProvider)?.sessionId, 'abc');
  });

  test(
    'requesting the same session id twice produces distinct events — a '
    'listener keyed on value-equality would otherwise miss the second '
    'click',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final seen = <SessionDetailOpenRequestState>[];
      container.listen<SessionDetailOpenRequestState>(
        sessionDetailOpenRequestProvider,
        (previous, next) => seen.add(next),
        fireImmediately: true,
      );

      container.read(sessionDetailOpenRequestProvider.notifier).open('abc');
      container.read(sessionDetailOpenRequestProvider.notifier).open('abc');

      expect(seen, hasLength(3)); // initial null + two distinct requests
      expect(seen[1]?.sessionId, 'abc');
      expect(seen[2]?.sessionId, 'abc');
      expect(seen[1]?.revision, isNot(seen[2]?.revision));
    },
  );
}
