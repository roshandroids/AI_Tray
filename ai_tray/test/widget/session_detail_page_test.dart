import 'dart:convert';

import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/logging/console_app_logger.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/core/theme/app_theme.dart';
import 'package:ai_tray/features/providers/data/process/fake_process_runner.dart';
import 'package:ai_tray/features/providers/data/process/process_runner.dart';
import 'package:ai_tray/features/sessions/data/process/claude_session_service.dart';
import 'package:ai_tray/features/sessions/data/repositories/fake_session_repository.dart';
import 'package:ai_tray/features/sessions/detail/presentation/session_detail_page.dart';
import 'package:ai_tray/features/sessions/domain/models/claude_session.dart';
import 'package:ai_tray/features/sessions/domain/models/session_token_totals.dart';
import 'package:ai_tray/features/sessions/session_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ClaudeSession session({
    required String id,
    bool isComplete = true,
    bool? isLive,
  }) {
    return ClaudeSession(
      sessionId: id,
      sanitizedProjectDirName: '-home-claude-ai-tray',
      projectPath: '/home/claude/ai-tray',
      lastActivityAt: DateTime.now().toUtc(),
      messageCount: 7,
      tokenTotals: const SessionTokenTotals(
        inputTokens: 120,
        outputTokens: 48,
      ),
      isComplete: isComplete,
      isLive: isLive,
      model: 'claude-opus-5',
      gitBranch: 'main',
    );
  }

  Future<void> pumpPage(
    WidgetTester tester,
    FakeSessionRepository repository, {
    String sessionId = 'abc',
    FakeProcessRunner? resumeRunner,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(repository),
          if (resumeRunner != null)
            claudeSessionServiceProvider.overrideWithValue(
              ClaudeSessionService(
                processRunner: resumeRunner,
                logger: ConsoleAppLogger(
                  defaultName: 'session_detail_page_test',
                ),
              ),
            ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: SessionDetailPage(sessionId: sessionId),
        ),
      ),
    );
  }

  testWidgets('renders session detail fields', (tester) async {
    final repository = FakeSessionRepository()
      ..setSession(session(id: 'abc'));

    await pumpPage(tester, repository);
    await tester.pumpAndSettle();

    expect(find.text('/home/claude/ai-tray'), findsOneWidget);
    expect(find.text('claude-opus-5'), findsOneWidget);
    expect(find.text('main'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('renders the session-not-found state instead of throwing', (
    tester,
  ) async {
    final repository = FakeSessionRepository()
      ..setSessionFailure('missing', FailureCode.sessionNotFound);

    await pumpPage(tester, repository, sessionId: 'missing');
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('session-detail-not-found')),
      findsOneWidget,
    );
    expect(find.text('Session no longer available'), findsOneWidget);
  });

  testWidgets('renders an incomplete-session indicator honestly', (
    tester,
  ) async {
    final repository = FakeSessionRepository()
      ..setSession(session(id: 'abc', isComplete: false));

    await pumpPage(tester, repository);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('session-incomplete')), findsOneWidget);
  });

  testWidgets('does not render the incomplete indicator for a complete '
      'session', (tester) async {
    final repository = FakeSessionRepository()
      ..setSession(session(id: 'abc'));

    await pumpPage(tester, repository);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('session-incomplete')), findsNothing);
  });

  testWidgets('shows a live badge only when the session is confirmed live', (
    tester,
  ) async {
    final repository = FakeSessionRepository()
      ..setSession(session(id: 'abc', isLive: true));

    await pumpPage(tester, repository);
    await tester.pumpAndSettle();

    expect(find.text('Live'), findsOneWidget);
  });

  testWidgets('Resume now is disabled until a prompt is entered', (
    tester,
  ) async {
    final repository = FakeSessionRepository()..setSession(session(id: 'abc'));

    await pumpPage(tester, repository, resumeRunner: FakeProcessRunner());
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('resume-now-button')),
    );
    expect(button.onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('resume-prompt-field')),
      'continue please',
    );
    await tester.pump();

    final enabledButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('resume-now-button')),
    );
    expect(enabledButton.onPressed, isNotNull);
  });

  testWidgets(
    'tapping Resume now renders cost, tokens, turns, and stop reason',
    (tester) async {
      final repository = FakeSessionRepository()
        ..setSession(session(id: 'abc'));
      final runner = FakeProcessRunner()
        ..handler = (exe, args) {
          return Result.success(
            ProcessRunResult(
              exitCode: 0,
              stdout: jsonEncode({
                'is_error': false,
                'num_turns': 4,
                'stop_reason': 'end_turn',
                'session_id': 'abc',
                'total_cost_usd': 0.0123,
                'usage': {'input_tokens': 200, 'output_tokens': 80},
                'result': 'Added the requested feature.',
              }),
              stderr: '',
              duration: Duration.zero,
            ),
          );
        };

      await pumpPage(tester, repository, resumeRunner: runner);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('resume-prompt-field')),
        'continue please',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('resume-now-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('resume-result')), findsOneWidget);
      expect(find.text('\$0.0123'), findsOneWidget);
      expect(find.text('200 in / 80 out'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('end_turn'), findsOneWidget);
      expect(find.text('Added the requested feature.'), findsOneWidget);
    },
  );

  testWidgets('a resume failure renders an error message, not a crash', (
    tester,
  ) async {
    final repository = FakeSessionRepository()..setSession(session(id: 'abc'));
    final runner = FakeProcessRunner()
      ..handler = (exe, args) {
        return const Result.failure(
          AppFailure(code: FailureCode.timeout, message: 'timed out'),
        );
      };

    await pumpPage(tester, repository, resumeRunner: runner);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('resume-prompt-field')),
      'continue please',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('resume-now-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('resume-error')), findsOneWidget);
  });

  testWidgets(
    'Resume now is unavailable when the project path could not be decoded',
    (tester) async {
      final repository = FakeSessionRepository()
        ..setSession(
          const ClaudeSession(
            sessionId: 'abc',
            sanitizedProjectDirName: '-home-claude-ai-tray',
            messageCount: 1,
            tokenTotals: SessionTokenTotals(),
            isComplete: true,
          ),
        );

      await pumpPage(tester, repository, resumeRunner: FakeProcessRunner());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('resume-prompt-field')),
        findsNothing,
      );
      expect(find.textContaining('Resume is unavailable'), findsOneWidget);
    },
  );
}
