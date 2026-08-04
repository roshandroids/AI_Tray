import 'package:ai_tray/features/sessions/browser/presentation/session_browser_page.dart';
import 'package:ai_tray/features/sessions/data/repositories/fake_session_repository.dart';
import 'package:ai_tray/features/sessions/domain/models/claude_session.dart';
import 'package:ai_tray/features/sessions/domain/models/session_summary.dart';
import 'package:ai_tray/features/sessions/domain/models/session_token_totals.dart';
import 'package:ai_tray/features/sessions/session_providers.dart';
import 'package:ai_tray/theme/app_theme.dart';
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

  testWidgets('renders a populated project group, expanded by default, with '
      'path, activity, and count', (tester) async {
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

    expect(find.textContaining('/home/claude/ai-tray'), findsOneWidget);
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
    expect(find.textContaining('/home/claude/x'), findsOneWidget);
  });

  testWidgets('refresh reloads and reflects a newly added project', (
    tester,
  ) async {
    final repository = FakeSessionRepository(
      sessions: [summary(sessionId: 'a', projectPath: '/home/claude/a')],
    );

    await pumpPage(tester, repository);
    await tester.pumpAndSettle();
    expect(repository.listSessionsCallCount, 1);
    expect(find.textContaining('/home/claude/b'), findsNothing);

    repository.setSessions([
      summary(sessionId: 'a', projectPath: '/home/claude/a'),
      summary(sessionId: 'b', projectPath: '/home/claude/b'),
    ]);
    await tester.tap(find.widgetWithIcon(IconButton, Icons.refresh));
    await tester.pumpAndSettle();

    expect(repository.listSessionsCallCount, 2);
    expect(find.textContaining('/home/claude/b'), findsOneWidget);
  });

  testWidgets('search narrows the groups by project path and clearing '
      'restores them', (tester) async {
    final repository = FakeSessionRepository(
      sessions: [
        summary(sessionId: 'a', projectPath: '/home/claude/ai-tray'),
        summary(sessionId: 'b', projectPath: '/home/claude/other-repo'),
      ],
    );

    await pumpPage(tester, repository);
    await tester.pumpAndSettle();
    expect(find.textContaining('/home/claude/ai-tray'), findsOneWidget);
    expect(find.textContaining('/home/claude/other-repo'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('sessions-search-field')),
      'ai-tray',
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('/home/claude/ai-tray'), findsOneWidget);
    expect(find.textContaining('/home/claude/other-repo'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('sessions-search-field')),
      '',
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('/home/claude/ai-tray'), findsOneWidget);
    expect(find.textContaining('/home/claude/other-repo'), findsOneWidget);
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

  testWidgets('shows a live badge on the group and the live session row', (
    tester,
  ) async {
    final repository = FakeSessionRepository(
      sessions: [
        summary(sessionId: 'a', projectPath: '/home/claude/live', isLive: true),
        summary(
          sessionId: 'b',
          projectPath: '/home/claude/live',
          isLive: false,
        ),
      ],
    );

    await pumpPage(tester, repository);
    await tester.pumpAndSettle();

    // One "Live" on the group header, one on the specific live session row.
    expect(find.text('Live'), findsNWidgets(2));
  });

  testWidgets('tapping a session row opens its detail page', (tester) async {
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

    await tester.tap(find.textContaining('messages'));
    await tester.pumpAndSettle();

    expect(find.text('ai-tray'), findsOneWidget);
  });

  testWidgets('groups sessions by project, most-recently-active group '
      'first', (tester) async {
    final older = DateTime.now().toUtc().subtract(const Duration(days: 2));
    final newer = DateTime.now().toUtc();
    final repository = FakeSessionRepository(
      sessions: [
        summary(
          sessionId: 'a',
          projectPath: '/home/claude/older-project',
          lastActivityAt: older,
        ),
        summary(
          sessionId: 'b',
          projectPath: '/home/claude/newer-project',
          lastActivityAt: newer,
        ),
      ],
    );

    await pumpPage(tester, repository);
    await tester.pumpAndSettle();

    final newerOffset = tester
        .getTopLeft(find.textContaining('/home/claude/newer-project'))
        .dy;
    final olderOffset = tester
        .getTopLeft(find.textContaining('/home/claude/older-project'))
        .dy;
    expect(newerOffset, lessThan(olderOffset));
  });

  testWidgets('pins the group with a live session first even if less '
      'recent', (tester) async {
    final older = DateTime.now().toUtc().subtract(const Duration(days: 2));
    final newer = DateTime.now().toUtc();
    final repository = FakeSessionRepository(
      sessions: [
        summary(
          sessionId: 'a',
          projectPath: '/home/claude/live-but-old',
          lastActivityAt: older,
          isLive: true,
        ),
        summary(
          sessionId: 'b',
          projectPath: '/home/claude/idle-but-new',
          lastActivityAt: newer,
        ),
      ],
    );

    await pumpPage(tester, repository);
    await tester.pumpAndSettle();

    final liveOffset = tester
        .getTopLeft(find.textContaining('/home/claude/live-but-old'))
        .dy;
    final idleOffset = tester
        .getTopLeft(find.textContaining('/home/claude/idle-but-new'))
        .dy;
    expect(liveOffset, lessThan(idleOffset));
  });

  testWidgets('a second, non-pinned project group starts collapsed and '
      'expands on tap', (tester) async {
    final older = DateTime.now().toUtc().subtract(const Duration(days: 2));
    final newer = DateTime.now().toUtc();
    final repository = FakeSessionRepository(
      sessions: [
        summary(
          sessionId: 'a',
          projectPath: '/home/claude/older-project',
          lastActivityAt: older,
          messageCount: 42,
        ),
        summary(
          sessionId: 'b',
          projectPath: '/home/claude/newer-project',
          lastActivityAt: newer,
        ),
      ],
    );

    await pumpPage(tester, repository);
    await tester.pumpAndSettle();

    expect(find.textContaining('42 messages'), findsNothing);

    await tester.tap(find.textContaining('/home/claude/older-project'));
    await tester.pumpAndSettle();

    expect(find.textContaining('42 messages'), findsOneWidget);
  });
}
