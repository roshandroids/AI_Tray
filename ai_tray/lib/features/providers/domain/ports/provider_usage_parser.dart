import 'package:ai_tray/features/providers/domain/models/provider_usage_candidate.dart';

/// Maps provider adapter output into a normalized usage candidate.
///
/// Implementations remain provider-owned while refresh and UI consume the
/// normalized result through shared contracts.
abstract interface class ProviderUsageParser {
  ProviderUsageCandidate parse({
    required String rawText,
    Map<String, dynamic>? envelopeJson,
  });
}
