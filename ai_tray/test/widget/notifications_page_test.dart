import 'package:ai_tray/features/notifications/data/repositories/fake_notification_history_repository.dart';
import 'package:ai_tray/features/notifications/domain/models/notification_history_entry.dart';
import 'package:ai_tray/features/notifications/notification_providers.dart';
import 'package:ai_tray/features/notifications/presentation/notifications_page.dart';
import 'package:ai_tray/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpPage(
    WidgetTester tester,
    FakeNotificationHistoryRepository repository,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationHistoryRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const NotificationsPage(),
        ),
      ),
    );
  }

  testWidgets('renders the empty state when there is no history', (
    tester,
  ) async {
    await pumpPage(tester, FakeNotificationHistoryRepository());
    await tester.pump();

    expect(find.byKey(const ValueKey('notifications-empty')), findsOneWidget);
  });

  testWidgets('renders each recorded notification, newest first', (
    tester,
  ) async {
    final repository = FakeNotificationHistoryRepository(
      entries: [
        NotificationHistoryEntry(
          title: 'AI Tray',
          body: 'older entry',
          sentAt: DateTime.utc(2026, 7, 31),
        ),
        NotificationHistoryEntry(
          title: 'AI Tray',
          body: 'newer entry',
          sentAt: DateTime.utc(2026, 8, 1),
        ),
      ],
    );

    await pumpPage(tester, repository);
    await tester.pump();

    expect(find.text('older entry'), findsOneWidget);
    expect(find.text('newer entry'), findsOneWidget);
  });

  testWidgets('clearing history removes every entry after confirmation', (
    tester,
  ) async {
    final repository = FakeNotificationHistoryRepository(
      entries: [
        NotificationHistoryEntry(
          title: 'AI Tray',
          body: 'entry',
          sentAt: DateTime.utc(2026, 7, 31),
        ),
      ],
    );

    await pumpPage(tester, repository);
    await tester.pump();

    await tester.tap(find.byTooltip('Clear history'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('notifications-empty')), findsOneWidget);
  });
}
