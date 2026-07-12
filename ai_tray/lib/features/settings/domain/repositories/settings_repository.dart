import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/settings/domain/models/app_settings.dart';
import 'package:ai_tray/features/usage/data/cache/usage_cache.dart';

abstract interface class SettingsRepository {
  Future<AppSettings> read();

  Future<Result<Unit>> write(AppSettings settings);
}
