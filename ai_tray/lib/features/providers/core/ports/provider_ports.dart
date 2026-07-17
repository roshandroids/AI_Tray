import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/providers/core/models/provider_id.dart';
import 'package:ai_tray/features/providers/core/models/provider_models.dart';

/// Raw provider payload restricted to data-layer transport fields.
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
  final Map<String, dynamic>? envelopeJson;
}

/// Provider-neutral usage and health boundary.
abstract interface class AiProviderPort {
  ProviderId get providerId;

  Future<Result<UsageRawFetch>> fetchUsageRaw({
    ProviderExecutionConfig config = const ProviderExecutionConfig(),
  });

  Future<Result<AuthHealth>> healthCheck({
    ProviderExecutionConfig config = const ProviderExecutionConfig(),
  });
}

/// Converts provider-owned raw data to a provider-neutral candidate.
abstract interface class ProviderUsageParser {
  ProviderUsageCandidate parse({
    required String rawText,
    Map<String, dynamic>? envelopeJson,
  });
}

/// Complete provider registration contract.
abstract interface class AIProvider implements AiProviderPort {
  String get displayName;
  String get sourceLabel;
  bool get enabled;
  ProviderCapabilities get capabilities;
  ProviderUsageParser get parser;
  String get limitsUnavailableMessage;
}
