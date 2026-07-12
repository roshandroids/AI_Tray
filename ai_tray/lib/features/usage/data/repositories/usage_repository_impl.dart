import 'dart:async';

import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/logging/app_logger.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/settings/domain/models/app_settings.dart';
import 'package:ai_tray/features/settings/domain/repositories/settings_repository.dart';
import 'package:ai_tray/features/usage/data/cache/usage_cache.dart';
import 'package:ai_tray/features/usage/data/services/refresh_service.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_outcome.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_phase.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_result.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_status.dart';
import 'package:ai_tray/features/usage/domain/models/usage_info.dart';
import 'package:ai_tray/features/usage/domain/repositories/usage_repository.dart';

final class UsageRepositoryImpl implements UsageRepository {
  UsageRepositoryImpl({
    required RefreshService refreshService,
    required UsageCache cache,
    required SettingsRepository settingsRepository,
    required AppLogger logger,
  })  : _refreshService = refreshService,
        _cache = cache,
        _settingsRepository = settingsRepository,
        _logger = logger,
        _statusController = StreamController<RefreshStatus>.broadcast() {
    _status = RefreshStatus.initial();
  }

  final RefreshService _refreshService;
  final UsageCache _cache;
  final SettingsRepository _settingsRepository;
  final AppLogger _logger;
  final StreamController<RefreshStatus> _statusController;

  late RefreshStatus _status;
  Timer? _timer;
  bool _autoRefreshPaused = false;

  @override
  RefreshStatus get status => _status;

  @override
  Stream<RefreshStatus> watchStatus() => _statusController.stream;

  @override
  Future<Result<UsageInfo?>> getCachedUsage() => _cache.read();

  @override
  Future<AppSettings> getSettings() => _settingsRepository.read();

  @override
  Future<Result<Unit>> updateSettings(AppSettings settings) async {
    final written = await _settingsRepository.write(settings);
    if (written.isSuccess) {
      _autoRefreshPaused = false;
      await _reschedule(settings);
    }
    return written;
  }

  Future<void> start() async {
    final settings = await _settingsRepository.read();
    await refresh();
    await _reschedule(settings);
  }

  void dispose() {
    _timer?.cancel();
    unawaited(_statusController.close());
  }

  @override
  Future<RefreshResult> refresh({bool manual = false}) async {
    if (manual) {
      _autoRefreshPaused = false;
    }

    final settings = await _settingsRepository.read();
    _emit(_status.copyWith(phase: RefreshPhase.refreshing));

    final result = await _refreshService.refresh(
      settings: settings,
      currentStatus: _status,
    );

    _emit(_statusAfter(result, settings));

    if (result.status == RefreshOutcome.failure) {
      final code = result.error?.code;
      if (code == FailureCode.cliNotInstalled ||
          code == FailureCode.notAuthenticated) {
        _autoRefreshPaused = true;
        _timer?.cancel();
        _logger.warning(
          'auto-refresh paused due to ${code?.name}',
          name: 'usage_repository',
        );
      }
    }

    await _reschedule(settings);
    return result;
  }

  RefreshStatus _statusAfter(RefreshResult result, AppSettings settings) {
    final baseSeconds = settings.refreshInterval.inSeconds;
    switch (result.status) {
      case RefreshOutcome.success:
        return RefreshStatus(
          phase: RefreshPhase.idle,
          lastResult: result,
          lastSuccessAt: DateTime.now().toUtc(),
          nextScheduledAt: _nextAt(settings.refreshInterval),
        );
      case RefreshOutcome.softFailure:
        final soft = _status.consecutiveSoftFailures + 1;
        final seconds = soft >= 3 && baseSeconds < 120 ? 120 : baseSeconds;
        return RefreshStatus(
          phase: RefreshPhase.idle,
          lastResult: result,
          lastSuccessAt: _status.lastSuccessAt,
          nextScheduledAt: _nextAt(Duration(seconds: seconds)),
          consecutiveSoftFailures: soft,
        );
      case RefreshOutcome.failure:
        final hard = _status.consecutiveHardFailures + 1;
        final seconds = hard >= 3 && baseSeconds < 180 ? 180 : baseSeconds;
        return RefreshStatus(
          phase: RefreshPhase.idle,
          lastResult: result,
          lastSuccessAt: _status.lastSuccessAt,
          nextScheduledAt: _autoRefreshPaused
              ? null
              : _nextAt(Duration(seconds: seconds)),
          consecutiveSoftFailures: _status.consecutiveSoftFailures,
          consecutiveHardFailures: hard,
        );
    }
  }

  DateTime _nextAt(Duration interval) => DateTime.now().toUtc().add(interval);

  Future<void> _reschedule(AppSettings settings) async {
    _timer?.cancel();
    if (_autoRefreshPaused || !settings.autoRefreshEnabled) {
      return;
    }

    var seconds = settings.refreshInterval.inSeconds;
    if (_status.consecutiveSoftFailures >= 3 && seconds < 120) {
      seconds = 120;
    } else if (_status.consecutiveHardFailures >= 3 && seconds < 180) {
      seconds = 180;
    }

    _timer = Timer(Duration(seconds: seconds), () {
      unawaited(refresh());
    });
  }

  void _emit(RefreshStatus status) {
    _status = status;
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }
}
