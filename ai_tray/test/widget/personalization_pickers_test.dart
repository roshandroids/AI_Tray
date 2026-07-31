import 'package:ai_tray/core/theme/app_theme_mode.dart';
import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/typography.dart';
import 'package:ai_tray/features/settings/presentation/widgets/app_icon_preset_picker.dart';
import 'package:ai_tray/features/settings/presentation/widgets/font_preset_picker.dart';
import 'package:ai_tray/features/settings/presentation/widgets/theme_mode_picker.dart';
import 'package:ai_tray/features/settings/presentation/widgets/theme_preset_picker.dart';
import 'package:ai_tray/theme/app_icons.dart';
import 'package:ai_tray/theme/app_theme.dart';
import 'package:ai_tray/theme/font_presets.dart';
import 'package:ai_tray/theme/theme_presets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.md),
          child: child,
        ),
      ),
    );
  }

  testWidgets('ThemeModePicker reports selection', (tester) async {
    AppThemePreference? selected;
    await tester.pumpWidget(
      wrap(
        ThemeModePicker(
          selected: AppThemePreference.system,
          onChanged: (v) => selected = v,
        ),
      ),
    );
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(selected, AppThemePreference.dark);
  });

  testWidgets('ThemePresetPicker expands and selects Nord', (tester) async {
    ThemePreset? selected;
    var expanded = true;
    await tester.pumpWidget(
      wrap(
        StatefulBuilder(
          builder: (context, setState) {
            return ThemePresetPicker(
              selected: selected ?? ThemePreset.cursor,
              expanded: expanded,
              onExpansionChanged: (value) => setState(() => expanded = value),
              onChanged: (v) => setState(() => selected = v),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nord'));
    await tester.pumpAndSettle();
    expect(selected, ThemePreset.nord);
  });

  testWidgets('FontPresetPicker expands and selects Geist', (tester) async {
    FontPreset? selected;
    await tester.pumpWidget(
      wrap(
        FontPresetPicker(
          selected: FontPreset.inter,
          expanded: true,
          onExpansionChanged: (_) {},
          onChanged: (v) => selected = v,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Geist'),
      80,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Geist'));
    await tester.pumpAndSettle();
    expect(selected, FontPreset.geist);
  });

  testWidgets('AppIconPresetPicker shows unsupported message when expanded', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        AppIconPresetPicker(
          selected: AppIconPresets.defaultIcon,
          isSupported: false,
          expanded: true,
          onExpansionChanged: (_) {},
          onChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppIconPresetPicker.unsupportedMessage), findsOneWidget);
    expect(find.text('Terminal'), findsOneWidget);
  });

  testWidgets('theme rebuild applies new font family', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        key: const ValueKey('inter'),
        theme: AppTheme.dark(font: FontPreset.inter),
        home: Builder(
          builder: (context) {
            return Text(
              'Preview',
              style: Theme.of(context).extension<TrayTypography>()!.body,
            );
          },
        ),
      ),
    );
    expect(
      tester.widget<Text>(find.text('Preview')).style?.fontFamily,
      'Inter',
    );

    await tester.pumpWidget(
      MaterialApp(
        key: const ValueKey('geist'),
        theme: AppTheme.dark(font: FontPreset.geist),
        home: Builder(
          builder: (context) {
            return Text(
              'Preview',
              style: Theme.of(context).extension<TrayTypography>()!.body,
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.text('Preview')).style?.fontFamily,
      'Geist',
    );
  });

  testWidgets('switching light theme rebuilds scaffold background', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(preset: ThemePreset.gruvbox),
        darkTheme: AppTheme.dark(preset: ThemePreset.gruvbox),
        themeMode: ThemeMode.light,
        home: const Scaffold(body: Text('Body')),
      ),
    );
    final scaffold = tester.widget<Material>(
      find
          .descendant(
            of: find.byType(Scaffold),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(scaffold.color?.toARGB32(), 0xFFFBF1C7);
  });
}
