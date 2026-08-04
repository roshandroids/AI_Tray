import 'package:ai_tray/core/components/metric_card.dart';
import 'package:ai_tray/core/components/progress_ring.dart';
import 'package:ai_tray/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child, {bool disableAnimations = false}) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(body: child),
      ),
    );
  }

  testWidgets('renders absolute, remaining, reset, and unlimited metrics', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const Column(
          children: [
            MetricCard(
              label: 'Premium requests',
              percent: 20,
              value: 20,
              total: 100,
              unit: 'requests',
              remainingPercent: 80,
              resetsAtRaw: '2026-08-01',
            ),
            MetricCard(
              label: 'Chat quota',
              percent: 0,
              unlimited: true,
            ),
          ],
        ),
      ),
    );

    expect(find.text('20 / 100 requests used'), findsOneWidget);
    expect(find.text('80 requests remaining · 80% remaining'), findsOneWidget);
    expect(find.text('Resets 2026-08-01'), findsOneWidget);
    expect(find.text('Unlimited'), findsOneWidget);
    expect(find.text('No usage limit'), findsOneWidget);
  });

  testWidgets('retains Claude percentage-only presentation', (tester) async {
    await tester.pumpWidget(
      wrap(
        const MetricCard(label: 'Session', percent: 24),
        disableAnimations: true,
      ),
    );

    expect(find.text('24% used'), findsOneWidget);
    expect(find.text('SESSION'), findsOneWidget);
  });

  testWidgets('renders unavailable ring and complete semantics', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const MetricCard(
          label: 'Usage',
          percent: 0,
          available: false,
        ),
      ),
    );

    expect(find.text('--'), findsOneWidget);
    expect(find.text('Usage unavailable'), findsOneWidget);

    // The ring's own semantics are asserted on a bare ring because a
    // MetricCard is a semantics container that merges the ring's node
    // with the card label.
    await tester.pumpWidget(
      wrap(const ProgressRing(percent: 0, available: false)),
    );

    expect(
      tester.getSemantics(find.byType(ProgressRing)),
      matchesSemantics(
        label: 'Usage unavailable',
        value: 'Unavailable',
        textDirection: TextDirection.ltr,
      ),
    );
  });

  testWidgets('refresh ring honors reduced motion', (tester) async {
    await tester.pumpWidget(
      wrap(
        const ProgressRing(percent: 42, refreshing: true),
        disableAnimations: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('42'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(ProgressRing)),
      matchesSemantics(
        label: 'Usage refreshing, 42 percent used',
        value: '42%',
        textDirection: TextDirection.ltr,
      ),
    );
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('refreshing ring uses info color band semantics', (tester) async {
    await tester.pumpWidget(
      wrap(const ProgressRing(percent: 18, refreshing: true)),
    );
    await tester.pump();

    expect(
      tester.getSemantics(find.byType(ProgressRing)),
      matchesSemantics(
        label: 'Usage refreshing, 18 percent used',
        value: '18%',
        textDirection: TextDirection.ltr,
      ),
    );
  });
}
