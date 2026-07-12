import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/logging/app_logger.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/providers/domain/ports/ai_provider_port.dart';
import 'package:ai_tray/features/settings/domain/models/app_settings.dart';
import 'package:ai_tray/features/usage/data/cache/usage_cache.dart';
import 'package:ai_tray/features/usage/data/parsers/usage_parser.dart';
import 'package:ai_tray/features/usage/data/validators/usage_validator.dart';
import 'package:ai_tray/features/usage/domain/models/parser_state.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_outcome.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_result.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_status.dart';
import 'package:ai_tray/features/usage/domain/models/usage_info.dart';

/// Coordinates adapter → parse → validate → cache with ADR-002 policy.
final class RefreshService {
  RefreshService({
    required AiProviderPort provider,
    required UsageParser parser,
    required UsageValidator validator,
    required UsageCache cache,
    required AppLogger logger,
    this.softRetryDelay = const Duration(seconds: 3),
    this.hardRetryDelay = const Duration(seconds: 2),
  }) : _provider = provider,
       _parser = parser,
       _validator = validator,
       _cache = cache,
       _logger = logger;

  final AiProviderPort _provider;
  final UsageParser _parser;
  final UsageValidator _validator;
  final UsageCache _cache;
  final AppLogger _logger;
  final Duration softRetryDelay;
  final Duration hardRetryDelay;

  Future<RefreshResult>? _inFlight;

  Future<RefreshResult> refresh({
    required AppSettings settings,
    required RefreshStatus currentStatus,
  }) {
    final existing = _inFlight;
    if (existing != null) {
      _logger.debug('refresh coalesced (single-flight)', name: 'refresh');
      return existing;
    }

    final future = _run(settings: settings, currentStatus: currentStatus);
    _inFlight = future;
    return future.whenComplete(() {
      if (identical(_inFlight, future)) {
        _inFlight = null;
      }
    });
  }

  Future<RefreshResult> _run({
    required AppSettings settings,
    required RefreshStatus currentStatus,
  }) async {
    final started = DateTime.now().toUtc();
    _logger.info('refresh started', name: 'refresh');

    var rawResult = await _provider.fetchUsageRaw(
      binaryPath: settings.claudeBinaryPath,
    );

    rawResult = await _maybeRetryRaw(first: rawResult, settings: settings);

    return rawResult.when(
      success: (raw) async {
        final candidate = _parser.parse(
          rawText: raw.stdout,
          envelopeJson: raw.envelopeJson,
        );
        final fetchedAt = DateTime.now().toUtc();
        final validated = _validator.validate(
          candidate,
          fetchedAt: fetchedAt,
        );

        return validated.when(
          success: (usage) async {
            await _cache.write(usage);
            final result = RefreshResult(
              status: RefreshOutcome.success,
              usage: usage,
              parserState: candidate.parserState,
              duration: DateTime.now().toUtc().difference(started),
              cliExitCode: raw.exitCode,
            );
            _logger.info(
              'refresh success durationMs=${result.duration.inMilliseconds}',
              name: 'refresh',
            );
            return result;
          },
          onFailure: (failure) async {
            final cached = await _readCache();
            final soft = failure.code == FailureCode.incompleteOutput;
            final result = RefreshResult(
              status: soft
                  ? RefreshOutcome.softFailure
                  : RefreshOutcome.failure,
              usage: cached,
              parserState: candidate.parserState,
              error: failure,
              duration: DateTime.now().toUtc().difference(started),
              cliExitCode: raw.exitCode,
            );
            if (soft) {
              _logger.warning(
                'refresh softFailure usedCache=${cached != null}',
                name: 'refresh',
              );
            } else {
              _logger.error(
                'refresh failure',
                name: 'refresh',
                failure: failure,
              );
            }
            return result;
          },
        );
      },
      onFailure: (failure) async {
        var effective = failure;
        if (_shouldProbeAuth(failure, currentStatus)) {
          final health = await _provider.healthCheck(
            binaryPath: settings.claudeBinaryPath,
          );
          final probed = health.failureOrNull;
          if (probed != null) {
            effective = probed;
          }
        }

        final cached = await _readCache();
        final result = RefreshResult(
          status: RefreshOutcome.failure,
          usage: cached,
          parserState: ParserState.empty(),
          error: effective,
          duration: DateTime.now().toUtc().difference(started),
        );
        _logger.error(
          'refresh hard failure',
          name: 'refresh',
          failure: effective,
        );
        return result;
      },
    );
  }

  Future<Result<UsageRawFetch>> _maybeRetryRaw({
    required Result<UsageRawFetch> first,
    required AppSettings settings,
  }) async {
    return first.when(
      success: (raw) async {
        final candidate = _parser.parse(
          rawText: raw.stdout,
          envelopeJson: raw.envelopeJson,
        );
        if (candidate.parserState.rateLimitsPresent) {
          return first;
        }
        await Future<void>.delayed(softRetryDelay);
        return _provider.fetchUsageRaw(binaryPath: settings.claudeBinaryPath);
      },
      onFailure: (failure) async {
        final retryable =
            failure.code == FailureCode.timeout ||
            failure.code == FailureCode.processNonZeroExit ||
            failure.code == FailureCode.unknown;
        if (!retryable) {
          return first;
        }
        await Future<void>.delayed(hardRetryDelay);
        return _provider.fetchUsageRaw(binaryPath: settings.claudeBinaryPath);
      },
    );
  }

  bool _shouldProbeAuth(AppFailure failure, RefreshStatus status) {
    if (failure.code == FailureCode.cliNotInstalled ||
        failure.code == FailureCode.notAuthenticated) {
      return true;
    }
    return status.consecutiveHardFailures >= 1;
  }

  Future<UsageInfo?> _readCache() async {
    final cached = await _cache.read();
    return cached.valueOrNull;
  }
}
