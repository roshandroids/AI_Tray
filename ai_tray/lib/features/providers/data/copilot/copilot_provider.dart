import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/providers/data/copilot/copilot_adapter.dart';
import 'package:ai_tray/features/providers/data/copilot/copilot_usage_parser.dart';
import 'package:ai_tray/features/providers/domain/models/auth_health.dart';
import 'package:ai_tray/features/providers/domain/models/provider_capabilities.dart';
import 'package:ai_tray/features/providers/domain/models/provider_id.dart';
import 'package:ai_tray/features/providers/domain/ports/ai_provider.dart';
import 'package:ai_tray/features/providers/domain/ports/ai_provider_port.dart';
import 'package:ai_tray/features/providers/domain/ports/provider_usage_parser.dart';

/// Disabled GitHub Copilot provider registration for Phase C.
///
/// Dependencies:
/// - Delegates raw operations to [CopilotAdapter].
/// - Exposes [CopilotUsageParser] as the future parser integration point.
final class CopilotProvider implements AIProvider {
  const CopilotProvider({
    CopilotAdapter adapter = const CopilotAdapter(),
    CopilotUsageParser parser = const CopilotUsageParser(),
  }) : _adapter = adapter,
       _parser = parser;

  final CopilotAdapter _adapter;
  final CopilotUsageParser _parser;

  @override
  ProviderId get providerId => ProviderId.copilot;

  @override
  String get displayName => 'GitHub Copilot';

  @override
  String get sourceLabel => 'GitHub Copilot';

  @override
  bool get enabled => false;

  @override
  ProviderCapabilities get capabilities {
    return ProviderCapabilities.copilotPlaceholder;
  }

  @override
  ProviderUsageParser get parser => _parser;

  @override
  String get limitsUnavailableMessage {
    return 'GitHub Copilot usage is not available yet.';
  }

  @override
  Future<Result<UsageRawFetch>> fetchUsageRaw({String? binaryPath}) {
    return _adapter.fetchUsageRaw(binaryPath: binaryPath);
  }

  @override
  Future<Result<AuthHealth>> healthCheck({String? binaryPath}) {
    return _adapter.healthCheck(binaryPath: binaryPath);
  }
}
