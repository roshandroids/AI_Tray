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

  testWidgets('ThemePresetPicker selects Nord', (tester) async {
    ThemePreset? selected;
    await tester.pumpWidget(
      wrap(
        ThemePresetPicker(
          selected: ThemePreset.cursor,
          onChanged: (v) => selected = v,
        ),
      ),
    );
    await tester.tap(find.text('Nord'));
    await tester.pumpAndSettle();
    expect(selected, ThemePreset.nord);
  });

  testWidgets('FontPresetPicker selects Geist', (tester) async {
    FontPreset? selected;
    await tester.pumpWidget(
      wrap(
        FontPresetPicker(
          selected: FontPreset.inter,
          onChanged: (v) => selected = v,
        ),
      ),
    );
    await tester.tap(find.text('Geist'));
    await tester.pumpAndSettle();
    expect(selected, FontPreset.geist);
  });

  testWidgets('AppIconPresetPicker shows unsupported message', (tester) async {
    await tester.pumpWidget(
      wrap(
        AppIconPresetPicker(
          selected: AppIconPresets.defaultIcon,
          isSupported: false,
          onChanged: (_) {},
        ),
      ),
    );
    expect(
      find.text(AppIconPresetPicker.unsupportedMessage),
      findsOneWidget,
    );
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
}
