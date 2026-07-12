import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/settings/domain/models/app_settings.dart';
import 'package:ai_tray/features/usage/data/cache/usage_cache.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_result.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_status.dart';
import 'package:ai_tray/features/usage/domain/models/usage_info.dart';

/// Domain port for usage reads and refresh orchestration.
abstract interface class UsageRepository {
  Future<Result<UsageInfo?>> getCachedUsage();

  Future<RefreshResult> refresh({bool manual = false});

  RefreshStatus get status;

  Stream<RefreshStatus> watchStatus();

  Future<AppSettings> getSettings();

  Future<Result<Unit>> updateSettings(AppSettings settings);
}
