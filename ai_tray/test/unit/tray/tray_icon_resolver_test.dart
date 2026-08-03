import 'dart:io';

import 'package:ai_tray/core/components/status_badge.dart';
import 'package:ai_tray/features/tray/domain/tray_display_mode.dart';
import 'package:ai_tray/features/tray/presentation/tray_icon_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TrayIconResolver', () {
    test('macOS menu bar uses dedicated template asset', () {
      expect(
        TrayIconResolver.macOsMenuBarTemplate,
        'assets/tray/tray_menubar_template.png',
      );
      expect(
        TrayIconResolver.macOsMenuBarTemplateDim,
        'assets/tray/tray_menubar_template_dim.png',
      );
      expect(
        TrayIconResolver.macOsMenuBarTemplate,
        isNot(TrayIconResolver.windowsAsset),
      );
    });

    test('template PNG assets exist on disk', () {
      final root = Directory.current.path.endsWith('ai_tray')
          ? Directory.current.path
          : '${Directory.current.path}/ai_tray';
      for (final relative in [
        TrayIconResolver.macOsMenuBarTemplate,
        TrayIconResolver.macOsMenuBarTemplateDim,
        'assets/tray/tray_menubar_template_16.png',
        'assets/tray/tray_menubar_template_18.png',
        TrayIconResolver.macOsMenuBarTemplate36,
      ]) {
        final file = File('$root/$relative');
        expect(file.existsSync(), isTrue, reason: relative);
      }
    });

    test('status assets remain available for legacy/fallback', () {
      for (final kind in TrayStatusKind.values) {
        expect(TrayIconResolver.macOsStatusAsset(kind), contains('tray_icon_'));
        expect(TrayIconResolver.macOsAsset(kind), contains('tray_icon_'));
      }
    });

    test('iconOnly never shows a title', () {
      expect(
        TrayIconResolver.macOsTitle(
          mode: TrayDisplayMode.iconOnly,
          threshold: 90,
          kind: TrayStatusKind.live,
          sessionPercent: 95,
        ),
        isEmpty,
      );
    });

    test('alwaysPercent shows percent when available', () {
      expect(
        TrayIconResolver.macOsTitle(
          mode: TrayDisplayMode.alwaysPercent,
          threshold: 90,
          kind: TrayStatusKind.live,
          sessionPercent: 42,
        ),
        '42%',
      );
      expect(
        TrayIconResolver.macOsTitle(
          mode: TrayDisplayMode.alwaysPercent,
          threshold: 90,
          kind: TrayStatusKind.live,
          sessionPercent: null,
        ),
        isEmpty,
      );
    });

    test('adaptive reveals only at threshold or attention states', () {
      expect(
        TrayIconResolver.macOsTitle(
          mode: TrayDisplayMode.adaptive,
          threshold: 90,
          kind: TrayStatusKind.live,
          sessionPercent: 76,
        ),
        isEmpty,
      );
      expect(
        TrayIconResolver.macOsTitle(
          mode: TrayDisplayMode.adaptive,
          threshold: 90,
          kind: TrayStatusKind.live,
          sessionPercent: 93,
        ),
        '93%',
      );
      expect(
        TrayIconResolver.macOsTitle(
          mode: TrayDisplayMode.adaptive,
          threshold: 90,
          kind: TrayStatusKind.refreshing,
          sessionPercent: 12,
        ),
        '12%',
      );
      expect(
        TrayIconResolver.macOsTitle(
          mode: TrayDisplayMode.adaptive,
          threshold: 90,
          kind: TrayStatusKind.error,
          sessionPercent: null,
        ),
        isEmpty,
      );
    });

    test('titles never include emoji', () {
      final title = TrayIconResolver.macOsTitle(
        mode: TrayDisplayMode.alwaysPercent,
        threshold: 90,
        kind: TrayStatusKind.live,
        sessionPercent: 10,
      );
      expect(title, '10%');
      expect(title.contains(RegExp(r'[^\x00-\x7F]')), isFalse);
    });
  });
}
