import 'package:ai_tray/app.dart';
import 'package:ai_tray/core/di/providers.dart';
import 'package:ai_tray/core/logging/buffered_app_logger.dart';
import 'package:ai_tray/core/logging/console_app_logger.dart';
import 'package:ai_tray/core/logging/logging_providers.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/providers/data/claude/claude_cli_adapter.dart';
import 'package:ai_tray/features/providers/data/process/fake_process_runner.dart';
import 'package:ai_tray/features/providers/data/process/process_runner.dart';
import 'package:ai_tray/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:ai_tray/features/settings/domain/models/app_settings.dart';
import 'package:ai_tray/features/settings/presentation/settings_controller.dart';
import 'package:ai_tray/features/usage/data/cache/usage_cache.dart';
import 'package:ai_tray/features/usage/data/parsers/usage_parser.dart';
import 'package:ai_tray/features/usage/data/repositories/usage_repository_impl.dart';
import 'package:ai_tray/features/usage/data/services/refresh_service.dart';
import 'package:ai_tray/features/usage/data/validators/usage_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _notOnboardedContainer() async {
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
      settingsRepositoryProvider.overrideWithValue(
        InMemorySettingsRepository(AppSettings.defaults()),
      ),
      applyLaunchAtLoginProvider.overrideWithValue((_) async {}),
      applyPresentationSettingsProvider.overrideWithValue(() async {}),
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
  testWidgets(
    'a fresh install shows onboarding, not the app shell',
    (tester) async {
      final container = await _notOnboardedContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const AiTrayApp(),
        ),
      );
      await tester.pump();

      expect(find.text('Welcome to AI Tray'), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    },
  );

  testWidgets(
    'completing onboarding reveals the app shell',
    (tester) async {
      final container = await _notOnboardedContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const AiTrayApp(),
        ),
      );
      await tester.pump();

      // Welcome -> provider -> CLI check -> tour -> ready.
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.byKey(const ValueKey('onboarding-next')));
        await tester.pumpAndSettle();
      }

      await tester.tap(find.byKey(const ValueKey('onboarding-finish')));
      // Not pumpAndSettle: AppShell's Dashboard polls/animates continuously
      // once shown, so it never fully settles (same reason app_shell_test.dart
      // uses bounded pumps instead of pumpAndSettle after landing there).
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.text('Welcome to AI Tray'), findsNothing);
      expect(
        container.read(settingsRepositoryProvider).read(),
        completion(
          isA<AppSettings>().having(
            (s) => s.hasCompletedOnboarding,
            'hasCompletedOnboarding',
            isTrue,
          ),
        ),
      );
    },
  );

  testWidgets('an already-onboarded install shows the app shell directly', (
    tester,
  ) async {
    final container = await _notOnboardedContainer();
    addTearDown(container.dispose);
    await container
        .read(settingsRepositoryProvider)
        .write(AppSettings.defaults().copyWith(hasCompletedOnboarding: true));

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const AiTrayApp()),
    );
    await tester.pump();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('Welcome to AI Tray'), findsNothing);
  });
}
