import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/logging/app_logger.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/providers/domain/models/provider_execution_config.dart';
import 'package:ai_tray/features/providers/domain/models/provider_id.dart';
import 'package:ai_tray/features/providers/domain/ports/ai_provider.dart';
import 'package:ai_tray/features/providers/domain/ports/ai_provider_port.dart';
import 'package:ai_tray/features/providers/domain/ports/provider_usage_parser.dart';
import 'package:ai_tray/features/settings/domain/models/app_settings.dart';
import 'package:ai_tray/features/usage/data/cache/usage_cache.dart';
import 'package:ai_tray/features/usage/data/validators/usage_validator.dart';
import 'package:ai_tray/features/usage/domain/models/parser_state.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_outcome.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_result.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_status.dart';
import 'package:ai_tray/features/usage/domain/models/usage_info.dart';

/// Coordinates adapter → parse → validate → cache with ADR-002 policy.
final class RefreshService {
  RefreshService({
    required AIProvider provider,
    required UsageValidator validator,
    required UsageCache cache,
    required AppLogger logger,
    ProviderUsageParser? parser,
    AIProvider Function()? providerResolver,
    this.softRetryDelay = const Duration(seconds: 3),
    this.hardRetryDelay = const Duration(seconds: 2),
  }) : _providerResolver = providerResolver ?? (() => provider),
       _parserOverride = parser,
       _validator = validator,
       _cache = cache,
       _logger = logger;

  final AIProvider Function() _providerResolver;
  final ProviderUsageParser? _parserOverride;
  final UsageValidator _validator;
  final UsageCache _cache;
  final AppLogger _logger;
  final Duration softRetryDelay;
  final Duration hardRetryDelay;

  final Map<ProviderId, Future<RefreshResult>> _inFlight = {};

  /// Drops coalescing for [providerId] without awaiting the abandoned future.
  ///
  /// Used when the selected provider changes so a later return to the same
  /// provider starts a fresh refresh instead of joining a stale in-flight run.
  void invalidateInFlight(ProviderId providerId) {
    _inFlight.remove(providerId);
  }

  Future<RefreshResult> refresh({
    required AppSettings settings,
    required RefreshStatus currentStatus,
  }) {
    final provider = _providerResolver();
    final providerId = provider.providerId;
    final existing = _inFlight[providerId];
    if (existing != null) {
      _logger.debug(
        'operation=refresh status=coalesced provider=${providerId.value}',
        name: 'refresh',
      );
      return existing;
    }

    late final Future<RefreshResult> tracked;
    tracked =
        _run(
          settings: settings,
          currentStatus: currentStatus,
          provider: provider,
        ).whenComplete(() {
          if (identical(_inFlight[providerId], tracked)) {
            _inFlight.remove(providerId);
          }
        });
    _inFlight[providerId] = tracked;
    return tracked;
  }

  Future<RefreshResult> _run({
    required AppSettings settings,
    required RefreshStatus currentStatus,
    required AIProvider provider,
  }) async {
    final started = DateTime.now().toUtc();
    final parser = _parserOverride ?? provider.parser;
    final config = _configFor(provider, settings);
    _logger.info(
      'operation=refresh status=started provider=${provider.providerId.value}',
      name: 'refresh',
    );

    var rawResult = await provider.fetchUsageRaw(config: config);

    rawResult = await _maybeRetryRaw(
      first: rawResult,
      settings: settings,
      provider: provider,
      parser: parser,
    );

    return rawResult.when(
      success: (raw) async {
        final candidate = parser.parse(
          rawText: raw.stdout,
          envelopeJson: raw.envelopeJson,
        );
        final fetchedAt = DateTime.now().toUtc();
        final validated = _validator.validate(
          candidate,
          fetchedAt: fetchedAt,
          providerId: provider.providerId,
        );

        return validated.when(
          success: (usage) async {
            final writeResult = await _cache.write(usage);
            writeResult.when(
              success: (_) {},
              onFailure: (failure) {
                _logger.warning(
                  'operation=cache_write status=failed '
                  'provider=${provider.providerId.value} '
                  'code=${failure.code.name}',
                  name: 'refresh',
                  error: failure,
                );
              },
            );
            final result = RefreshResult(
              status: RefreshOutcome.success,
              usage: usage,
              parserState: candidate.parserState,
              duration: DateTime.now().toUtc().difference(started),
              cliExitCode: raw.exitCode,
              providerId: provider.providerId,
            );
            _logger.info(
              'refresh success durationMs=${result.duration.inMilliseconds}',
              name: 'refresh',
            );
            return result;
          },
          onFailure: (failure) async {
            final cached = await _readCache(provider.providerId);
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
              providerId: provider.providerId,
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
          final health = await provider.healthCheck(
            config: config,
          );
          final probed = health.failureOrNull;
          if (probed != null) {
            effective = probed;
          }
        }

        final cached = await _readCache(provider.providerId);
        final result = RefreshResult(
          status: RefreshOutcome.failure,
          usage: cached,
          parserState: ParserState.empty(),
          error: effective,
          duration: DateTime.now().toUtc().difference(started),
          providerId: provider.providerId,
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
    required AIProvider provider,
    required ProviderUsageParser parser,
  }) async {
    return first.when(
      success: (raw) async {
        final candidate = parser.parse(
          rawText: raw.stdout,
          envelopeJson: raw.envelopeJson,
        );
        if (candidate.parserState.rateLimitsPresent) {
          return first;
        }
        await Future<void>.delayed(softRetryDelay);
        return provider.fetchUsageRaw(config: _configFor(provider, settings));
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
        return provider.fetchUsageRaw(config: _configFor(provider, settings));
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

  Future<UsageInfo?> _readCache(ProviderId providerId) async {
    final cached = await _cache.read(providerId: providerId);
    return cached.valueOrNull;
  }

  ProviderExecutionConfig _configFor(
    AIProvider provider,
    AppSettings settings,
  ) {
    return ProviderExecutionConfig(
      executablePath: provider.capabilities.customExecutable
          ? settings.claudeBinaryPath
          : null,
    );
  }
}
