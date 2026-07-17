import 'package:ai_tray/features/providers/copilot/mapper/copilot_quota_mapper.dart';
import 'package:ai_tray/features/providers/copilot/sdk/copilot_sdk.dart';
import 'package:ai_tray/features/providers/copilot/sdk/sidecar_process_transport.dart';
import 'package:ai_tray/features/providers/core/models/provider_models.dart';
import 'package:ai_tray/features/providers/core/models/quota_models.dart';

/// Protocol-v1 Copilot SDK implementation over the persistent sidecar.
final class CopilotSdkV1 implements CopilotSdk {
  CopilotSdkV1({
    required SidecarTransport transport,
    CopilotQuotaMapper quotaMapper = const CopilotQuotaMapper(),
  }) : _transport = transport,
       _quotaMapper = quotaMapper;

  final SidecarTransport _transport;
  final CopilotQuotaMapper _quotaMapper;

  @override
  Future<void> initialize() => _transport.initialize();

  @override
  Future<QuotaSnapshot> getQuota({
    CopilotSdkCancellationToken? cancellationToken,
  }) async {
    final response = await _transport.request(
      'quota.get',
      cancellationToken: cancellationToken,
    );
    return _quotaMapper.mapResponse(response);
  }

  @override
  Future<SessionUsage> getSessionUsage(
    String sessionId, {
    CopilotSdkCancellationToken? cancellationToken,
  }) async {
    if (sessionId.trim().isEmpty) {
      throw const CopilotSdkException(
        code: CopilotSdkErrorCode.malformedResponse,
        message: 'Copilot session id cannot be empty',
      );
    }
    final map = _map(
      await _transport.request(
        'session.usage',
        params: {'sessionId': sessionId},
        cancellationToken: cancellationToken,
      ),
      'session usage',
    );
    return SessionUsage(
      sessionId: _string(map, 'sessionId'),
      totalPremiumRequestCost: _number(map, 'totalPremiumRequestCost'),
      totalUserRequests: _nonNegativeInteger(map, 'totalUserRequests'),
      totalApiDuration: Duration(
        milliseconds: _nonNegativeInteger(map, 'totalApiDurationMs'),
      ),
      sessionStartedAt: _date(map, 'sessionStartTime'),
      currentModel: _nullableString(map, 'currentModel'),
      lastCallInputTokens: _nonNegativeInteger(map, 'lastCallInputTokens'),
      lastCallOutputTokens: _nonNegativeInteger(map, 'lastCallOutputTokens'),
    );
  }

  @override
  Future<ProviderHealth> getHealth({
    CopilotSdkCancellationToken? cancellationToken,
  }) async {
    final map = _map(
      await _transport.request(
        'health.get',
        cancellationToken: cancellationToken,
      ),
      'health',
    );
    return ProviderHealth(
      healthy: _boolean(map, 'healthy'),
      authenticated: _boolean(map, 'authenticated'),
      message: _string(map, 'message'),
      checkedAt: _date(map, 'checkedAt'),
    );
  }

  @override
  Future<VersionInfo> getVersion({
    CopilotSdkCancellationToken? cancellationToken,
  }) async {
    final map = _map(
      await _transport.request(
        'version.get',
        cancellationToken: cancellationToken,
      ),
      'version',
    );
    final version = VersionInfo(
      protocolVersion: _nonNegativeInteger(map, 'protocolVersion'),
      bridgeVersion: _string(map, 'bridgeVersion'),
      sdkVersion: _string(map, 'sdkVersion'),
      cliVersion: _nullableString(map, 'cliVersion'),
    );
    if (version.protocolVersion != SidecarProcessTransport.protocolVersion) {
      throw const CopilotSdkException(
        code: CopilotSdkErrorCode.protocolMismatch,
        message: 'Copilot SDK bridge protocol is incompatible',
      );
    }
    return version;
  }

  @override
  Future<void> shutdown() => _transport.shutdown();

  Map<String, Object?> _map(Object? value, String operation) {
    if (value is Map<String, Object?>) return value;
    throw _malformed(operation);
  }

  bool _boolean(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is bool) return value;
    throw _malformed(key);
  }

  String _string(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is String && value.trim().isNotEmpty) return value;
    throw _malformed(key);
  }

  String? _nullableString(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value == null) return null;
    if (value is String && value.trim().isNotEmpty) return value;
    throw _malformed(key);
  }

  double _number(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is num && value.isFinite && value >= 0) {
      return value.toDouble();
    }
    throw _malformed(key);
  }

  int _nonNegativeInteger(Map<String, Object?> map, String key) {
    final value = map[key];
    final integer = switch (value) {
      int() => value,
      double() when value.isFinite && value == value.roundToDouble() =>
        value.toInt(),
      _ => throw _malformed(key),
    };
    if (integer < 0) throw _malformed(key);
    return integer;
  }

  DateTime _date(Map<String, Object?> map, String key) {
    final value = DateTime.tryParse(_string(map, key));
    if (value == null) throw _malformed(key);
    return value.toUtc();
  }

  CopilotSdkException _malformed(String field) {
    return CopilotSdkException(
      code: CopilotSdkErrorCode.malformedResponse,
      message: 'Copilot SDK $field response was malformed',
    );
  }
}
