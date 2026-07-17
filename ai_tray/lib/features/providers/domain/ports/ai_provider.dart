import 'package:ai_tray/features/providers/domain/models/provider_capabilities.dart';
import 'package:ai_tray/features/providers/domain/ports/ai_provider_port.dart';
import 'package:ai_tray/features/providers/domain/ports/provider_usage_parser.dart';

/// Complete provider contract registered by the AI Tray platform.
///
/// Data Flow:
/// - The adapter methods fetch raw usage and authentication health.
/// - [parser] normalizes provider-specific output for the shared refresh flow.
/// - Metadata and [capabilities] drive selector and dashboard rendering.
abstract interface class AIProvider implements AiProviderPort {
  String get displayName;

  String get sourceLabel;

  bool get enabled;

  ProviderCapabilities get capabilities;

  ProviderUsageParser get parser;

  /// Provider-authored message shown when limits are temporarily unavailable.
  String get limitsUnavailableMessage;
}
