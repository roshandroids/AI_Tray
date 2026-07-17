import 'dart:async';

import 'package:ai_tray/core/logging/app_logger.dart';
import 'package:ai_tray/features/providers/copilot/sdk/copilot_sdk.dart';
import 'package:ai_tray/features/providers/core/cache/provider_cache.dart';
import 'package:ai_tray/features/providers/core/models/provider_id.dart';
import 'package:ai_tray/features/providers/core/models/provider_models.dart';
import 'package:ai_tray/features/providers/core/models/quota_models.dart';
import 'package:meta/meta.dart';

/// Secret-free Copilot availability and compatibility snapshot.
@immutable
final class CopilotDiagnostics {
  const CopilotDiagnostics({
    required this.providerEnabled,
    required this.available,
    required this.authStatus,
    required this.healthStatus,
    required this.quotaRpcStatus,
    required this.sdkVersion,
    required this.cliVersion,
    required this.experimentalStatus,
    required this.currentModel,
    required this.checkedAt,
    required this.duration,
  });

  factory CopilotDiagnostics.disabled(DateTime checkedAt) {
    return CopilotDiagnostics(
      providerEnabled: false,
      available: false,
      authStatus: 'Not checked',
      healthStatus: 'Disabled',
      quotaRpcStatus: 'Disabled',
      sdkVersion: '—',
      cliVersion: '—',
      experimentalStatus: 'Disabled',
      currentModel: '—',
      checkedAt: checkedAt,
      duration: Duration.zero,
    );
  }

  final bool providerEnabled;
  final bool available;
  final String authStatus;
  final String healthStatus;
  final String quotaRpcStatus;
  final String sdkVersion;
  final String cliVersion;
  final String experimentalStatus;
  final String currentModel;
  final DateTime checkedAt;
  final Duration duration;
}

/// Pure backend diagnostics orchestrator with no Riverpod or UI dependency.
///
/// Health and version metadata use bounded provider-scoped caches. Quota is
/// always probed live and all failures are projected to secret-free statuses.
final class CopilotDiagnosticsService {
  CopilotDiagnosticsService({
    required CopilotSdk sdk,
    required AppLogger logger,
    ProviderMetadataCache<ProviderHealth>? healthCache,
    ProviderMetadataCache<VersionInfo>? versionCache,
    DateTime Function()? clock,
    this.timeout = const Duration(seconds: 10),
  }) : _sdk = sdk,
       _logger = logger,
       _healthCache = healthCache ?? ProviderMetadataCache(),
       _versionCache = versionCache ?? ProviderMetadataCache(),
       _clock = clock ?? DateTime.now;

  static const _logName = 'copilot_diagnostics';

  final CopilotSdk _sdk;
  final AppLogger _logger;
  final ProviderMetadataCache<ProviderHealth> _healthCache;
  final ProviderMetadataCache<VersionInfo> _versionCache;
  final DateTime Function() _clock;
  final Duration timeout;

  /// Returns a complete diagnostics snapshot for disabled, success, timeout,
  /// authentication, malformed, and unexpected failure states.
  Future<CopilotDiagnostics> inspect({
    required bool enabled,
    bool forceRefresh = false,
  }) async {
    final startedAt = _clock().toUtc();
    if (!enabled) return CopilotDiagnostics.disabled(startedAt);

    try {
      await _sdk.initialize().timeout(timeout);
    } on Object catch (error) {
      final status = _statusFor(error);
      _logger.warning(
        'operation=initialize status=failure code=$status',
        name: _logName,
      );
      return _unavailable(startedAt, status);
    }

    final health = await _probe<ProviderHealth>(
      () => _healthCache.getOrLoad(
        ProviderId.copilot,
        () => _sdk.getHealth().timeout(timeout),
        forceRefresh: forceRefresh,
      ),
    );
    final version = await _probe<VersionInfo>(
      () => _versionCache.getOrLoad(
        ProviderId.copilot,
        () => _sdk.getVersion().timeout(timeout),
        forceRefresh: forceRefresh,
      ),
    );
    final quota = await _probe<QuotaSnapshot>(
      () => _sdk.getQuota().timeout(timeout),
    );
    final healthValue = health.value;
    final available = (healthValue?.healthy ?? false) && quota.value != null;
    final duration = _clock().toUtc().difference(startedAt);

    _logger.info(
      'operation=inspect status=${available ? 'available' : 'unavailable'} '
      'duration_ms=${duration.inMilliseconds}',
      name: _logName,
    );
    return CopilotDiagnostics(
      providerEnabled: true,
      available: available,
      authStatus: healthValue == null
          ? health.status
          : healthValue.authenticated
          ? 'Authenticated'
          : 'Signed out',
      healthStatus: healthValue == null
          ? health.status
          : healthValue.healthy
          ? 'Healthy'
          : healthValue.message,
      quotaRpcStatus: quota.value == null ? quota.status : 'Available',
      sdkVersion: version.value?.sdkVersion ?? version.status,
      cliVersion: version.value?.cliVersion ?? '—',
      experimentalStatus: version.value == null
          ? 'Unavailable'
          : 'Session-scoped RPC available',
      currentModel: 'No active SDK session',
      checkedAt: _clock().toUtc(),
      duration: duration,
    );
  }

  Future<({T? value, String status})> _probe<T>(
    Future<T> Function() operation,
  ) async {
    try {
      return (value: await operation(), status: 'Available');
    } on Object catch (error) {
      return (value: null, status: _statusFor(error));
    }
  }

  CopilotDiagnostics _unavailable(DateTime startedAt, String status) {
    return CopilotDiagnostics(
      providerEnabled: true,
      available: false,
      authStatus: 'Not checked',
      healthStatus: status,
      quotaRpcStatus: 'Unavailable',
      sdkVersion: '—',
      cliVersion: '—',
      experimentalStatus: 'Unavailable',
      currentModel: '—',
      checkedAt: _clock().toUtc(),
      duration: _clock().toUtc().difference(startedAt),
    );
  }

  String _statusFor(Object error) {
    if (error is TimeoutException) return 'Timed out';
    if (error is! CopilotSdkException) return 'Unavailable';
    return switch (error.code) {
      CopilotSdkErrorCode.authenticationFailed ||
      CopilotSdkErrorCode.authenticationExpired => 'Signed out',
      CopilotSdkErrorCode.timeout => 'Timed out',
      CopilotSdkErrorCode.experimentalDisabled => 'Experimental disabled',
      CopilotSdkErrorCode.rpcUnavailable => 'RPC unavailable',
      CopilotSdkErrorCode.protocolMismatch ||
      CopilotSdkErrorCode.unsupportedSdk => 'Unsupported version',
      CopilotSdkErrorCode.malformedResponse ||
      CopilotSdkErrorCode.schemaChanged => 'Malformed response',
      _ => 'Unavailable (${error.code.name})',
    };
  }
}
