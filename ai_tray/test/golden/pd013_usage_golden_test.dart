import 'package:ai_tray/core/theme/app_theme.dart';
import 'package:ai_tray/features/usage/presentation/widgets/tray_status_badge.dart';
import 'package:ai_tray/features/usage/presentation/widgets/tray_usage_meter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _loadPlex() async {
  final loader = FontLoader('IBMPlexMono')
    ..addFont(rootBundle.load('assets/fonts/IBMPlexMono-Regular.otf'))
    ..addFont(rootBundle.load('assets/fonts/IBMPlexMono-Medium.otf'))
    ..addFont(rootBundle.load('assets/fonts/IBMPlexMono-SemiBold.otf'));
  await loader.load();
}

/// Visual snapshot for PD-013 review (update with `--update-goldens`).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('pd013 usage composition golden', (tester) async {
    await _loadPlex();
    await tester.binding.setSurfaceSize(const Size(420, 560));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final theme = AppTheme.dark();

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: Scaffold(
          appBar: AppBar(
            title: const Text('AI Tray'),
            actions: const [
              Icon(Icons.settings_outlined),
              SizedBox(width: 8),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const TrayUsageMeter(
                  label: 'Current session',
                  percent: 24,
                  resetsAtRaw: '10pm (America/Toronto)',
                ),
                const SizedBox(height: 24),
                ColoredBox(
                  color: theme.dividerColor,
                  child: const SizedBox(height: 1, width: double.infinity),
                ),
                const SizedBox(height: 24),
                const TrayUsageMeter(
                  label: 'Current week (all models)',
                  percent: 11,
                  resetsAtRaw: 'Sat 7am (America/Toronto)',
                ),
                const SizedBox(height: 24),
                ColoredBox(
                  color: theme.dividerColor,
                  child: const SizedBox(height: 1, width: double.infinity),
                ),
                const SizedBox(height: 24),
                const TrayStatusBadge(kind: TrayStatusKind.live),
                const Spacer(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton(
                    onPressed: () {},
                    child: const Text('Refresh'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/pd013_after.png'),
    );
  });
}
