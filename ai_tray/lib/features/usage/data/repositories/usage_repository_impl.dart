import 'dart:async';

import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/logging/app_logger.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/providers/domain/models/provider_id.dart';
import 'package:ai_tray/features/providers/domain/ports/ai_provider.dart';
import 'package:ai_tray/features/settings/domain/models/app_settings.dart';
import 'package:ai_tray/features/settings/domain/repositories/settings_repository.dart';
import 'package:ai_tray/features/usage/data/cache/usage_cache.dart';
import 'package:ai_tray/features/usage/data/services/refresh_service.dart';
import 'package:ai_tray/features/usage/domain/models/parser_state.dart';
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
    AIProvider Function()? providerResolver,
  }) : _refreshService = refreshService,
       _cache = cache,
       _settingsRepository = settingsRepository,
       _logger = logger,
       _providerResolver = providerResolver,
       _statusController = StreamController<RefreshStatus>.broadcast() {
    _status = RefreshStatus.initial();
  }

  final RefreshService _refreshService;
  final UsageCache _cache;
  final SettingsRepository _settingsRepository;
  final AppLogger _logger;
  final AIProvider Function()? _providerResolver;
  final StreamController<RefreshStatus> _statusController;
  final Map<ProviderId, _ProviderBackoff> _backoffByProvider = {};

  late RefreshStatus _status;
  Timer? _timer;
  bool _autoRefreshPaused = false;
  bool _disposed = false;
  int _refreshGeneration = 0;
  ProviderId? _lastRequestedProviderId;

  @override
  RefreshStatus get status => _status;

  @override
  Stream<RefreshStatus> watchStatus() => _statusController.stream;

  @override
  Future<Result<UsageInfo?>> getCachedUsage() {
    return _cache.read(providerId: _providerResolver?.call().providerId);
  }

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

  /// Recovers an overdue auto-refresh after sleep/wake or similar resume.
  ///
  /// Safe to call repeatedly: fires at most one refresh when the previously
  /// scheduled deadline has passed, and never restarts paused auto-refresh.
  Future<void> recoverScheduleIfOverdue({DateTime? now}) async {
    if (_disposed || _autoRefreshPaused) {
      return;
    }
    final settings = await _settingsRepository.read();
    if (!settings.autoRefreshEnabled) {
      return;
    }
    final deadline = _status.nextScheduledAt;
    if (deadline == null) {
      return;
    }
    final clock = now ?? DateTime.now().toUtc();
    if (clock.isBefore(deadline)) {
      return;
    }
    _logger.info(
      'operation=refresh status=resume_overdue',
      name: 'usage_repository',
    );
    await refresh();
  }

  void dispose() {
    _disposed = true;
    _refreshGeneration += 1;
    _timer?.cancel();
    _timer = null;
    unawaited(_statusController.close());
  }

  @override
  Future<RefreshResult> refresh({bool manual = false}) async {
    if (_disposed) {
      return _disposedResult();
    }

    if (manual) {
      _autoRefreshPaused = false;
    }

    final settings = await _settingsRepository.read();
    if (_disposed) {
      return _disposedResult();
    }

    final requestedProviderId = _providerResolver?.call().providerId;
    final previousProviderId = _lastRequestedProviderId;
    if (previousProviderId != null &&
        requestedProviderId != null &&
        previousProviderId != requestedProviderId) {
      _refreshService.invalidateInFlight(previousProviderId);
    }
    _lastRequestedProviderId = requestedProviderId;
    final generation = ++_refreshGeneration;
    _emit(_status.copyWith(phase: RefreshPhase.refreshing));

    final result = await _refreshService.refresh(
      settings: settings,
      currentStatus: _status,
    );

    if (_disposed || generation != _refreshGeneration) {
      _logger.debug(
        'operation=refresh status=stale_ignored '
        'provider=${result.providerId?.value ?? 'unknown'} '
        'reason=${_disposed ? 'disposed' : 'generation'}',
        name: 'usage_repository',
      );
      return result;
    }

    if (requestedProviderId != null &&
        (_providerResolver?.call().providerId != requestedProviderId ||
            result.providerId != requestedProviderId)) {
      _logger.debug(
        'operation=refresh status=stale_ignored '
        'provider=${result.providerId?.value ?? 'unknown'}',
        name: 'usage_repository',
      );
      return result;
    }

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

    _emit(_statusAfter(result, settings, requestedProviderId));

    await _reschedule(settings);
    return result;
  }

  RefreshResult _disposedResult() {
    return _status.lastResult ??
        RefreshResult(
          status: RefreshOutcome.failure,
          parserState: ParserState.empty(),
          duration: Duration.zero,
        );
  }

  RefreshStatus _statusAfter(
    RefreshResult result,
    AppSettings settings,
    ProviderId? providerId,
  ) {
    final baseSeconds = settings.refreshInterval.inSeconds;
    final backoff = providerId == null
        ? _ProviderBackoff()
        : (_backoffByProvider[providerId] ??= _ProviderBackoff());

    switch (result.status) {
      case RefreshOutcome.success:
        backoff.soft = 0;
        backoff.hard = 0;
        return RefreshStatus(
          phase: RefreshPhase.idle,
          lastResult: result,
          lastSuccessAt: DateTime.now().toUtc(),
          nextScheduledAt: _nextAt(settings.refreshInterval),
        );
      case RefreshOutcome.softFailure:
        backoff.soft += 1;
        final seconds = backoff.soft >= 3 && baseSeconds < 120
            ? 120
            : baseSeconds;
        return RefreshStatus(
          phase: RefreshPhase.idle,
          lastResult: result,
          lastSuccessAt: _status.lastSuccessAt,
          nextScheduledAt: _nextAt(Duration(seconds: seconds)),
          consecutiveSoftFailures: backoff.soft,
          consecutiveHardFailures: backoff.hard,
        );
      case RefreshOutcome.failure:
        backoff.hard += 1;
        final seconds = backoff.hard >= 3 && baseSeconds < 180
            ? 180
            : baseSeconds;
        return RefreshStatus(
          phase: RefreshPhase.idle,
          lastResult: result,
          lastSuccessAt: _status.lastSuccessAt,
          nextScheduledAt: _autoRefreshPaused
              ? null
              : _nextAt(Duration(seconds: seconds)),
          consecutiveSoftFailures: backoff.soft,
          consecutiveHardFailures: backoff.hard,
        );
    }
  }

  DateTime _nextAt(Duration interval) => DateTime.now().toUtc().add(interval);

  Future<void> _reschedule(AppSettings settings) async {
    _timer?.cancel();
    _timer = null;
    if (_disposed || _autoRefreshPaused || !settings.autoRefreshEnabled) {
      return;
    }

    final providerId = _providerResolver?.call().providerId;
    final backoff = providerId == null ? null : _backoffByProvider[providerId];
    var seconds = settings.refreshInterval.inSeconds;
    if (backoff != null) {
      if (backoff.soft >= 3 && seconds < 120) {
        seconds = 120;
      } else if (backoff.hard >= 3 && seconds < 180) {
        seconds = 180;
      }
    }

    _timer = Timer(Duration(seconds: seconds), () {
      if (_disposed) {
        return;
      }
      unawaited(refresh());
    });
  }

  void _emit(RefreshStatus status) {
    if (_disposed) {
      return;
    }
    _status = status;
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }
}

final class _ProviderBackoff {
  int soft = 0;
  int hard = 0;
}
