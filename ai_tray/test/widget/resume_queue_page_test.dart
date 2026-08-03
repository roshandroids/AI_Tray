import 'package:ai_tray/features/sessions/queue/data/repositories/fake_resume_queue_repository.dart';
import 'package:ai_tray/features/sessions/queue/domain/models/resume_queue_item.dart';
import 'package:ai_tray/features/sessions/queue/presentation/resume_queue_page.dart';
import 'package:ai_tray/features/sessions/queue/queue_providers.dart';
import 'package:ai_tray/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ResumeQueueItem item({
    required String id,
    required String sessionId,
    String cwd = '/home/claude/proj',
    ResumeQueueStatus status = ResumeQueueStatus.pending,
    DateTime? startedAt,
    DateTime? executedAt,
  }) {
    return ResumeQueueItem(
      id: id,
      sessionId: sessionId,
      cwd: cwd,
      prompt: 'continue',
      maxBudgetUsd: 2,
      createdAt: DateTime.utc(2026, 7, 31),
      status: status,
      startedAt: startedAt,
      executedAt: executedAt,
    );
  }

  Future<void> pumpPage(
    WidgetTester tester,
    FakeResumeQueueRepository repository,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          resumeQueueRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const ResumeQueuePage(),
        ),
      ),
    );
  }

  testWidgets('renders one item of each status, labeled by project', (
    tester,
  ) async {
    final repository = FakeResumeQueueRepository(
      items: [
        item(id: '1', sessionId: 'a', cwd: '/home/claude/pending-proj'),
        item(
          id: '2',
          sessionId: 'b',
          cwd: '/home/claude/running-proj',
          status: ResumeQueueStatus.running,
        ),
        item(
          id: '3',
          sessionId: 'c',
          cwd: '/home/claude/succeeded-proj',
          status: ResumeQueueStatus.succeeded,
        ),
        item(
          id: '4',
          sessionId: 'd',
          cwd: '/home/claude/failed-proj',
          status: ResumeQueueStatus.failed,
        ),
      ],
    );

    await pumpPage(tester, repository);
    await tester.pump();

    expect(
      find.byKey(const ValueKey('queue-status-pending')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('queue-status-running')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('queue-status-succeeded')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('queue-status-failed')),
      findsOneWidget,
    );
    expect(find.text('pending-proj'), findsOneWidget);
    expect(find.text('running-proj'), findsOneWidget);
    expect(find.text('succeeded-proj'), findsOneWidget);
    expect(find.text('failed-proj'), findsOneWidget);
  });

  testWidgets('renders the empty state when the queue has no items', (
    tester,
  ) async {
    await pumpPage(tester, FakeResumeQueueRepository());
    await tester.pump();

    expect(find.byKey(const ValueKey('queue-empty')), findsOneWidget);
  });

  testWidgets('tapping remove on a pending item deletes it from the list', (
    tester,
  ) async {
    final repository = FakeResumeQueueRepository(
      items: [item(id: '1', sessionId: 'a', cwd: '/home/claude/pending-proj')],
    );

    await pumpPage(tester, repository);
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('queue-remove-1')));
    await tester.pump();

    expect(find.text('pending-proj'), findsNothing);
    expect(find.byKey(const ValueKey('queue-empty')), findsOneWidget);
  });

  testWidgets('the remove button is disabled for a running item', (
    tester,
  ) async {
    final repository = FakeResumeQueueRepository(
      items: [
        item(
          id: '1',
          sessionId: 'a',
          status: ResumeQueueStatus.running,
        ),
      ],
    );

    await pumpPage(tester, repository);
    await tester.pump();

    final button = tester.widget<IconButton>(
      find.byKey(const ValueKey('queue-remove-1')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('a failed item shows a Retry action that resets it to '
      'pending', (tester) async {
    final repository = FakeResumeQueueRepository(
      items: [item(id: '1', sessionId: 'a', status: ResumeQueueStatus.failed)],
    );

    await pumpPage(tester, repository);
    await tester.pump();

    expect(find.byKey(const ValueKey('queue-retry-1')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('queue-retry-1')));
    await tester.pump();

    expect(find.byKey(const ValueKey('queue-status-pending')), findsOneWidget);
    expect(find.byKey(const ValueKey('queue-retry-1')), findsNothing);
  });

  testWidgets('a pending item shows no Retry action', (tester) async {
    final repository = FakeResumeQueueRepository(
      items: [item(id: '1', sessionId: 'a')],
    );

    await pumpPage(tester, repository);
    await tester.pump();

    expect(find.byKey(const ValueKey('queue-retry-1')), findsNothing);
  });

  testWidgets('shows elapsed duration for a running item and total '
      'duration for a finished one', (tester) async {
    final started = DateTime.utc(2026, 7, 31, 12);
    final finished = started.add(const Duration(seconds: 45));
    final repository = FakeResumeQueueRepository(
      items: [
        item(
          id: '1',
          sessionId: 'a',
          cwd: '/home/claude/succeeded-proj',
          status: ResumeQueueStatus.succeeded,
          startedAt: started,
          executedAt: finished,
        ),
      ],
    );

    await pumpPage(tester, repository);
    await tester.pump();

    expect(find.textContaining('45s'), findsOneWidget);
  });
}
