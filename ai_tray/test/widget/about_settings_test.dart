import 'package:ai_tray/features/about/presentation/about_page.dart';
import 'package:ai_tray/features/settings/domain/models/release_history.dart';
import 'package:ai_tray/features/settings/release_history_providers.dart';
import 'package:ai_tray/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  testWidgets('About shows live version and What’s New from history', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1100, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final packageInfo = PackageInfo(
      appName: 'AI Tray',
      packageName: 'ai_tray',
      version: '1.3.3',
      buildNumber: '9',
    );
    const history = ReleaseHistory(
      schemaVersion: 1,
      generatedFrom: 'CHANGELOG.md',
      releases: [
        ReleaseEntry(
          version: '1.3.3',
          date: '2026-07-17',
          notesMarkdown: '### Fixed\n- Optional session reset suffix.',
        ),
        ReleaseEntry(
          version: '1.3.2',
          date: '2026-07-17',
          notesMarkdown: '### Fixed\n- Sidecar payload pin.',
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          packageInfoProvider.overrideWith((ref) async => packageInfo),
          releaseHistoryProvider.overrideWith((ref) async => history),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const AboutPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1.3.3'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
    expect(find.text('2026-07-17'), findsWidgets);
    expect(
      find.textContaining('Optional session reset suffix'),
      findsOneWidget,
    );
    expect(find.text('Previous releases'), findsOneWidget);
  });
}
