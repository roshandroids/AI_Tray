import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/settings/domain/models/app_settings.dart';
import 'package:ai_tray/features/settings/domain/repositories/settings_repository.dart';
import 'package:ai_tray/features/usage/data/cache/usage_cache.dart';
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
        notifyAtSessionPercent:
            _prefs.getDouble('${_prefix}notifyAtSessionPercent'),
        claudeBinaryPath: _prefs.getString('${_prefix}claudeBinaryPath'),
      );
    } on Exception {
      return AppSettings.defaults();
    }
  }

  @override
  Future<Result<Unit>> write(AppSettings settings) async {
    try {
      await _prefs.setBool(
        '${_prefix}autoRefreshEnabled',
        settings.autoRefreshEnabled,
      );
      await _prefs.setInt(
        '${_prefix}refreshIntervalSeconds',
        settings.refreshInterval.inSeconds,
      );
      await _prefs.setBool(
        '${_prefix}notificationsEnabled',
        settings.notificationsEnabled,
      );
      await _prefs.setBool(
        '${_prefix}launchAtLogin',
        settings.launchAtLogin,
      );
      await _prefs.setBool(
        '${_prefix}showStaleIndicator',
        settings.showStaleIndicator,
      );
      if (settings.notifyAtSessionPercent == null) {
        await _prefs.remove('${_prefix}notifyAtSessionPercent');
      } else {
        await _prefs.setDouble(
          '${_prefix}notifyAtSessionPercent',
          settings.notifyAtSessionPercent!,
        );
      }
      if (settings.claudeBinaryPath == null) {
        await _prefs.remove('${_prefix}claudeBinaryPath');
      } else {
        await _prefs.setString(
          '${_prefix}claudeBinaryPath',
          settings.claudeBinaryPath!,
        );
      }
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
