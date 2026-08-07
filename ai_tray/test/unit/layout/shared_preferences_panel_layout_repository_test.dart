import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/logging/console_app_logger.dart';
import 'package:ai_tray/features/layout/data/repositories/shared_preferences_panel_layout_repository.dart';
import 'package:ai_tray/features/layout/domain/models/panel_layout_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferencesPanelLayoutRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repository = SharedPreferencesPanelLayoutRepository(
      prefs,
      logger: ConsoleAppLogger(defaultName: 'panel_layout_test'),
    );
  });

  test('loadAll() is empty for a fresh install', () async {
    final result = await repository.loadAll();

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, isEmpty);
  });

  test('save() writes an entry that loadAll() then returns', () async {
    final saveResult = await repository.save(
      'session_detail.queue_task',
      const PanelLayoutState(heightPx: 240, isExpanded: true),
    );

    expect(saveResult.isSuccess, isTrue);
    final loaded = await repository.loadAll();
    expect(
      loaded.valueOrNull!['session_detail.queue_task'],
      const PanelLayoutState(heightPx: 240, isExpanded: true),
    );
  });

  test('save() for a second panelId does not clobber the first', () async {
    await repository.save(
      'session_detail.queue_task',
      const PanelLayoutState(heightPx: 240, isExpanded: true),
    );
    await repository.save(
      'session_detail.advanced',
      const PanelLayoutState(heightPx: 180, isExpanded: false),
    );

    final loaded = (await repository.loadAll()).valueOrNull!;
    expect(loaded, hasLength(2));
    expect(loaded['session_detail.queue_task']?.heightPx, 240);
    expect(loaded['session_detail.advanced']?.heightPx, 180);
  });

  test('persists across repository instances sharing the same prefs', () async {
    await repository.save(
      'session_detail.queue_task',
      const PanelLayoutState(heightPx: 300, isExpanded: true),
    );

    final prefs = await SharedPreferences.getInstance();
    final reloaded = SharedPreferencesPanelLayoutRepository(
      prefs,
      logger: ConsoleAppLogger(defaultName: 'panel_layout_test'),
    );

    final result = await reloaded.loadAll();
    expect(result.valueOrNull, hasLength(1));
  });

  test('clear() empties the layout map', () async {
    await repository.save(
      'session_detail.queue_task',
      const PanelLayoutState(heightPx: 240, isExpanded: true),
    );
    await repository.clear();

    final result = await repository.loadAll();
    expect(result.valueOrNull, isEmpty);
  });

  test(
    'a malformed stored entry (missing isExpanded) is skipped, not fatal '
    'to loadAll()',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'panel_layout_v1',
        '{"session_detail.queue_task":{"heightPx":240}}',
      );

      final result = await repository.loadAll();

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isEmpty);
    },
  );

  test('a non-JSON stored value maps to cacheUnavailable', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('panel_layout_v1', 'not-json{{{');

    final result = await repository.loadAll();

    expect(result.failureOrNull?.code, FailureCode.cacheUnavailable);
  });
}
