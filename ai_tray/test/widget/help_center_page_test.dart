import 'package:ai_tray/features/help/presentation/help_center_page.dart';
import 'package:ai_tray/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpPage(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark(), home: const HelpCenterPage()),
    );
  }

  testWidgets('renders every help topic by default', (tester) async {
    await pumpPage(tester);

    expect(find.text('Queue'), findsOneWidget);
    expect(find.text('Budget cap'), findsOneWidget);
    expect(find.text('Providers'), findsOneWidget);
    expect(find.text('Diagnostics'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Sessions'), findsOneWidget);
  });

  testWidgets('searching narrows the list to matching topics', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.enterText(
      find.byKey(const ValueKey('help-search-field')),
      'budget',
    );
    await tester.pump();

    expect(find.text('Budget cap'), findsOneWidget);
    expect(find.text('Queue'), findsNothing);
    expect(find.text('Diagnostics'), findsNothing);
  });

  testWidgets('a search with no matches shows an empty state', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.enterText(
      find.byKey(const ValueKey('help-search-field')),
      'nonexistent-topic',
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('help-empty')), findsOneWidget);
  });
}
