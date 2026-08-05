import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/logging/console_app_logger.dart';
import 'package:ai_tray/features/notifications/data/repositories/shared_preferences_notification_history_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferencesNotificationHistoryRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repository = SharedPreferencesNotificationHistoryRepository(
      prefs,
      logger: ConsoleAppLogger(defaultName: 'notification_history_test'),
    );
  });

  test('list() is empty for a fresh install', () async {
    final result = await repository.list();

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, isEmpty);
  });

  test('record() adds an entry that list() then returns', () async {
    final recordResult = await repository.record(
      title: 'AI Tray',
      body: 'Session usage at 90%',
    );

    expect(recordResult.isSuccess, isTrue);
    final listResult = await repository.list();
    expect(listResult.valueOrNull!.single.body, 'Session usage at 90%');
  });

  test('persists across repository instances sharing the same prefs', () async {
    await repository.record(title: 'AI Tray', body: 'first');

    final prefs = await SharedPreferences.getInstance();
    final reloaded = SharedPreferencesNotificationHistoryRepository(
      prefs,
      logger: ConsoleAppLogger(defaultName: 'notification_history_test'),
    );

    final result = await reloaded.list();
    expect(result.valueOrNull, hasLength(1));
  });

  test('evicts the oldest entry once the bounded list is full', () async {
    for (
      var i = 0;
      i < SharedPreferencesNotificationHistoryRepository.maxSize;
      i++
    ) {
      await repository.record(title: 'AI Tray', body: 'entry-$i');
    }

    await repository.record(title: 'AI Tray', body: 'newest');

    final items = (await repository.list()).valueOrNull!;
    expect(
      items,
      hasLength(SharedPreferencesNotificationHistoryRepository.maxSize),
    );
    expect(items.map((e) => e.body), isNot(contains('entry-0')));
    expect(items.map((e) => e.body), contains('newest'));
  });

  test('clear() empties the history', () async {
    await repository.record(title: 'AI Tray', body: 'first');
    await repository.clear();

    final result = await repository.list();
    expect(result.valueOrNull, isEmpty);
  });

  test(
    'a malformed stored entry (missing body) is skipped, not fatal to '
    'list()',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'notification_history_v1',
        '[{"title":"AI Tray","sentAt":"2026-07-31T00:00:00.000Z"}]',
      );

      final result = await repository.list();

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isEmpty);
    },
  );

  test('a non-JSON stored value maps to cacheUnavailable', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notification_history_v1', 'not-json{{{');

    final result = await repository.list();

    expect(result.failureOrNull?.code, FailureCode.cacheUnavailable);
  });
}
