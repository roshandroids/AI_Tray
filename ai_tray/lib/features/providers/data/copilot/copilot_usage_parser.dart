import 'package:ai_tray/features/providers/domain/models/provider_usage_candidate.dart';
import 'package:ai_tray/features/providers/domain/ports/provider_usage_parser.dart';
import 'package:ai_tray/features/usage/domain/models/parser_state.dart';

/// Placeholder parser defining the Copilot integration seam.
///
/// Transformation:
/// - Produces an empty, invalid candidate because no stable Copilot usage
///   payload contract is available in Phase C.
final class CopilotUsageParser implements ProviderUsageParser {
  const CopilotUsageParser();

  @override
  ProviderUsageCandidate parse({
    required String rawText,
    Map<String, dynamic>? envelopeJson,
  }) {
    return ProviderUsageCandidate(
      parserState: ParserState.empty().copyWith(
        messages: const ['copilot_parser_not_implemented'],
      ),
      rawText: rawText,
    );
  }
}
