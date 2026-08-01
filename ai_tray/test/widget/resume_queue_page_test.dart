import 'package:ai_tray/core/theme/app_theme.dart';
import 'package:ai_tray/features/sessions/queue/data/repositories/fake_resume_queue_repository.dart';
import 'package:ai_tray/features/sessions/queue/domain/models/resume_queue_item.dart';
import 'package:ai_tray/features/sessions/queue/presentation/resume_queue_page.dart';
import 'package:ai_tray/features/sessions/queue/queue_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ResumeQueueItem item({
    required String id,
    required String sessionId,
    ResumeQueueStatus status = ResumeQueueStatus.pending,
  }) {
    return ResumeQueueItem(
      id: id,
      sessionId: sessionId,
      cwd: '/home/claude/proj',
      prompt: 'continue',
      maxBudgetUsd: 2,
      createdAt: DateTime.utc(2026, 7, 31),
      status: status,
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

  testWidgets('renders one item of each status', (tester) async {
    final repository = FakeResumeQueueRepository(
      items: [
        item(id: '1', sessionId: 'pending-one'),
        item(
          id: '2',
          sessionId: 'running-one',
          status: ResumeQueueStatus.running,
        ),
        item(
          id: '3',
          sessionId: 'succeeded-one',
          status: ResumeQueueStatus.succeeded,
        ),
        item(
          id: '4',
          sessionId: 'failed-one',
          status: ResumeQueueStatus.failed,
        ),
      ],
    );

    await pumpPage(tester, repository);
    await tester.pumpAndSettle();

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
    expect(find.text('pending-one'), findsOneWidget);
    expect(find.text('running-one'), findsOneWidget);
    expect(find.text('succeeded-one'), findsOneWidget);
    expect(find.text('failed-one'), findsOneWidget);
  });

  testWidgets('renders the empty state when the queue has no items', (
    tester,
  ) async {
    await pumpPage(tester, FakeResumeQueueRepository());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('queue-empty')), findsOneWidget);
  });
}
