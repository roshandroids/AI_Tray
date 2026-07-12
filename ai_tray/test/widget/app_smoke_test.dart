import 'package:ai_tray/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('foundation shell renders AI Tray title', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AiTrayApp(),
      ),
    );

    expect(find.text('AI Tray'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
