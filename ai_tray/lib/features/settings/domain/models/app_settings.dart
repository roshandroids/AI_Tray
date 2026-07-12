import 'package:ai_tray/core/theme/app_theme_mode.dart';
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
    AppThemePreference themeMode = AppThemePreference.system,
  }) {
    _validateRefreshInterval(refreshInterval);
    final threshold = notifyAtSessionPercent;
    if (threshold != null) {
      _requirePercent(threshold, 'notifyAtSessionPercent');
    }
    final path = claudeBinaryPath?.trim();
    return AppSettings._(
      autoRefreshEnabled: autoRefreshEnabled,
      refreshInterval: refreshInterval,
      notificationsEnabled: notificationsEnabled,
      notifyAtSessionPercent: threshold,
      launchAtLogin: launchAtLogin,
      claudeBinaryPath: (path == null || path.isEmpty) ? null : path,
      showStaleIndicator: showStaleIndicator,
      themeMode: themeMode,
    );
  }

  const AppSettings._({
    required this.autoRefreshEnabled,
    required this.refreshInterval,
    required this.notificationsEnabled,
    required this.notifyAtSessionPercent,
    required this.launchAtLogin,
    required this.claudeBinaryPath,
    required this.showStaleIndicator,
    required this.themeMode,
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

  final bool autoRefreshEnabled;
  final Duration refreshInterval;
  final bool notificationsEnabled;
  final double? notifyAtSessionPercent;
  final bool launchAtLogin;
  final String? claudeBinaryPath;
  final bool showStaleIndicator;
  final AppThemePreference themeMode;

  AppSettings copyWith({
    bool? autoRefreshEnabled,
    Duration? refreshInterval,
    bool? notificationsEnabled,
    double? notifyAtSessionPercent,
    bool? launchAtLogin,
    String? claudeBinaryPath,
    bool? showStaleIndicator,
    AppThemePreference? themeMode,
  }) {
    return AppSettings(
      autoRefreshEnabled: autoRefreshEnabled ?? this.autoRefreshEnabled,
      refreshInterval: refreshInterval ?? this.refreshInterval,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notifyAtSessionPercent:
          notifyAtSessionPercent ?? this.notifyAtSessionPercent,
      launchAtLogin: launchAtLogin ?? this.launchAtLogin,
      claudeBinaryPath: claudeBinaryPath ?? this.claudeBinaryPath,
      showStaleIndicator: showStaleIndicator ?? this.showStaleIndicator,
      themeMode: themeMode ?? this.themeMode,
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
        other.showStaleIndicator == showStaleIndicator &&
        other.themeMode == themeMode;
  }

  @override
  int get hashCode => Object.hash(
    autoRefreshEnabled,
    refreshInterval,
    notificationsEnabled,
    notifyAtSessionPercent,
    launchAtLogin,
    claudeBinaryPath,
    showStaleIndicator,
    themeMode,
  );
}

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
