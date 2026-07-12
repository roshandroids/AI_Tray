import 'package:ai_tray/core/theme/app_theme.dart';
import 'package:ai_tray/core/theme/color_tokens.dart';
import 'package:ai_tray/core/theme/typography.dart';
import 'package:ai_tray/features/usage/presentation/widgets/tray_status_badge.dart';
import 'package:ai_tray/features/usage/presentation/widgets/tray_usage_meter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child, {required ThemeData theme}) {
    return MaterialApp(
      theme: theme,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: child,
        ),
      ),
    );
  }

  test('AppTheme attaches color and typography extensions', () {
    for (final theme in [AppTheme.light(), AppTheme.dark()]) {
      expect(theme.extension<TrayColorTokens>(), isNotNull);
      expect(theme.extension<TrayTypography>(), isNotNull);
    }
  });

  testWidgets('TrayUsageMeter shows percent and reset', (tester) async {
    await tester.pumpWidget(
      wrap(
        const TrayUsageMeter(
          label: 'Current session',
          percent: 24,
          resetsAtRaw: '10pm (America/Toronto)',
        ),
        theme: AppTheme.dark(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Current session'), findsOneWidget);
    expect(find.text('24% used'), findsOneWidget);
    expect(find.text('Resets 10pm (America/Toronto)'), findsOneWidget);
  });

  testWidgets('TrayStatusBadge shows Live label', (tester) async {
    await tester.pumpWidget(
      wrap(
        const TrayStatusBadge(kind: TrayStatusKind.live),
        theme: AppTheme.dark(),
      ),
    );
    expect(find.text('Live'), findsOneWidget);
  });
}
