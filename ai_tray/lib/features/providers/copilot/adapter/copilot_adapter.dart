import 'dart:async';
import 'dart:convert';

import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/logging/app_logger.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/providers/copilot/sdk/copilot_sdk.dart';
import 'package:ai_tray/features/providers/core/models/provider_id.dart';
import 'package:ai_tray/features/providers/core/models/provider_models.dart';
import 'package:ai_tray/features/providers/core/models/quota_models.dart';
import 'package:ai_tray/features/providers/core/ports/provider_ports.dart';

/// Bounded retry policy for transient SDK initialization and RPC failures.
final class CopilotRetryPolicy {
  const CopilotRetryPolicy({
    this.maxAttempts = 2,
    this.delay = const Duration(milliseconds: 250),
  }) : assert(maxAttempts > 0, 'maxAttempts must be greater than zero');

  final int maxAttempts;
  final Duration delay;

  bool shouldRetry(CopilotSdkException error, int attempt) {
    return attempt < maxAttempts && error.retryable;
  }
}

/// Adapts the Copilot SDK to the provider-neutral raw usage contract.
///
/// The adapter owns lazy initialization and shutdown, emits only app-owned
/// envelopes, and never logs response bodies, credentials, or SDK errors.
final class CopilotSdkAdapter implements AiProviderPort {
  CopilotSdkAdapter({
    required CopilotSdk sdk,
    required AppLogger logger,
    DateTime Function()? clock,
    this.timeout = const Duration(seconds: 15),
    this.retryPolicy = const CopilotRetryPolicy(),
  }) : _sdk = sdk,
       _logger = logger,
       _clock = clock ?? DateTime.now;

  static const _logName = 'copilot_sdk_adapter';
  static const _schemaVersion = 1;

  final CopilotSdk _sdk;
  final AppLogger _logger;
  final DateTime Function() _clock;
  final Duration timeout;
  final CopilotRetryPolicy retryPolicy;
  Future<void>? _initializing;
  bool _initialized = false;
  bool _shutdown = false;

  @override
  ProviderId get providerId => ProviderId.copilot;

  @override
  Future<Result<UsageRawFetch>> fetchUsageRaw({
    ProviderExecutionConfig config = const ProviderExecutionConfig(),
  }) async {
    final startedAt = _clock().toUtc();
    for (var attempt = 1; attempt <= retryPolicy.maxAttempts; attempt += 1) {
      final cancellationToken = CopilotSdkCancellationToken();
      try {
        await _ensureInitialized().timeout(timeout);
        final snapshot = await _sdk
            .getQuota(cancellationToken: cancellationToken)
            .timeout(
              timeout,
              onTimeout: () {
                cancellationToken.cancel();
                throw TimeoutException('quota deadline exceeded');
              },
            );
        final fetchedAt = _clock().toUtc();
        final envelope = _quotaEnvelope(snapshot, fetchedAt);
        _logger.info(
          'operation=quota status=success attempt=$attempt '
          'duration_ms=${fetchedAt.difference(startedAt).inMilliseconds}',
          name: _logName,
        );
        return Result.success(
          UsageRawFetch(
            stdout: jsonEncode(envelope),
            stderr: '',
            exitCode: 0,
            duration: fetchedAt.difference(startedAt),
            envelopeJson: envelope,
          ),
        );
      } on TimeoutException {
        cancellationToken.cancel();
        const error = CopilotSdkException(
          code: CopilotSdkErrorCode.timeout,
          message: 'Copilot SDK request timed out',
          retryable: true,
        );
        if (await _retry(error, attempt, operation: 'quota')) continue;
        return Result.failure(_failureFor(error));
      } on CopilotSdkException catch (error) {
        if (await _retry(error, attempt, operation: 'quota')) continue;
        final failure = _failureFor(error);
        _logger.error(
          'operation=quota status=failure code=${error.code.name} '
          'attempt=$attempt',
          name: _logName,
          failure: failure,
        );
        return Result.failure(failure);
      } on Exception catch (error, stackTrace) {
        const failure = AppFailure(
          code: FailureCode.unknown,
          message: 'Copilot SDK could not load quota usage',
        );
        _logger.error(
          'operation=quota status=failure code=unexpected',
          name: _logName,
          error: error.runtimeType,
          stackTrace: stackTrace,
          failure: failure,
        );
        return const Result.failure(failure);
      }
    }
    return const Result.failure(
      AppFailure(
        code: FailureCode.unknown,
        message: 'Copilot SDK retry policy was exhausted',
      ),
    );
  }

  @override
  Future<Result<AuthHealth>> healthCheck({
    ProviderExecutionConfig config = const ProviderExecutionConfig(),
  }) async {
    final token = CopilotSdkCancellationToken();
    try {
      await _ensureInitialized().timeout(timeout);
      final health = await _sdk
          .getHealth(cancellationToken: token)
          .timeout(
            timeout,
            onTimeout: () {
              token.cancel();
              throw TimeoutException('health deadline exceeded');
            },
          );
      if (!health.authenticated) {
        return const Result.failure(
          AppFailure(
            code: FailureCode.notAuthenticated,
            message: 'Sign in to GitHub Copilot before refreshing usage',
          ),
        );
      }
      if (!health.healthy) {
        return const Result.failure(
          AppFailure(
            code: FailureCode.unknown,
            message: 'Copilot SDK is not ready',
          ),
        );
      }
      return Result.success(
        AuthHealth(loggedIn: true, checkedAt: health.checkedAt),
      );
    } on TimeoutException {
      token.cancel();
      return const Result.failure(
        AppFailure(
          code: FailureCode.timeout,
          message: 'Copilot SDK health check timed out',
        ),
      );
    } on CopilotSdkException catch (error) {
      return Result.failure(_failureFor(error));
    } on Exception catch (error, stackTrace) {
      _logger.error(
        'operation=health status=failure code=unexpected',
        name: _logName,
        error: error.runtimeType,
        stackTrace: stackTrace,
      );
      return const Result.failure(
        AppFailure(
          code: FailureCode.unknown,
          message: 'Copilot SDK health check failed',
        ),
      );
    }
  }

  /// Stops the persistent SDK process exactly once.
  Future<void> shutdown() async {
    if (_shutdown) return;
    _shutdown = true;
    try {
      await _sdk.shutdown().timeout(timeout);
      _logger.debug(
        'operation=shutdown status=success',
        name: _logName,
      );
    } on Exception catch (error, stackTrace) {
      _logger.warning(
        'operation=shutdown status=failure code=unexpected',
        name: _logName,
        error: error.runtimeType,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _ensureInitialized() {
    if (_shutdown) {
      return Future.error(
        const CopilotSdkException(
          code: CopilotSdkErrorCode.cancelled,
          message: 'Copilot SDK adapter has stopped',
        ),
      );
    }
    if (_initialized) return Future.value();
    final existing = _initializing;
    if (existing != null) return existing;
    final future = _sdk.initialize().then((_) => _initialized = true);
    _initializing = future.whenComplete(() => _initializing = null);
    return _initializing!;
  }

  Future<bool> _retry(
    CopilotSdkException error,
    int attempt, {
    required String operation,
  }) async {
    if (!retryPolicy.shouldRetry(error, attempt)) return false;
    _logger.warning(
      'operation=$operation status=retry code=${error.code.name} '
      'attempt=$attempt',
      name: _logName,
    );
    await Future<void>.delayed(retryPolicy.delay);
    return true;
  }

  Map<String, dynamic> _quotaEnvelope(
    QuotaSnapshot snapshot,
    DateTime fetchedAt,
  ) {
    return {
      'schema_version': _schemaVersion,
      'provider': providerId.value,
      'fetched_at': fetchedAt.toIso8601String(),
      'quota': {
        'premium': _quotaMap(snapshot.premium),
        'chat': _quotaMap(snapshot.chat),
        'completion': _quotaMap(snapshot.completion),
      },
    };
  }

  Map<String, dynamic> _quotaMap(CopilotQuota quota) {
    return {
      'available': quota.available,
      'entitlement_requests': quota.entitlementRequests,
      'used_requests': quota.usedRequests,
      'remaining_percentage': quota.remainingPercentage,
      'unlimited': quota.isUnlimited,
      'overage': quota.overage,
      'overage_allowed_with_exhausted_quota':
          quota.overageAllowedWithExhaustedQuota,
      'reset_at': quota.reset?.at.toIso8601String(),
    };
  }

  AppFailure _failureFor(CopilotSdkException error) {
    return switch (error.code) {
      CopilotSdkErrorCode.cancelled => const AppFailure(
        code: FailureCode.cancelled,
        message: 'Copilot SDK request was cancelled',
      ),
      CopilotSdkErrorCode.timeout => const AppFailure(
        code: FailureCode.timeout,
        message: 'Copilot SDK request timed out',
      ),
      CopilotSdkErrorCode.processLaunchFailed => const AppFailure(
        code: FailureCode.cliNotInstalled,
        message: 'The bundled Copilot runtime could not start',
      ),
      CopilotSdkErrorCode.processCrashed ||
      CopilotSdkErrorCode.protocolMismatch ||
      CopilotSdkErrorCode.unsupportedCapability ||
      CopilotSdkErrorCode.unsupportedSdk => const AppFailure(
        code: FailureCode.processNonZeroExit,
        message: 'The bundled Copilot runtime is incompatible',
      ),
      CopilotSdkErrorCode.malformedResponse ||
      CopilotSdkErrorCode.sessionNotFound ||
      CopilotSdkErrorCode.schemaChanged => const AppFailure(
        code: FailureCode.unknownCliOutput,
        message: 'Copilot quota data changed or was malformed',
      ),
      CopilotSdkErrorCode.authenticationFailed ||
      CopilotSdkErrorCode.authenticationExpired => const AppFailure(
        code: FailureCode.notAuthenticated,
        message: 'Your GitHub Copilot session expired; sign in again',
      ),
      CopilotSdkErrorCode.rpcUnavailable => const AppFailure(
        code: FailureCode.unknown,
        message: 'The Copilot quota RPC is unavailable',
      ),
      CopilotSdkErrorCode.experimentalDisabled => const AppFailure(
        code: FailureCode.unknown,
        message: 'The experimental Copilot quota capability is disabled',
      ),
      CopilotSdkErrorCode.networkUnavailable => const AppFailure(
        code: FailureCode.timeout,
        message: 'Connect to the internet to refresh Copilot usage',
      ),
      CopilotSdkErrorCode.operationFailed when error.retryable =>
        const AppFailure(
          code: FailureCode.timeout,
          message: 'Copilot SDK RPC is temporarily unavailable',
        ),
      CopilotSdkErrorCode.operationFailed => const AppFailure(
        code: FailureCode.unknown,
        message: 'Copilot SDK could not complete the request',
      ),
    };
  }
}
