import 'package:ai_tray/core/theme/app_theme.dart';
import 'package:ai_tray/features/sessions/browser/presentation/session_browser_page.dart';
import 'package:ai_tray/features/sessions/data/repositories/fake_session_repository.dart';
import 'package:ai_tray/features/sessions/domain/models/claude_session.dart';
import 'package:ai_tray/features/sessions/domain/models/session_summary.dart';
import 'package:ai_tray/features/sessions/domain/models/session_token_totals.dart';
import 'package:ai_tray/features/sessions/session_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  SessionSummary summary({
    required String sessionId,
    required String projectPath,
    bool? isLive,
    DateTime? lastActivityAt,
    int messageCount = 5,
  }) {
    return SessionSummary(
      sessionId: sessionId,
      sanitizedProjectDirName: projectPath.replaceAll('/', '-'),
      projectPath: projectPath,
      lastActivityAt: lastActivityAt ?? DateTime.now().toUtc(),
      messageCount: messageCount,
      isLive: isLive,
    );
  }

  Future<void> pumpPage(
    WidgetTester tester,
    FakeSessionRepository repository,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const SessionBrowserPage(),
        ),
      ),
    );
  }

  testWidgets('renders a populated list with path, activity, and count', (
    tester,
  ) async {
    final repository = FakeSessionRepository(
      sessions: [
        summary(
          sessionId: 'a',
          projectPath: '/home/claude/ai-tray',
          messageCount: 12,
        ),
      ],
    );

    await pumpPage(tester, repository);
    await tester.pumpAndSettle();

    expect(find.text('/home/claude/ai-tray'), findsOneWidget);
    expect(find.textContaining('12 messages'), findsOneWidget);
    expect(find.byKey(const ValueKey('sessions-list')), findsOneWidget);
  });

  testWidgets('renders the empty state when there are no sessions', (
    tester,
  ) async {
    final repository = FakeSessionRepository(sessions: const []);

    await pumpPage(tester, repository);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('sessions-empty')), findsOneWidget);
    expect(find.text('No sessions yet'), findsOneWidget);
  });

  testWidgets('renders a loading indicator before the repository responds', (
    tester,
  ) async {
    final repository = FakeSessionRepository(
      sessions: [summary(sessionId: 'a', projectPath: '/home/claude/x')],
    )..holdNextResponse();

    await pumpPage(tester, repository);
    await tester.pump();

    expect(find.byKey(const ValueKey('sessions-loading')), findsOneWidget);

    repository.releaseResponse();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('sessions-loading')), findsNothing);
    expect(find.text('/home/claude/x'), findsOneWidget);
  });

  testWidgets('refresh reloads and reflects newly added sessions', (
    tester,
  ) async {
    final repository = FakeSessionRepository(
      sessions: [summary(sessionId: 'a', projectPath: '/home/claude/a')],
    );

    await pumpPage(tester, repository);
    await tester.pumpAndSettle();
    expect(repository.listSessionsCallCount, 1);
    expect(find.text('/home/claude/b'), findsNothing);

    repository.setSessions([
      summary(sessionId: 'a', projectPath: '/home/claude/a'),
      summary(sessionId: 'b', projectPath: '/home/claude/b'),
    ]);
    await tester.tap(find.widgetWithIcon(IconButton, Icons.refresh));
    await tester.pumpAndSettle();

    expect(repository.listSessionsCallCount, 2);
    expect(find.text('/home/claude/b'), findsOneWidget);
  });

  testWidgets('search narrows the list by project path and clearing '
      'restores it', (tester) async {
    final repository = FakeSessionRepository(
      sessions: [
        summary(sessionId: 'a', projectPath: '/home/claude/ai-tray'),
        summary(sessionId: 'b', projectPath: '/home/claude/other-repo'),
      ],
    );

    await pumpPage(tester, repository);
    await tester.pumpAndSettle();
    expect(find.text('/home/claude/ai-tray'), findsOneWidget);
    expect(find.text('/home/claude/other-repo'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('sessions-search-field')),
      'ai-tray',
    );
    await tester.pumpAndSettle();

    expect(find.text('/home/claude/ai-tray'), findsOneWidget);
    expect(find.text('/home/claude/other-repo'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('sessions-search-field')),
      '',
    );
    await tester.pumpAndSettle();

    expect(find.text('/home/claude/ai-tray'), findsOneWidget);
    expect(find.text('/home/claude/other-repo'), findsOneWidget);
  });

  testWidgets('search with no matches renders the no-match empty state', (
    tester,
  ) async {
    final repository = FakeSessionRepository(
      sessions: [summary(sessionId: 'a', projectPath: '/home/claude/ai-tray')],
    );

    await pumpPage(tester, repository);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('sessions-search-field')),
      'nonexistent',
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('sessions-no-match')), findsOneWidget);
    expect(find.text('No sessions match this filter'), findsOneWidget);
  });

  testWidgets('shows a live badge only for sessions the CLI confirmed live', (
    tester,
  ) async {
    final repository = FakeSessionRepository(
      sessions: [
        summary(sessionId: 'a', projectPath: '/home/claude/live', isLive: true),
        summary(
          sessionId: 'b',
          projectPath: '/home/claude/not-live',
          isLive: false,
        ),
        summary(
          sessionId: 'c',
          projectPath: '/home/claude/unknown',
        ),
      ],
    );

    await pumpPage(tester, repository);
    await tester.pumpAndSettle();

    expect(find.text('Live'), findsOneWidget);
  });

  testWidgets('tapping a session tile opens its detail page', (tester) async {
    final repository =
        FakeSessionRepository(
          sessions: [
            summary(sessionId: 'abc', projectPath: '/home/claude/ai-tray'),
          ],
        )..setSession(
          const ClaudeSession(
            sessionId: 'abc',
            sanitizedProjectDirName: '-home-claude-ai-tray',
            projectPath: '/home/claude/ai-tray',
            messageCount: 3,
            tokenTotals: SessionTokenTotals(),
            isComplete: true,
            model: 'claude-opus-5',
          ),
        );

    await pumpPage(tester, repository);
    await tester.pumpAndSettle();

    await tester.tap(find.text('/home/claude/ai-tray'));
    await tester.pumpAndSettle();

    expect(find.text('claude-opus-5'), findsOneWidget);
  });
}
