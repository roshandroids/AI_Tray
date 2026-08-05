import 'package:ai_tray/core/logging/buffered_app_logger.dart';
import 'package:ai_tray/core/logging/logging_providers.dart';
import 'package:ai_tray/features/diagnostics/presentation/logs_page.dart';
import 'package:ai_tray/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpPage(
    WidgetTester tester,
    BufferedAppLogger logger,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [bufferedAppLoggerProvider.overrideWithValue(logger)],
        child: MaterialApp(theme: AppTheme.dark(), home: const LogsPage()),
      ),
    );
  }

  testWidgets(
    'grouping a small provider renders its rows directly, no scroll cap',
    (tester) async {
      final logger = BufferedAppLogger();
      for (var i = 0; i < 5; i++) {
        logger.info('entry $i', provider: 'claude');
      }

      await pumpPage(tester, logger);
      await tester.tap(find.byTooltip('Group by provider'));
      await tester.pump();

      expect(
        find.byType(SizedBox).evaluate().any((e) {
          final box = e.widget as SizedBox;
          return box.height == 320;
        }),
        isFalse,
      );
    },
  );

  testWidgets(
    'grouping a busy provider (over the virtualize threshold) caps it in a '
    'bounded, scrollable list',
    (tester) async {
      final logger = BufferedAppLogger(capacity: 200);
      for (var i = 0; i < 40; i++) {
        logger.info('entry $i', provider: 'claude');
      }

      await pumpPage(tester, logger);
      await tester.tap(find.byTooltip('Group by provider'));
      await tester.pump();

      expect(
        find.byType(SizedBox).evaluate().any((e) {
          final box = e.widget as SizedBox;
          return box.height == 320;
        }),
        isTrue,
      );
      // Rows render most-recent-first; only a viewport's worth should be
      // mounted at once, so the oldest ("entry 0") stays off-screen.
      expect(find.textContaining('entry 39'), findsOneWidget);
      expect(find.textContaining('entry 0'), findsNothing);
    },
  );
}
