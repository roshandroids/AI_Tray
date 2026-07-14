import 'dart:io';
import 'dart:ui' as ui;

import 'package:ai_tray/core/components/log_chip.dart';
import 'package:ai_tray/core/components/metric_card.dart';
import 'package:ai_tray/core/components/section_chrome.dart';
import 'package:ai_tray/core/components/settings_chrome.dart';
import 'package:ai_tray/core/components/status_badge.dart';
import 'package:ai_tray/core/logging/log_level.dart';
import 'package:ai_tray/core/theme/app_theme.dart';
import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:ai_tray/features/tray/presentation/tray_ring_icon_renderer.dart';
import 'package:ai_tray/features/usage/presentation/widgets/tray_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Generates README screenshots under docs/assets/screenshots/.
///
/// Run:
///   flutter test test/screenshot/readme_screenshots_test.dart --tags screenshot
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory outDir;

  setUpAll(() async {
    await _loadFonts();
    outDir = Directory(
      '${Directory.current.path}/../docs/assets/screenshots',
    );
    if (!outDir.existsSync()) {
      outDir.createSync(recursive: true);
    }
  });

  testWidgets('capture dashboard dark', (tester) async {
    await _capture(
      tester,
      size: const Size(880, 640),
      theme: AppTheme.dark(),
      path: '${outDir.path}/dashboard-dark.png',
      child: const _DashboardPreview(),
    );
  }, tags: ['screenshot']);

  testWidgets('capture dashboard light', (tester) async {
    await _capture(
      tester,
      size: const Size(880, 640),
      theme: AppTheme.light(),
      path: '${outDir.path}/dashboard-light.png',
      child: const _DashboardPreview(),
    );
  }, tags: ['screenshot']);

  testWidgets('capture settings dark', (tester) async {
    await _capture(
      tester,
      size: const Size(880, 560),
      theme: AppTheme.dark(),
      path: '${outDir.path}/settings-dark.png',
      child: const _SettingsPreview(),
    );
  }, tags: ['screenshot']);

  testWidgets('capture diagnostics dark', (tester) async {
    await _capture(
      tester,
      size: const Size(880, 560),
      theme: AppTheme.dark(),
      path: '${outDir.path}/diagnostics-dark.png',
      child: const _DiagnosticsPreview(),
    );
  }, tags: ['screenshot']);

  testWidgets('capture logs dark', (tester) async {
    await _capture(
      tester,
      size: const Size(880, 520),
      theme: AppTheme.dark(),
      path: '${outDir.path}/logs-dark.png',
      child: const _LogsPreview(),
    );
  }, tags: ['screenshot']);

  test('capture tray ring variants', () async {
    final sizes = <String, (TrayStatusKind, double?)>{
      'tray-live.png': (TrayStatusKind.live, 58),
      'tray-cached.png': (TrayStatusKind.cached, 72),
      'tray-refreshing.png': (TrayStatusKind.refreshing, 41),
      'tray-error.png': (TrayStatusKind.error, 96),
    };

    for (final entry in sizes.entries) {
      final path = await TrayRingIconRenderer.render(
        kind: entry.value.$1,
        sessionPercent: entry.value.$2,
      );
      final dest = File('${outDir.path}/${entry.key}');
      await File(path).copy(dest.path);
    }

    await _composeTrayStrip(
      [
        '${outDir.path}/tray-live.png',
        '${outDir.path}/tray-cached.png',
        '${outDir.path}/tray-refreshing.png',
        '${outDir.path}/tray-error.png',
      ],
      '${outDir.path}/tray-rings.png',
    );
  }, tags: ['screenshot']);
}

Future<void> _loadFonts() async {
  final jetbrains = FontLoader('JetBrainsMono')
    ..addFont(rootBundle.load('assets/fonts/JetBrainsMono-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/JetBrainsMono-Medium.ttf'))
    ..addFont(rootBundle.load('assets/fonts/JetBrainsMono-SemiBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/JetBrainsMono-Bold.ttf'));
  await jetbrains.load();
}

Future<void> _capture(
  WidgetTester tester, {
  required Size size,
  required ThemeData theme,
  required String path,
  required Widget child,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: Scaffold(
        body: RepaintBoundary(
          child: ColoredBox(
            color: theme.scaffoldBackgroundColor,
            child: child,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 100));

  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byType(RepaintBoundary).first,
  );

  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File(path).writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
  });
}

Future<void> _composeTrayStrip(List<String> sources, String dest) async {
  const cell = 88.0;
  const gap = 24.0;
  final width = (cell * sources.length) + (gap * (sources.length + 1));
  const height = cell + gap * 2;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final bg = Paint()..color = const Color(0xFF0D1117);
  canvas.drawRect(Rect.fromLTWH(0, 0, width, height), bg);

  for (var i = 0; i < sources.length; i++) {
    final bytes = await File(sources[i]).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final x = gap + i * (cell + gap);
    const y = gap;
    paintImage(
      canvas: canvas,
      rect: Rect.fromLTWH(x, y, cell, cell),
      image: image,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }

  final picture = recorder.endRecording();
  final image = await picture.toImage(width.round(), height.round());
  final out = await image.toByteData(format: ui.ImageByteFormat.png);
  await File(dest).writeAsBytes(out!.buffer.asUint8List(), flush: true);
}

final class _DashboardPreview extends StatelessWidget {
  const _DashboardPreview();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('AI Tray', style: context.typography.title),
              const Spacer(),
              const StatusBadge(kind: TrayStatusKind.live, compact: true),
            ],
          ),
          const SizedBox(height: Spacing.md),
          const Row(
            children: [
              Expanded(
                child: MetricCard(
                  label: 'Session',
                  percent: 58,
                  resetsAtRaw: 'at 4:00 AM',
                  sparklineValues: [20, 28, 34, 40, 48, 52, 58],
                ),
              ),
              SizedBox(width: Spacing.md),
              Expanded(
                child: MetricCard(
                  label: 'Week',
                  percent: 31,
                  resetsAtRaw: 'Sat 7am',
                  sparklineValues: [12, 15, 18, 22, 24, 28, 31],
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          const Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: TerminalPanel(
                    title: 'Status',
                    child: Column(
                      children: [
                        InfoRow(label: 'Status', value: '● Live'),
                        InfoRow(label: 'Source', value: 'Claude CLI'),
                        InfoRow(label: 'Updated', value: 'just now'),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: Spacing.md),
                Expanded(
                  child: TerminalPanel(
                    title: 'CLI Health',
                    child: Column(
                      children: [
                        InfoRow(label: 'Auth', value: '✓ OK'),
                        InfoRow(label: 'CLI', value: '✓ OK'),
                        InfoRow(label: 'Parser', value: '✓ OK'),
                        InfoRow(label: 'Cache', value: '✓ live'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            '⌘R Refresh   ⌘L Logs   ⌘, Settings',
            style: context.typography.caption,
          ),
        ],
      ),
    );
  }
}

final class _SettingsPreview extends StatelessWidget {
  const _SettingsPreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.md,
            Spacing.md,
            Spacing.md,
            0,
          ),
          child: Text('Settings', style: context.typography.title),
        ),
        const SizedBox(height: Spacing.md),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SettingsNavRail(
                selected: SettingsSection.appearance,
                onSelect: (_) {},
              ),
              ColoredBox(
                color: context.colors.border,
                child: const SizedBox(width: 1),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.md),
                  child: SettingsGroup(
                    title: 'Appearance',
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Theme', style: context.typography.label),
                          const SizedBox(height: Spacing.sm),
                          const Wrap(
                            spacing: Spacing.sm,
                            children: [
                              _ThemeChip(label: 'System', selected: false),
                              _ThemeChip(label: 'Dark', selected: true),
                              _ThemeChip(label: 'Light', selected: false),
                            ],
                          ),
                          const SizedBox(height: Spacing.md),
                          Text('Accent', style: context.typography.label),
                          const SizedBox(height: Spacing.sm),
                          Row(
                            children: [
                              for (final c in [
                                context.colors.success,
                                context.colors.purpleAccent,
                                context.colors.info,
                                context.colors.cyanAccent,
                              ])
                                Padding(
                                  padding: const EdgeInsets.only(
                                    right: Spacing.sm,
                                  ),
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: c,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: context.colors.border,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final class _ThemeChip extends StatelessWidget {
  const _ThemeChip({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected
            ? context.colors.success.withValues(alpha: 0.12)
            : context.colors.surfaceAlt,
        borderRadius: BorderRadius.circular(RadiusTokens.sm),
        border: Border.all(
          color: selected ? context.colors.success : context.colors.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        child: Text(
          label,
          style: context.typography.caption.copyWith(
            color: selected
                ? context.colors.success
                : context.colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

final class _DiagnosticsPreview extends StatelessWidget {
  const _DiagnosticsPreview();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Diagnostics', style: context.typography.title),
              const Spacer(),
              const StatusBadge(kind: TrayStatusKind.live, compact: true),
            ],
          ),
          const SizedBox(height: Spacing.md),
          const Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: TerminalPanel(
                    title: 'Application',
                    child: Column(
                      children: [
                        InfoRow(label: 'App version', value: '1.2.0+5'),
                        InfoRow(label: 'Theme', value: 'Dark'),
                        InfoRow(label: 'Platform', value: 'macOS'),
                        InfoRow(label: 'Provider', value: 'Claude CLI'),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: Spacing.md),
                Expanded(
                  child: TerminalPanel(
                    title: 'Refresh',
                    child: Column(
                      children: [
                        InfoRow(label: 'Mode', value: 'Auto'),
                        InfoRow(label: 'Interval', value: '60s'),
                        InfoRow(label: 'Phase', value: 'idle'),
                        InfoRow(label: 'Last success', value: 'just now'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _LogsPreview extends StatelessWidget {
  const _LogsPreview();

  @override
  Widget build(BuildContext context) {
    final rows = <(String, LogLevel, String, String)>[
      ('21:04:12', LogLevel.info, 'refresh', 'refresh success durationMs=412'),
      ('21:04:11', LogLevel.success, 'parser', 'Shape A matched session+week'),
      ('21:03:58', LogLevel.warning, 'cache', 'served LKG after soft failure'),
      (
        '21:03:40',
        LogLevel.error,
        'cli',
        'exit 1 — check `claude auth status`',
      ),
      ('21:03:12', LogLevel.debug, 'tray', 'ring icon updated session=58'),
    ];

    return Padding(
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Logs', style: context.typography.title),
          const SizedBox(height: Spacing.md),
          DecoratedBox(
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(RadiusTokens.md),
              border: Border.all(color: context.colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    size: 16,
                    color: context.colors.textMuted,
                  ),
                  const SizedBox(width: Spacing.sm),
                  Text(
                    'Search logs…',
                    style: context.typography.body.copyWith(
                      color: context.colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Spacing.sm),
          const SectionDivider(),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: Row(
                children: [
                  SizedBox(
                    width: 72,
                    child: Text(row.$1, style: context.typography.caption),
                  ),
                  LogChip(level: row.$2),
                  const SizedBox(width: Spacing.sm),
                  SizedBox(
                    width: 72,
                    child: Text(row.$3, style: context.typography.label),
                  ),
                  Expanded(
                    child: Text(
                      row.$4,
                      style: context.typography.terminalOutput,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
