import 'package:ai_tray/core/components/tray_accordion.dart';
import 'package:ai_tray/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(body: child),
    );
  }

  testWidgets('collapsed body is not built', (tester) async {
    var builderCalls = 0;
    await tester.pumpWidget(
      wrap(
        TrayAccordion(
          title: 'Panel',
          isExpanded: false,
          onExpandedChanged: (_) {},
          bodyBuilder: (context) {
            builderCalls++;
            return const Text('Body content');
          },
        ),
      ),
    );
    expect(builderCalls, 0);
    expect(find.text('Body content'), findsNothing);
  });

  testWidgets('tapping header toggles expansion', (tester) async {
    var expanded = false;
    await tester.pumpWidget(
      wrap(
        StatefulBuilder(
          builder: (context, setState) {
            return TrayAccordion(
              title: 'Panel',
              isExpanded: expanded,
              onExpandedChanged: (value) => setState(() => expanded = value),
              bodyBuilder: (context) => const Text('Body content'),
            );
          },
        ),
      ),
    );
    expect(find.text('Body content'), findsNothing);

    await tester.tap(find.text('Panel'));
    await tester.pumpAndSettle();
    expect(find.text('Body content'), findsOneWidget);

    await tester.tap(find.text('Panel'));
    await tester.pumpAndSettle();
    expect(find.text('Body content'), findsNothing);
  });

  testWidgets('sectionLabel header style uppercases the title', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        TrayAccordion(
          title: 'Advanced',
          headerStyle: AccordionHeaderStyle.sectionLabel,
          isExpanded: false,
          onExpandedChanged: (_) {},
          bodyBuilder: (context) => const SizedBox(),
        ),
      ),
    );
    expect(find.text('ADVANCED'), findsOneWidget);
    expect(find.text('Advanced'), findsNothing);
  });
}
