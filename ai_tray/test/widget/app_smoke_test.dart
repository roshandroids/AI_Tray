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
import 'package:ai_tray/features/usage/data/cache/usage_cache.dart';
import 'package:ai_tray/features/usage/data/parsers/usage_parser.dart';
import 'package:ai_tray/features/usage/data/repositories/usage_repository_impl.dart';
import 'package:ai_tray/features/usage/data/services/refresh_service.dart';
import 'package:ai_tray/features/usage/data/validators/usage_validator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('foundation shell renders AI Tray title', (tester) async {
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

    final container = ProviderContainer(
      overrides: [
        bufferedAppLoggerProvider.overrideWithValue(logger),
        sharedPreferencesProvider.overrideWithValue(prefs),
        processRunnerProvider.overrideWithValue(runner),
        usageRepositoryProvider.overrideWith((ref) {
          final repo = UsageRepositoryImpl(
            refreshService: RefreshService(
              provider: ClaudeCliAdapter(
                processRunner: runner,
                logger: logger,
              ),
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
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const AiTrayApp(),
      ),
    );
    await tester.pump();

    expect(find.text('AI Tray'), findsOneWidget);
  });
}
