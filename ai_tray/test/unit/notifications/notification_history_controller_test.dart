import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/features/notifications/data/repositories/fake_notification_history_repository.dart';
import 'package:ai_tray/features/notifications/domain/models/notification_history_entry.dart';
import 'package:ai_tray/features/notifications/notification_providers.dart';
import 'package:ai_tray/features/notifications/presentation/notification_history_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ProviderContainer container(FakeNotificationHistoryRepository repository) {
    return ProviderContainer(
      overrides: [
        notificationHistoryRepositoryProvider.overrideWithValue(repository),
      ],
    );
  }

  test('build() populates state from the repository, newest first', () async {
    final repository = FakeNotificationHistoryRepository(
      entries: [
        NotificationHistoryEntry(
          title: 'AI Tray',
          body: 'older',
          sentAt: DateTime.utc(2026, 7, 31),
        ),
        NotificationHistoryEntry(
          title: 'AI Tray',
          body: 'newer',
          sentAt: DateTime.utc(2026, 8, 1),
        ),
      ],
    );
    final ref = container(repository);
    addTearDown(ref.dispose);

    final result = await ref.read(
      notificationHistoryControllerProvider.future,
    );

    expect(result.first.body, 'newer');
    expect(result.last.body, 'older');
  });

  test('build() surfaces a repository read failure as AsyncError', () async {
    final repository = FakeNotificationHistoryRepository()
      ..listFailure = FailureCode.cacheUnavailable;
    final ref = container(repository);
    addTearDown(ref.dispose);

    await expectLater(
      ref.read(notificationHistoryControllerProvider.future),
      throwsA(isA<StateError>()),
    );
    expect(
      ref.read(notificationHistoryControllerProvider).hasError,
      isTrue,
    );
  });

  test('clear() empties the list and refreshes', () async {
    final repository = FakeNotificationHistoryRepository(
      entries: [
        NotificationHistoryEntry(
          title: 'AI Tray',
          body: 'entry',
          sentAt: DateTime.utc(2026, 7, 31),
        ),
      ],
    );
    final ref = container(repository);
    addTearDown(ref.dispose);
    await ref.read(notificationHistoryControllerProvider.future);

    final ok = await ref
        .read(notificationHistoryControllerProvider.notifier)
        .clear();

    expect(ok, isTrue);
    expect(ref.read(notificationHistoryControllerProvider).value, isEmpty);
  });

  test(
    'clear() returns false, without throwing, on a repository failure',
    () async {
      final repository = FakeNotificationHistoryRepository(
        entries: [
          NotificationHistoryEntry(
            title: 'AI Tray',
            body: 'entry',
            sentAt: DateTime.utc(2026, 7, 31),
          ),
        ],
      )..clearFailure = FailureCode.unknown;
      final ref = container(repository);
      addTearDown(ref.dispose);
      await ref.read(notificationHistoryControllerProvider.future);

      final ok = await ref
          .read(notificationHistoryControllerProvider.notifier)
          .clear();

      expect(ok, isFalse);
      // Repository failed to clear; the entry is still there.
      expect(
        ref.read(notificationHistoryControllerProvider).value,
        hasLength(1),
      );
    },
  );
}
