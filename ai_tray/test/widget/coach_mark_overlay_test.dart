import 'dart:async';

import 'package:ai_tray/core/components/coach_mark_overlay.dart';
import 'package:ai_tray/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeHighlightRect', () {
    testWidgets('returns a rect inflated around an attached target', (
      tester,
    ) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                key: key,
                width: 40,
                height: 20,
                child: const ColoredBox(color: Colors.red),
              ),
            ),
          ),
        ),
      );

      final rect = computeHighlightRect(key, padding: 4);

      expect(rect, isNot(Rect.zero));
      expect(rect.width, 40 + 8);
      expect(rect.height, 20 + 8);
    });

    testWidgets('returns Rect.zero for a key attached to nothing', (
      tester,
    ) async {
      final key = GlobalKey();
      expect(computeHighlightRect(key), Rect.zero);
    });
  });

  group('showCoachMarks', () {
    Future<void> pumpHarness(
      WidgetTester tester,
      GlobalKey targetKey,
      List<CoachMarkStep> Function(GlobalKey) buildSteps, {
      Completer<void>? doneSignal,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  SizedBox(key: targetKey, width: 40, height: 20),
                  TextButton(
                    onPressed: () {
                      unawaited(
                        showCoachMarks(context, buildSteps(targetKey)).then(
                          (_) => doneSignal?.complete(),
                        ),
                      );
                    },
                    child: const Text('start tour'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('Next advances through steps; Done finishes the tour', (
      tester,
    ) async {
      final key = GlobalKey();
      final done = Completer<void>();
      await pumpHarness(
        tester,
        key,
        (k) => [
          CoachMarkStep(targetKey: k, title: 'Step one', body: 'First'),
          CoachMarkStep(targetKey: k, title: 'Step two', body: 'Second'),
        ],
        doneSignal: done,
      );

      await tester.tap(find.text('start tour'));
      await tester.pump();

      expect(find.text('Step one'), findsOneWidget);
      expect(find.text('1 / 2'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('coach-mark-next')));
      await tester.pump();

      expect(find.text('Step two'), findsOneWidget);
      expect(find.text('2 / 2'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('coach-mark-next')));
      await tester.pump();

      expect(find.text('Step two'), findsNothing);
      expect(done.isCompleted, isTrue);
    });

    testWidgets('Skip dismisses the tour immediately', (tester) async {
      final key = GlobalKey();
      final done = Completer<void>();
      await pumpHarness(
        tester,
        key,
        (k) => [
          CoachMarkStep(targetKey: k, title: 'Step one', body: 'First'),
          CoachMarkStep(targetKey: k, title: 'Step two', body: 'Second'),
        ],
        doneSignal: done,
      );

      await tester.tap(find.text('start tour'));
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('coach-mark-skip')));
      await tester.pump();

      expect(find.text('Step one'), findsNothing);
      expect(done.isCompleted, isTrue);
    });

    testWidgets(
      'a step targeting an unattached key still renders, centered',
      (tester) async {
        final unattachedKey = GlobalKey();
        final anchorKey = GlobalKey();
        await pumpHarness(
          tester,
          anchorKey,
          (_) => [
            CoachMarkStep(
              targetKey: unattachedKey,
              title: 'Missing target',
              body: 'Should not crash',
            ),
          ],
        );

        await tester.tap(find.text('start tour'));
        await tester.pump();

        expect(find.text('Missing target'), findsOneWidget);
      },
    );
  });
}
