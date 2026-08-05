import 'package:ai_tray/core/theme/app_theme_mode.dart';
import 'package:ai_tray/features/providers/domain/models/provider_id.dart';
import 'package:ai_tray/features/tray/domain/tray_display_mode.dart';
import 'package:ai_tray/theme/app_icons.dart';
import 'package:ai_tray/theme/font_presets.dart';
import 'package:ai_tray/theme/theme_presets.dart';
import 'package:meta/meta.dart';

/// User-configurable MVP preferences.
@immutable
final class AppSettings {
  factory AppSettings({
    required bool autoRefreshEnabled,
    required Duration refreshInterval,
    required bool notificationsEnabled,
    required bool launchAtLogin,
    required bool showStaleIndicator,
    double? notifyAtSessionPercent,
    String? claudeBinaryPath,
    ProviderId selectedProviderId = ProviderId.claude,
    AppThemePreference themeMode = AppThemePreference.system,
    ThemePreset themePreset = ThemePresetX.defaultPreset,
    FontPreset fontPreset = FontPresetX.defaultPreset,
    AppIconPreset appIconPreset = AppIconPresets.defaultIcon,
    bool copilotEnabled = true,
    TrayDisplayMode trayDisplayMode = TrayDisplayModeX.defaultMode,
    double trayPercentThreshold = defaultTrayPercentThreshold,
    bool hasCompletedOnboarding = false,
  }) {
    _validateRefreshInterval(refreshInterval);
    final threshold = notifyAtSessionPercent;
    if (threshold != null) {
      _requirePercent(threshold, 'notifyAtSessionPercent');
    }
    _requirePercent(trayPercentThreshold, 'trayPercentThreshold');
    final path = claudeBinaryPath?.trim();
    return AppSettings._(
      autoRefreshEnabled: autoRefreshEnabled,
      refreshInterval: refreshInterval,
      notificationsEnabled: notificationsEnabled,
      notifyAtSessionPercent: threshold,
      launchAtLogin: launchAtLogin,
      claudeBinaryPath: (path == null || path.isEmpty) ? null : path,
      selectedProviderId: selectedProviderId,
      showStaleIndicator: showStaleIndicator,
      themeMode: themeMode,
      themePreset: themePreset,
      fontPreset: fontPreset,
      appIconPreset: appIconPreset,
      copilotEnabled: copilotEnabled,
      trayDisplayMode: trayDisplayMode,
      trayPercentThreshold: trayPercentThreshold,
      hasCompletedOnboarding: hasCompletedOnboarding,
    );
  }

  const AppSettings._({
    required this.autoRefreshEnabled,
    required this.refreshInterval,
    required this.notificationsEnabled,
    required this.notifyAtSessionPercent,
    required this.launchAtLogin,
    required this.claudeBinaryPath,
    required this.selectedProviderId,
    required this.showStaleIndicator,
    required this.themeMode,
    required this.themePreset,
    required this.fontPreset,
    required this.appIconPreset,
    required this.copilotEnabled,
    required this.trayDisplayMode,
    required this.trayPercentThreshold,
    required this.hasCompletedOnboarding,
  });

  /// MVP defaults aligned with planning (60s auto-refresh).
  factory AppSettings.defaults() {
    return AppSettings(
      autoRefreshEnabled: true,
      refreshInterval: defaultRefreshInterval,
      notificationsEnabled: true,
      launchAtLogin: false,
      showStaleIndicator: true,
    );
  }

  static const Duration minRefreshInterval = Duration(seconds: 30);
  static const Duration maxRefreshInterval = Duration(seconds: 60);
  static const Duration defaultRefreshInterval = Duration(seconds: 60);

  /// Default adaptive reveal threshold for the menu-bar title.
  static const double defaultTrayPercentThreshold = 90;

  final bool autoRefreshEnabled;
  final Duration refreshInterval;
  final bool notificationsEnabled;
  final double? notifyAtSessionPercent;
  final bool launchAtLogin;
  final String? claudeBinaryPath;
  final ProviderId selectedProviderId;
  final bool showStaleIndicator;
  final AppThemePreference themeMode;
  final ThemePreset themePreset;
  final FontPreset fontPreset;
  final AppIconPreset appIconPreset;
  final bool copilotEnabled;
  final TrayDisplayMode trayDisplayMode;
  final double trayPercentThreshold;

  /// Gates the onboarding flow (V4 §9.1) — `false` only for a genuinely
  /// fresh install; once the flow completes, this is saved `true` and
  /// never read back to `false` by anything but a fresh store.
  final bool hasCompletedOnboarding;

  /// Full reconstruct helper when a nullable field must be cleared to null.
  AppSettings replace({
    bool? autoRefreshEnabled,
    Duration? refreshInterval,
    bool? notificationsEnabled,
    Object? notifyAtSessionPercent = _unset,
    bool? launchAtLogin,
    Object? claudeBinaryPath = _unset,
    ProviderId? selectedProviderId,
    bool? showStaleIndicator,
    AppThemePreference? themeMode,
    ThemePreset? themePreset,
    FontPreset? fontPreset,
    AppIconPreset? appIconPreset,
    bool? copilotEnabled,
    TrayDisplayMode? trayDisplayMode,
    double? trayPercentThreshold,
    bool? hasCompletedOnboarding,
  }) {
    return AppSettings(
      autoRefreshEnabled: autoRefreshEnabled ?? this.autoRefreshEnabled,
      refreshInterval: refreshInterval ?? this.refreshInterval,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notifyAtSessionPercent: identical(notifyAtSessionPercent, _unset)
          ? this.notifyAtSessionPercent
          : notifyAtSessionPercent as double?,
      launchAtLogin: launchAtLogin ?? this.launchAtLogin,
      claudeBinaryPath: identical(claudeBinaryPath, _unset)
          ? this.claudeBinaryPath
          : claudeBinaryPath as String?,
      selectedProviderId: selectedProviderId ?? this.selectedProviderId,
      showStaleIndicator: showStaleIndicator ?? this.showStaleIndicator,
      themeMode: themeMode ?? this.themeMode,
      themePreset: themePreset ?? this.themePreset,
      fontPreset: fontPreset ?? this.fontPreset,
      appIconPreset: appIconPreset ?? this.appIconPreset,
      copilotEnabled: copilotEnabled ?? this.copilotEnabled,
      trayDisplayMode: trayDisplayMode ?? this.trayDisplayMode,
      trayPercentThreshold: trayPercentThreshold ?? this.trayPercentThreshold,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }

  AppSettings copyWith({
    bool? autoRefreshEnabled,
    Duration? refreshInterval,
    bool? notificationsEnabled,
    double? notifyAtSessionPercent,
    bool? launchAtLogin,
    String? claudeBinaryPath,
    ProviderId? selectedProviderId,
    bool? showStaleIndicator,
    AppThemePreference? themeMode,
    ThemePreset? themePreset,
    FontPreset? fontPreset,
    AppIconPreset? appIconPreset,
    bool? copilotEnabled,
    TrayDisplayMode? trayDisplayMode,
    double? trayPercentThreshold,
    bool? hasCompletedOnboarding,
  }) {
    return AppSettings(
      autoRefreshEnabled: autoRefreshEnabled ?? this.autoRefreshEnabled,
      refreshInterval: refreshInterval ?? this.refreshInterval,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notifyAtSessionPercent:
          notifyAtSessionPercent ?? this.notifyAtSessionPercent,
      launchAtLogin: launchAtLogin ?? this.launchAtLogin,
      claudeBinaryPath: claudeBinaryPath ?? this.claudeBinaryPath,
      selectedProviderId: selectedProviderId ?? this.selectedProviderId,
      showStaleIndicator: showStaleIndicator ?? this.showStaleIndicator,
      themeMode: themeMode ?? this.themeMode,
      themePreset: themePreset ?? this.themePreset,
      fontPreset: fontPreset ?? this.fontPreset,
      appIconPreset: appIconPreset ?? this.appIconPreset,
      copilotEnabled: copilotEnabled ?? this.copilotEnabled,
      trayDisplayMode: trayDisplayMode ?? this.trayDisplayMode,
      trayPercentThreshold: trayPercentThreshold ?? this.trayPercentThreshold,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AppSettings &&
        other.autoRefreshEnabled == autoRefreshEnabled &&
        other.refreshInterval == refreshInterval &&
        other.notificationsEnabled == notificationsEnabled &&
        other.notifyAtSessionPercent == notifyAtSessionPercent &&
        other.launchAtLogin == launchAtLogin &&
        other.claudeBinaryPath == claudeBinaryPath &&
        other.selectedProviderId == selectedProviderId &&
        other.showStaleIndicator == showStaleIndicator &&
        other.themeMode == themeMode &&
        other.themePreset == themePreset &&
        other.fontPreset == fontPreset &&
        other.appIconPreset == appIconPreset &&
        other.copilotEnabled == copilotEnabled &&
        other.trayDisplayMode == trayDisplayMode &&
        other.trayPercentThreshold == trayPercentThreshold &&
        other.hasCompletedOnboarding == hasCompletedOnboarding;
  }

  @override
  int get hashCode => Object.hash(
    autoRefreshEnabled,
    refreshInterval,
    notificationsEnabled,
    notifyAtSessionPercent,
    launchAtLogin,
    claudeBinaryPath,
    selectedProviderId,
    showStaleIndicator,
    themeMode,
    themePreset,
    fontPreset,
    appIconPreset,
    copilotEnabled,
    trayDisplayMode,
    trayPercentThreshold,
    hasCompletedOnboarding,
  );
}

const Object _unset = Object();

void _validateRefreshInterval(Duration interval) {
  if (interval < AppSettings.minRefreshInterval ||
      interval > AppSettings.maxRefreshInterval) {
    throw ArgumentError.value(
      interval,
      'refreshInterval',
      'must be between ${AppSettings.minRefreshInterval.inSeconds}s and '
          '${AppSettings.maxRefreshInterval.inSeconds}s',
    );
  }
}

double _requirePercent(double value, String name) {
  if (value.isNaN || value < 0 || value > 100) {
    throw ArgumentError.value(value, name, 'must be between 0 and 100');
  }
  return value;
}
