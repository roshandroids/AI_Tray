import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Catalog entry for a selectable application icon.
@immutable
final class AppIconPreset {
  const AppIconPreset({
    required this.id,
    required this.displayName,
    required this.description,
    required this.assetPath,
    required this.previewAssetPath,
  });

  final String id;
  final String displayName;
  final String description;

  /// Asset used when a platform adapter can apply the icon.
  final String assetPath;

  /// Asset shown in Settings previews.
  final String previewAssetPath;

  String get storageValue => id;

  @override
  bool operator ==(Object other) => other is AppIconPreset && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Built-in application icon presets.
abstract final class AppIconPresets {
  static const AppIconPreset defaultIcon = AppIconPreset(
    id: 'default',
    displayName: 'Default',
    description: 'Standard AI Tray mark.',
    assetPath: 'assets/app_icons/icon_default.png',
    previewAssetPath: 'assets/app_icons/icon_default.png',
  );

  static const AppIconPreset terminal = AppIconPreset(
    id: 'terminal',
    displayName: 'Terminal',
    description: 'Command-line inspired glyph.',
    assetPath: 'assets/app_icons/icon_terminal.png',
    previewAssetPath: 'assets/app_icons/icon_terminal.png',
  );

  static const AppIconPreset ai = AppIconPreset(
    id: 'ai',
    displayName: 'AI',
    description: 'Abstract AI accent mark.',
    assetPath: 'assets/app_icons/icon_ai.png',
    previewAssetPath: 'assets/app_icons/icon_ai.png',
  );

  static const AppIconPreset minimal = AppIconPreset(
    id: 'minimal',
    displayName: 'Minimal',
    description: 'Quiet single-dot mark.',
    assetPath: 'assets/app_icons/icon_minimal.png',
    previewAssetPath: 'assets/app_icons/icon_minimal.png',
  );

  static const AppIconPreset dark = AppIconPreset(
    id: 'dark',
    displayName: 'Dark',
    description: 'Dark chrome variant.',
    assetPath: 'assets/app_icons/icon_dark.png',
    previewAssetPath: 'assets/app_icons/icon_dark.png',
  );

  static const AppIconPreset light = AppIconPreset(
    id: 'light',
    displayName: 'Light',
    description: 'Light chrome variant.',
    assetPath: 'assets/app_icons/icon_light.png',
    previewAssetPath: 'assets/app_icons/icon_light.png',
  );

  static const List<AppIconPreset> all = [
    defaultIcon,
    terminal,
    ai,
    minimal,
    dark,
    light,
  ];

  static AppIconPreset get defaultPreset => defaultIcon;

  static AppIconPreset fromStorage(String? value) {
    if (value == null || value.isEmpty) return defaultPreset;
    return all.firstWhere(
      (p) => p.id == value,
      orElse: () => defaultPreset,
    );
  }
}

/// Platform port for runtime application icon switching.
abstract interface class AppIconSwitcher {
  /// Whether the current platform can change the dock/taskbar icon at runtime.
  bool get isSupported;

  /// Applies [preset] when supported; otherwise a no-op.
  Future<void> setIcon(AppIconPreset preset);
}

/// Default desktop implementation — runtime icon switching is unsupported.
final class UnsupportedAppIconSwitcher implements AppIconSwitcher {
  const UnsupportedAppIconSwitcher();

  @override
  bool get isSupported => false;

  @override
  Future<void> setIcon(AppIconPreset preset) async {
    // Persisted by PersonalizationController; adapters can apply later.
    assert(
      () {
        debugPrint(
          'AppIconSwitcher: ignoring "${preset.id}" '
          '(runtime icon switching unsupported on this platform).',
        );
        return true;
      }(),
      'debug-only log',
    );
  }
}

/// Injectable switcher; override in tests or future platform adapters.
final appIconSwitcherProvider = Provider<AppIconSwitcher>((ref) {
  return const UnsupportedAppIconSwitcher();
});
