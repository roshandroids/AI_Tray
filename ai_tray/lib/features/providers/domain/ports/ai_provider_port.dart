import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/providers/domain/models/auth_health.dart';
import 'package:ai_tray/features/providers/domain/models/provider_id.dart';

/// Raw usage payload returned by a provider adapter (data-layer only).
final class UsageRawFetch {
  const UsageRawFetch({
    required this.stdout,
    required this.stderr,
    required this.exitCode,
    required this.duration,
    this.envelopeJson,
  });

  final String stdout;
  final String stderr;
  final int exitCode;
  final Duration duration;

  /// Parsed JSON envelope when `--output-format json` succeeds.
  final Map<String, dynamic>? envelopeJson;
}

/// Provider-agnostic port for usage + health (ADR-001 extensibility).
abstract interface class AiProviderPort {
  ProviderId get providerId;

  Future<Result<UsageRawFetch>> fetchUsageRaw({String? binaryPath});

  Future<Result<AuthHealth>> healthCheck({String? binaryPath});
}
