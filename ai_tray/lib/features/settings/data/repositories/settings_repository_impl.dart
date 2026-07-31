import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/core/theme/app_theme_mode.dart';
import 'package:ai_tray/features/providers/domain/models/provider_id.dart';
import 'package:ai_tray/features/settings/domain/models/app_settings.dart';
import 'package:ai_tray/features/settings/domain/repositories/settings_repository.dart';
import 'package:ai_tray/features/tray/domain/tray_display_mode.dart';
import 'package:ai_tray/features/usage/data/cache/usage_cache.dart';
import 'package:ai_tray/theme/app_icons.dart';
import 'package:ai_tray/theme/font_presets.dart';
import 'package:ai_tray/theme/theme_presets.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class SharedPreferencesSettingsRepository implements SettingsRepository {
  SharedPreferencesSettingsRepository(this._prefs);

  static const _prefix = 'settings_v1_';

  final SharedPreferences _prefs;

  @override
  Future<AppSettings> read() async {
    try {
      final defaults = AppSettings.defaults();
      final intervalSeconds = _prefs.getInt('${_prefix}refreshIntervalSeconds');
      return AppSettings(
        autoRefreshEnabled:
            _prefs.getBool('${_prefix}autoRefreshEnabled') ??
            defaults.autoRefreshEnabled,
        refreshInterval: intervalSeconds == null
            ? defaults.refreshInterval
            : Duration(seconds: intervalSeconds.clamp(30, 60)),
        notificationsEnabled:
            _prefs.getBool('${_prefix}notificationsEnabled') ??
            defaults.notificationsEnabled,
        launchAtLogin:
            _prefs.getBool('${_prefix}launchAtLogin') ?? defaults.launchAtLogin,
        showStaleIndicator:
            _prefs.getBool('${_prefix}showStaleIndicator') ??
            defaults.showStaleIndicator,
        notifyAtSessionPercent: _prefs.getDouble(
          '${_prefix}notifyAtSessionPercent',
        ),
        claudeBinaryPath: _prefs.getString('${_prefix}claudeBinaryPath'),
        selectedProviderId: ProviderId(
          _prefs.getString('${_prefix}selectedProviderId') ??
              defaults.selectedProviderId.value,
        ),
        themeMode: AppThemePreference.fromStorage(
          _prefs.getString('${_prefix}themeMode'),
        ),
        themePreset: ThemePresetX.fromStorage(
          _prefs.getString('${_prefix}themePreset'),
        ),
        fontPreset: FontPresetX.fromStorage(
          _prefs.getString('${_prefix}fontPreset'),
        ),
        appIconPreset: AppIconPresets.fromStorage(
          _prefs.getString('${_prefix}appIconPreset'),
        ),
        copilotEnabled:
            _prefs.getBool('${_prefix}copilotEnabled') ??
            defaults.copilotEnabled,
        trayDisplayMode: TrayDisplayModeX.fromStorage(
          _prefs.getString('${_prefix}trayDisplayMode'),
        ),
        trayPercentThreshold:
            _prefs.getDouble('${_prefix}trayPercentThreshold') ??
            defaults.trayPercentThreshold,
      );
    } on Exception {
      return AppSettings.defaults();
    }
  }

  @override
  Future<Result<Unit>> write(AppSettings settings) async {
    try {
      await _requireSaved(
        _prefs.setBool(
          '${_prefix}autoRefreshEnabled',
          settings.autoRefreshEnabled,
        ),
      );
      await _requireSaved(
        _prefs.setInt(
          '${_prefix}refreshIntervalSeconds',
          settings.refreshInterval.inSeconds,
        ),
      );
      await _requireSaved(
        _prefs.setBool(
          '${_prefix}notificationsEnabled',
          settings.notificationsEnabled,
        ),
      );
      await _requireSaved(
        _prefs.setBool(
          '${_prefix}launchAtLogin',
          settings.launchAtLogin,
        ),
      );
      await _requireSaved(
        _prefs.setBool(
          '${_prefix}showStaleIndicator',
          settings.showStaleIndicator,
        ),
      );
      if (settings.notifyAtSessionPercent == null) {
        await _requireSaved(
          _prefs.remove('${_prefix}notifyAtSessionPercent'),
        );
      } else {
        await _requireSaved(
          _prefs.setDouble(
            '${_prefix}notifyAtSessionPercent',
            settings.notifyAtSessionPercent!,
          ),
        );
      }
      if (settings.claudeBinaryPath == null) {
        await _requireSaved(_prefs.remove('${_prefix}claudeBinaryPath'));
      } else {
        await _requireSaved(
          _prefs.setString(
            '${_prefix}claudeBinaryPath',
            settings.claudeBinaryPath!,
          ),
        );
      }
      await _requireSaved(
        _prefs.setString(
          '${_prefix}themeMode',
          settings.themeMode.storageValue,
        ),
      );
      await _requireSaved(
        _prefs.setString(
          '${_prefix}themePreset',
          settings.themePreset.storageValue,
        ),
      );
      await _requireSaved(
        _prefs.setString(
          '${_prefix}fontPreset',
          settings.fontPreset.storageValue,
        ),
      );
      await _requireSaved(
        _prefs.setString(
          '${_prefix}appIconPreset',
          settings.appIconPreset.storageValue,
        ),
      );
      await _requireSaved(
        _prefs.setString(
          '${_prefix}selectedProviderId',
          settings.selectedProviderId.value,
        ),
      );
      await _requireSaved(
        _prefs.setBool(
          '${_prefix}copilotEnabled',
          settings.copilotEnabled,
        ),
      );
      await _requireSaved(
        _prefs.setString(
          '${_prefix}trayDisplayMode',
          settings.trayDisplayMode.storageValue,
        ),
      );
      await _requireSaved(
        _prefs.setDouble(
          '${_prefix}trayPercentThreshold',
          settings.trayPercentThreshold,
        ),
      );
      return const Result.success(Unit.unit);
    } on Exception {
      return const Result.failure(
        AppFailure(
          code: FailureCode.cacheUnavailable,
          message: "Couldn't save settings",
        ),
      );
    }
  }
}

Future<void> _requireSaved(Future<bool> operation) async {
  if (!await operation) {
    throw StateError('SharedPreferences rejected a settings write');
  }
}

final class InMemorySettingsRepository implements SettingsRepository {
  InMemorySettingsRepository([AppSettings? initial])
    : _settings = initial ?? AppSettings.defaults();

  AppSettings _settings;

  @override
  Future<AppSettings> read() async => _settings;

  @override
  Future<Result<Unit>> write(AppSettings settings) async {
    _settings = settings;
    return const Result.success(Unit.unit);
  }
}
