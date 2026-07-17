import 'dart:async';

import 'package:ai_tray/features/providers/core/models/provider_models.dart';
import 'package:ai_tray/features/providers/core/models/quota_models.dart';

/// Stable SDK failure categories that do not expose bridge internals.
enum CopilotSdkErrorCode {
  cancelled,
  timeout,
  processLaunchFailed,
  processCrashed,
  protocolMismatch,
  malformedResponse,
  authenticationFailed,
  authenticationExpired,
  sessionNotFound,
  unsupportedCapability,
  unsupportedSdk,
  rpcUnavailable,
  experimentalDisabled,
  networkUnavailable,
  schemaChanged,
  operationFailed,
}

/// Typed, secret-safe SDK boundary failure.
final class CopilotSdkException implements Exception {
  const CopilotSdkException({
    required this.code,
    required this.message,
    this.retryable = false,
  });

  final CopilotSdkErrorCode code;
  final String message;
  final bool retryable;

  @override
  String toString() => 'CopilotSdkException($code, $message)';
}

/// Cooperative cancellation signal for pending bridge requests.
final class CopilotSdkCancellationToken {
  final Completer<void> _cancelled = Completer<void>();

  bool get isCancelled => _cancelled.isCompleted;
  Future<void> get whenCancelled => _cancelled.future;

  void cancel() {
    if (!_cancelled.isCompleted) _cancelled.complete();
  }
}

/// SDK-free lifecycle and data boundary consumed by Copilot adapters.
abstract interface class CopilotSdk {
  Future<void> initialize();

  Future<QuotaSnapshot> getQuota({
    CopilotSdkCancellationToken? cancellationToken,
  });

  Future<SessionUsage> getSessionUsage(
    String sessionId, {
    CopilotSdkCancellationToken? cancellationToken,
  });

  Future<ProviderHealth> getHealth({
    CopilotSdkCancellationToken? cancellationToken,
  });

  Future<VersionInfo> getVersion({
    CopilotSdkCancellationToken? cancellationToken,
  });

  Future<void> shutdown();
}
