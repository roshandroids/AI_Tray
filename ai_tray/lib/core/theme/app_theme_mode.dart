import 'package:flutter/material.dart';

/// User-facing theme preference (PD-014).
enum AppThemePreference {
  system,
  light,
  dark;

  ThemeMode get materialThemeMode => switch (this) {
        AppThemePreference.system => ThemeMode.system,
        AppThemePreference.light => ThemeMode.light,
        AppThemePreference.dark => ThemeMode.dark,
      };

  static AppThemePreference fromStorage(String? value) => switch (value) {
        'light' => AppThemePreference.light,
        'dark' => AppThemePreference.dark,
        _ => AppThemePreference.system,
      };

  String get storageValue => name;
}
