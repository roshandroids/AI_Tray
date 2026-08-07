import 'package:ai_tray/core/components/resizable_panel.dart';
import 'package:ai_tray/features/layout/domain/models/panel_layout_state.dart';
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

  testWidgets('starts collapsed by default, body not built', (tester) async {
    var builderCalls = 0;
    await tester.pumpWidget(
      wrap(
        ResizablePanel(
          panelId: 'test.panel',
          title: 'Test panel',
          onStateChanged: (_) {},
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

  testWidgets('respects a persisted initial state', (tester) async {
    await tester.pumpWidget(
      wrap(
        ResizablePanel(
          panelId: 'test.panel',
          title: 'Test panel',
          initialState: const PanelLayoutState(heightPx: 200, isExpanded: true),
          onStateChanged: (_) {},
          bodyBuilder: (context) => const Text('Body content'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Body content'), findsOneWidget);
  });

  testWidgets('tapping the header toggles expansion and persists it', (
    tester,
  ) async {
    PanelLayoutState? lastState;
    await tester.pumpWidget(
      wrap(
        ResizablePanel(
          panelId: 'test.panel',
          title: 'Test panel',
          onStateChanged: (state) => lastState = state,
          bodyBuilder: (context) => const Text('Body content'),
        ),
      ),
    );

    await tester.tap(find.text('TEST PANEL'));
    await tester.pumpAndSettle();

    expect(find.text('Body content'), findsOneWidget);
    expect(lastState?.isExpanded, isTrue);
  });
}
