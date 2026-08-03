import 'package:ai_tray/core/components/metric_card.dart';
import 'package:ai_tray/core/components/section_chrome.dart';
import 'package:ai_tray/core/components/status_badge.dart';
import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:ai_tray/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _loadFonts() async {
  final jetbrains = FontLoader('JetBrainsMono')
    ..addFont(rootBundle.load('assets/fonts/JetBrainsMono-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/JetBrainsMono-Medium.ttf'))
    ..addFont(rootBundle.load('assets/fonts/JetBrainsMono-SemiBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/JetBrainsMono-Bold.ttf'));
  await jetbrains.load();
}

Widget _providerPreview({
  required ThemeData theme,
  required String providerName,
  required bool experimental,
  required List<Widget> cards,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: theme,
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('AI Tray', style: theme.textTheme.titleMedium),
                const Spacer(),
                const StatusBadge(kind: TrayStatusKind.live, compact: true),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            DecoratedBox(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(RadiusTokens.md),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(Spacing.sm),
                child: Row(
                  children: [
                    Text(providerName, style: theme.textTheme.titleSmall),
                    if (experimental) ...[
                      const SizedBox(width: Spacing.sm),
                      Builder(
                        builder: (context) {
                          final color = context.colors.warning;
                          return DecoratedBox(
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(
                                RadiusTokens.sm,
                              ),
                              border: Border.all(
                                color: color.withValues(alpha: 0.45),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Spacing.sm,
                                vertical: 2,
                              ),
                              child: Text(
                                'EXPERIMENTAL',
                                style: context.typography.caption.copyWith(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                    const Spacer(),
                    Text(
                      'Last refreshed just now',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Spacing.md),
            ...cards,
            const SizedBox(height: Spacing.md),
            const SectionCard(
              title: 'Status',
              child: Column(
                children: [
                  InfoRow(label: 'Status', value: '● Live'),
                  InfoRow(label: 'Updated', value: 'just now'),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// EP-002 Phase 3 provider UI golden snapshots.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ep002 Claude dashboard dark golden', (tester) async {
    await _loadFonts();
    await tester.binding.setSurfaceSize(const Size(880, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _providerPreview(
        theme: AppTheme.dark(),
        providerName: 'Claude',
        experimental: false,
        cards: const [
          MetricCard(
            label: 'Session',
            percent: 24,
            resetsAtRaw: '10pm',
            sparklineValues: [10, 14, 18, 20, 22, 23, 24],
          ),
          SizedBox(height: Spacing.sm),
          MetricCard(
            label: 'Week',
            percent: 11,
            resetsAtRaw: 'Sat 7am',
            sparklineValues: [4, 5, 6, 7, 8, 10, 11],
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/ep002_claude_dashboard_dark.png'),
    );
  }, tags: ['golden']);

  testWidgets('ep002 Copilot dashboard dark golden', (tester) async {
    await _loadFonts();
    await tester.binding.setSurfaceSize(const Size(880, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _providerPreview(
        theme: AppTheme.dark(),
        providerName: 'GitHub Copilot',
        experimental: true,
        cards: const [
          MetricCard(
            label: 'Premium requests',
            percent: 11.3,
            value: 34,
            total: 300,
            unit: 'requests',
            remainingPercent: 88.7,
            resetsAtRaw: 'Jul 25',
          ),
          SizedBox(height: Spacing.sm),
          MetricCard(
            label: 'Chat quota',
            percent: 0,
            unlimited: true,
            unit: 'requests',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/ep002_copilot_dashboard_dark.png'),
    );
  }, tags: ['golden']);

  testWidgets('ep002 Copilot dashboard light golden', (tester) async {
    await _loadFonts();
    await tester.binding.setSurfaceSize(const Size(880, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _providerPreview(
        theme: AppTheme.light(),
        providerName: 'GitHub Copilot',
        experimental: true,
        cards: const [
          MetricCard(
            label: 'Premium requests',
            percent: 11.3,
            value: 34,
            total: 300,
            unit: 'requests',
            remainingPercent: 88.7,
            resetsAtRaw: 'Jul 25',
          ),
          SizedBox(height: Spacing.sm),
          MetricCard(
            label: 'Chat quota',
            percent: 0,
            unlimited: true,
            unit: 'requests',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/ep002_copilot_dashboard_light.png'),
    );
  }, tags: ['golden']);

  testWidgets('ep002 Copilot settings/diagnostics/logs dark golden', (
    tester,
  ) async {
    await _loadFonts();
    await tester.binding.setSurfaceSize(const Size(880, 560));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Builder(
                  builder: (context) {
                    return Text(
                      'GitHub Copilot',
                      style: context.typography.title,
                    );
                  },
                ),
                const SizedBox(height: Spacing.md),
                const Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: SectionCard(
                          title: 'Settings',
                          child: Column(
                            children: [
                              InfoRow(label: 'Enabled', value: 'Yes'),
                              InfoRow(label: 'SDK', value: '0.1.x'),
                              InfoRow(label: 'Auth', value: 'Signed in'),
                              InfoRow(label: 'Refresh', value: '60s'),
                              InfoRow(
                                label: 'API',
                                value: 'Experimental',
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: Spacing.md),
                      Expanded(
                        child: SectionCard(
                          title: 'Diagnostics',
                          child: Column(
                            children: [
                              InfoRow(label: 'SDK Installed', value: 'Yes'),
                              InfoRow(label: 'CLI Version', value: '1.x'),
                              InfoRow(label: 'Quota RPC', value: 'OK'),
                              InfoRow(label: 'Health', value: 'Healthy'),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: Spacing.md),
                      Expanded(
                        child: SectionCard(
                          title: 'Logs',
                          child: Column(
                            children: [
                              InfoRow(label: 'Filter', value: 'Copilot'),
                              InfoRow(
                                label: 'Latest',
                                value: 'quota refresh ok',
                              ),
                              InfoRow(label: 'Severity', value: 'INFO'),
                            ],
                          ),
                        ),
                      ),
                    ],
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
      matchesGoldenFile('goldens/ep002_copilot_surfaces_dark.png'),
    );
  }, tags: ['golden']);
}
