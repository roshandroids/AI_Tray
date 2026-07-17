import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/providers/domain/models/auth_health.dart';
import 'package:ai_tray/features/providers/domain/models/provider_id.dart';
import 'package:ai_tray/features/providers/domain/ports/ai_provider_port.dart';

/// Disabled GitHub Copilot adapter contract.
///
/// Side Effects:
/// - None. Phase C intentionally performs no process or network calls.
final class CopilotAdapter implements AiProviderPort {
  const CopilotAdapter();

  static const _notImplemented = AppFailure(
    code: FailureCode.unknown,
    message: 'GitHub Copilot usage is not implemented yet',
    detail: 'The provider is registered as a disabled Phase C placeholder.',
  );

  @override
  ProviderId get providerId => ProviderId.copilot;

  @override
  Future<Result<UsageRawFetch>> fetchUsageRaw({String? binaryPath}) async {
    return const Result.failure(_notImplemented);
  }

  @override
  Future<Result<AuthHealth>> healthCheck({String? binaryPath}) async {
    return const Result.failure(_notImplemented);
  }
}
