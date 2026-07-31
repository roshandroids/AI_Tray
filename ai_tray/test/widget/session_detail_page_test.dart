import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/theme/app_theme.dart';
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
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(repository),
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
}
