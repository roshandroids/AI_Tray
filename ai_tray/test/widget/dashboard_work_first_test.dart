import 'package:ai_tray/core/di/providers.dart';
import 'package:ai_tray/core/logging/buffered_app_logger.dart';
import 'package:ai_tray/core/logging/console_app_logger.dart';
import 'package:ai_tray/core/logging/logging_providers.dart';
import 'package:ai_tray/core/navigation/app_destination.dart';
import 'package:ai_tray/core/navigation/app_shell_providers.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/providers/data/claude/claude_cli_adapter.dart';
import 'package:ai_tray/features/providers/data/process/fake_process_runner.dart';
import 'package:ai_tray/features/providers/data/process/process_runner.dart';
import 'package:ai_tray/features/sessions/data/repositories/fake_session_repository.dart';
import 'package:ai_tray/features/sessions/domain/models/session_summary.dart';
import 'package:ai_tray/features/sessions/queue/data/repositories/fake_resume_queue_repository.dart';
import 'package:ai_tray/features/sessions/queue/domain/models/resume_queue_item.dart';
import 'package:ai_tray/features/sessions/queue/queue_providers.dart';
import 'package:ai_tray/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:ai_tray/features/usage/data/cache/usage_cache.dart';
import 'package:ai_tray/features/usage/data/parsers/usage_parser.dart';
import 'package:ai_tray/features/usage/data/repositories/usage_repository_impl.dart';
import 'package:ai_tray/features/usage/data/services/refresh_service.dart';
import 'package:ai_tray/features/usage/data/validators/usage_validator.dart';
import 'package:ai_tray/features/usage/presentation/usage_page.dart';
import 'package:ai_tray/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProviderContainer _containerWith({
  required FakeSessionRepository sessions,
  required FakeResumeQueueRepository queue,
}) {
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
      processRunnerProvider.overrideWithValue(runner),
      sessionRepositoryProvider.overrideWithValue(sessions),
      resumeQueueRepositoryProvider.overrideWithValue(queue),
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
  SessionSummary summary(String sessionId, String projectPath) {
    return SessionSummary(
      sessionId: sessionId,
      sanitizedProjectDirName: projectPath.replaceAll('/', '-'),
      projectPath: projectPath,
      lastActivityAt: DateTime.now().toUtc(),
      messageCount: 3,
    );
  }

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('continue button is disabled with no sessions and Recent '
      'Sessions/Queue show empty states', (tester) async {
    final container = _containerWith(
      sessions: FakeSessionRepository(sessions: const []),
      queue: FakeResumeQueueRepository(items: const []),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.dark(), home: const UsagePage()),
      ),
    );
    await tester.pump();

    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Continue last session'),
        matching: find.byWidgetPredicate((widget) => widget is FilledButton),
      ),
    );
    expect(button.onPressed, isNull);
    expect(find.text('No sessions yet'), findsOneWidget);
    expect(find.text('No queued tasks'), findsOneWidget);
  });

  testWidgets('continue button opens the most recent session', (
    tester,
  ) async {
    final container = _containerWith(
      sessions: FakeSessionRepository(
        sessions: [summary('abc', '/home/claude/ai-tray')],
      ),
      queue: FakeResumeQueueRepository(
        items: [
          ResumeQueueItem(
            id: 'q1',
            sessionId: 'abc',
            cwd: '/home/claude/ai-tray',
            prompt: 'fix the bug',
            maxBudgetUsd: 2,
            createdAt: DateTime.now().toUtc(),
          ),
        ],
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.dark(), home: const UsagePage()),
      ),
    );
    await tester.pump();

    expect(find.text('/home/claude/ai-tray'), findsOneWidget);
    expect(find.textContaining('fix the bug'), findsOneWidget);

    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Continue last session'),
        matching: find.byWidgetPredicate((widget) => widget is FilledButton),
      ),
    );
    expect(button.onPressed, isNotNull);

    await tester.tap(find.text('Continue last session'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('claude-opus-5'), findsNothing);
    expect(find.byType(Scaffold), findsWidgets);
  });

  testWidgets('View all under Recent Sessions switches the shell '
      'destination to Sessions', (tester) async {
    final container = _containerWith(
      sessions: FakeSessionRepository(
        sessions: [summary('abc', '/home/claude/ai-tray')],
      ),
      queue: FakeResumeQueueRepository(items: const []),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.dark(), home: const UsagePage()),
      ),
    );
    await tester.pump();

    expect(
      container.read(appShellDestinationProvider),
      AppDestination.dashboard,
    );

    await tester.tap(find.text('View all').first);
    await tester.pump();

    expect(
      container.read(appShellDestinationProvider),
      AppDestination.sessions,
    );
  });
}
