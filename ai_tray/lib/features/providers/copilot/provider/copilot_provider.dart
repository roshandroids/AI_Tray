import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/providers/copilot/adapter/copilot_adapter.dart';
import 'package:ai_tray/features/providers/copilot/mapper/copilot_usage_parser.dart';
import 'package:ai_tray/features/providers/core/models/provider_id.dart';
import 'package:ai_tray/features/providers/core/models/provider_models.dart';
import 'package:ai_tray/features/providers/core/ports/provider_ports.dart';

/// Production GitHub Copilot provider registration.
final class CopilotProvider implements AIProvider {
  /// Disabled compatibility registration for legacy provider consumers.
  const CopilotProvider({
    CopilotUsageParser parser = const CopilotUsageParser(),
  }) : _adapter = null,
       _enabled = false,
       _parser = parser;

  /// Active production registration backed by the official SDK adapter.
  CopilotProvider.active({
    required CopilotSdkAdapter adapter,
    bool enabled = true,
    CopilotUsageParser parser = const CopilotUsageParser(),
  }) : _adapter = adapter,
       _enabled = enabled,
       _parser = parser;

  final CopilotSdkAdapter? _adapter;
  final bool _enabled;
  final CopilotUsageParser _parser;

  @override
  ProviderId get providerId => ProviderId.copilot;

  @override
  String get displayName => 'GitHub Copilot';

  @override
  String get sourceLabel => 'Copilot SDK';

  @override
  bool get enabled => _enabled;

  @override
  ProviderCapabilities get capabilities => ProviderCapabilities.copilot;

  @override
  ProviderUsageParser get parser => _parser;

  @override
  String get limitsUnavailableMessage {
    return 'Copilot did not return quota data; showing last known usage.';
  }

  @override
  Future<Result<UsageRawFetch>> fetchUsageRaw({
    ProviderExecutionConfig config = const ProviderExecutionConfig(),
  }) {
    final adapter = _adapter;
    if (adapter == null) {
      return Future.value(const Result.failure(_disabledFailure));
    }
    return adapter.fetchUsageRaw(config: config);
  }

  @override
  Future<Result<AuthHealth>> healthCheck({
    ProviderExecutionConfig config = const ProviderExecutionConfig(),
  }) {
    final adapter = _adapter;
    if (adapter == null) {
      return Future.value(const Result.failure(_disabledFailure));
    }
    return adapter.healthCheck(config: config);
  }

  static const _disabledFailure = AppFailure(
    code: FailureCode.unknown,
    message: 'GitHub Copilot provider is not active',
  );
}
