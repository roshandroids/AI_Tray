import 'package:ai_tray/core/theme/app_theme_mode.dart';
import 'package:ai_tray/theme/app_icons.dart';
import 'package:ai_tray/theme/font_presets.dart';
import 'package:ai_tray/theme/theme_presets.dart';
import 'package:meta/meta.dart';

/// Snapshot of all appearance personalization settings.
@immutable
final class PersonalizationState {
  const PersonalizationState({
    required this.themeMode,
    required this.themePreset,
    required this.fontPreset,
    required this.appIconPreset,
  });

  factory PersonalizationState.defaults() {
    return const PersonalizationState(
      themeMode: AppThemePreference.system,
      themePreset: ThemePreset.cursor,
      fontPreset: FontPreset.inter,
      appIconPreset: AppIconPresets.defaultIcon,
    );
  }

  final AppThemePreference themeMode;
  final ThemePreset themePreset;
  final FontPreset fontPreset;
  final AppIconPreset appIconPreset;

  PersonalizationState copyWith({
    AppThemePreference? themeMode,
    ThemePreset? themePreset,
    FontPreset? fontPreset,
    AppIconPreset? appIconPreset,
  }) {
    return PersonalizationState(
      themeMode: themeMode ?? this.themeMode,
      themePreset: themePreset ?? this.themePreset,
      fontPreset: fontPreset ?? this.fontPreset,
      appIconPreset: appIconPreset ?? this.appIconPreset,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PersonalizationState &&
        other.themeMode == themeMode &&
        other.themePreset == themePreset &&
        other.fontPreset == fontPreset &&
        other.appIconPreset == appIconPreset;
  }

  @override
  int get hashCode =>
      Object.hash(themeMode, themePreset, fontPreset, appIconPreset);
}
