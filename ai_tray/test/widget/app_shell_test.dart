import 'package:ai_tray/app.dart';
import 'package:ai_tray/core/di/providers.dart';
import 'package:ai_tray/core/logging/buffered_app_logger.dart';
import 'package:ai_tray/core/logging/console_app_logger.dart';
import 'package:ai_tray/core/logging/logging_providers.dart';
import 'package:ai_tray/core/navigation/app_destination.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/providers/data/claude/claude_cli_adapter.dart';
import 'package:ai_tray/features/providers/data/process/fake_process_runner.dart';
import 'package:ai_tray/features/providers/data/process/process_runner.dart';
import 'package:ai_tray/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:ai_tray/features/settings/domain/models/app_settings.dart';
import 'package:ai_tray/features/usage/data/cache/usage_cache.dart';
import 'package:ai_tray/features/usage/data/parsers/usage_parser.dart';
import 'package:ai_tray/features/usage/data/repositories/usage_repository_impl.dart';
import 'package:ai_tray/features/usage/data/services/refresh_service.dart';
import 'package:ai_tray/features/usage/data/validators/usage_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _offlineContainer() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final logger = BufferedAppLogger(
    delegate: ConsoleAppLogger(defaultName: 'test'),
  );
  final runner = FakeProcessRunner(
    handler: (exe, args) => const Result.success(
      ProcessRunResult(
        exitCode: 1,
        stdout: '',
        stderr: 'offline test',
        duration: Duration(milliseconds: 1),
      ),
    ),
  );

  return ProviderContainer(
    overrides: [
      bufferedAppLoggerProvider.overrideWithValue(logger),
      sharedPreferencesProvider.overrideWithValue(prefs),
      // These tests exercise AppShell, not onboarding — treat this run as
      // already onboarded.
      settingsRepositoryProvider.overrideWithValue(
        InMemorySettingsRepository(
          AppSettings.defaults().copyWith(hasCompletedOnboarding: true),
        ),
      ),
      processRunnerProvider.overrideWithValue(runner),
      usageRepositoryProvider.overrideWith((ref) {
        final repo = UsageRepositoryImpl(
          refreshService: RefreshService(
            provider: ClaudeCliAdapter(processRunner: runner, logger: logger),
            parser: const UsageParser(),
            validator: UsageValidator(),
            cache: InMemoryUsageCache(),
            logger: logger,
            softRetryDelay: Duration.zero,
            hardRetryDelay: Duration.zero,
          ),
          cache: InMemoryUsageCache(),
          settingsRepository: InMemorySettingsRepository(),
          logger: logger,
        );
        ref.onDispose(repo.dispose);
        return repo;
      }),
    ],
  );
}

void main() {
  testWidgets('nav rail shows all 5 destinations and highlights the tapped '
      'one', (tester) async {
    final container = await _offlineContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const AiTrayApp()),
    );
    await tester.pump();

    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.destinations.length, AppDestination.values.length);
    expect(rail.selectedIndex, AppDestination.dashboard.index);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationRail),
        matching: find.text('Sessions'),
      ),
    );
    await tester.pump();

    final railAfterTap = tester.widget<NavigationRail>(
      find.byType(NavigationRail),
    );
    expect(railAfterTap.selectedIndex, AppDestination.sessions.index);
  });

  testWidgets('Cmd+K opens the command palette', (tester) async {
    final container = await _offlineContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const AiTrayApp()),
    );
    await tester.pump();

    expect(find.text('Type a command or search sessions…'), findsNothing);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyK);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Type a command or search sessions…'), findsOneWidget);
    expect(find.text('Go to Dashboard'), findsOneWidget);
    expect(find.text('Go to Settings'), findsOneWidget);

    await tester.tap(find.text('Go to Settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Type a command or search sessions…'), findsNothing);
    final railAfterAction = tester.widget<NavigationRail>(
      find.byType(NavigationRail),
    );
    expect(railAfterAction.selectedIndex, AppDestination.settings.index);
  });

  testWidgets(
    'the palette can open Help Center and the keyboard shortcuts list',
    (tester) async {
      final container = await _offlineContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const AiTrayApp(),
        ),
      );
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyK);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyK);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      await tester.tap(find.text('Open Help Center'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byKey(const ValueKey('help-list')), findsOneWidget);

      Navigator.of(tester.element(find.byKey(const ValueKey('help-list'))))
          .pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyK);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyK);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      await tester.tap(find.text('Keyboard shortcuts'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Open the command palette'), findsOneWidget);
    },
  );

  testWidgets('arrow keys move the palette highlight, Enter invokes it', (
    tester,
  ) async {
    final container = await _offlineContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const AiTrayApp()),
    );
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyK);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    // Default highlight is the first row (Go to Dashboard); one ArrowDown
    // moves it to the second row (Go to Sessions).
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    // Hardware Enter reaches the field's onSubmitted via the text input
    // engine (TextInputAction.done), not a raw key event, in a real app;
    // simulate that path directly rather than a raw key event in the test.
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Type a command or search sessions…'), findsNothing);
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.selectedIndex, AppDestination.sessions.index);
  });
}
