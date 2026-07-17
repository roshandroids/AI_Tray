import 'dart:convert';

import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/logging/app_logger.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/providers/data/process/process_runner.dart';
import 'package:ai_tray/features/providers/domain/models/auth_health.dart';
import 'package:ai_tray/features/providers/domain/models/provider_capabilities.dart';
import 'package:ai_tray/features/providers/domain/models/provider_id.dart';
import 'package:ai_tray/features/providers/domain/ports/ai_provider.dart';
import 'package:ai_tray/features/providers/domain/ports/ai_provider_port.dart';
import 'package:ai_tray/features/providers/domain/ports/provider_usage_parser.dart';
import 'package:ai_tray/features/usage/data/parsers/usage_parser.dart';

/// Claude Code provider implementation. Never uses `--bare` for usage polls.
///
/// Data Flow:
/// - Fetches the unchanged Claude CLI JSON envelope.
/// - Exposes the existing parser through the generic provider contract.
/// - Supplies metadata and capabilities to shared UI.
final class ClaudeCliAdapter implements AIProvider {
  ClaudeCliAdapter({
    required ProcessRunner processRunner,
    required AppLogger logger,
    String defaultBinary = 'claude',
  }) : _processRunner = processRunner,
       _logger = logger,
       _defaultBinary = defaultBinary;

  final ProcessRunner _processRunner;
  final AppLogger _logger;
  final String _defaultBinary;

  @override
  ProviderId get providerId => ProviderId.claude;

  @override
  String get displayName => 'Claude';

  @override
  String get sourceLabel => 'Claude CLI';

  @override
  bool get enabled => true;

  @override
  ProviderCapabilities get capabilities => ProviderCapabilities.claude;

  @override
  ProviderUsageParser get parser => const UsageParser();

  @override
  String get limitsUnavailableMessage {
    return 'Claude did not return limits; showing last known usage.';
  }

  @override
  Future<Result<UsageRawFetch>> fetchUsageRaw({String? binaryPath}) async {
    final binary = _resolveBinary(binaryPath);
    final result = await _processRunner.run(
      binary,
      const ['-p', '/usage', '--output-format', 'json'],
    );

    return result.when(
      success: (process) {
        if (process.exitCode != 0) {
          _logger.warning(
            'claude usage non-zero exit=${process.exitCode}',
            name: 'claude_adapter',
          );
          return Result.failure(
            AppFailure(
              code: FailureCode.processNonZeroExit,
              message: 'Claude CLI returned an error',
              detail: _truncate(process.stderr),
            ),
          );
        }

        Map<String, dynamic>? envelope;
        try {
          final decoded = jsonDecode(process.stdout);
          if (decoded is Map<String, dynamic>) {
            envelope = decoded;
          } else {
            return const Result.failure(
              AppFailure(
                code: FailureCode.unknownCliOutput,
                message: 'Unexpected Claude usage JSON shape',
              ),
            );
          }
        } on FormatException catch (error) {
          return Result.failure(
            AppFailure(
              code: FailureCode.unknownCliOutput,
              message: 'Claude usage output was not valid JSON',
              detail: error.message,
            ),
          );
        }

        return Result.success(
          UsageRawFetch(
            stdout: process.stdout,
            stderr: process.stderr,
            exitCode: process.exitCode,
            duration: process.duration,
            envelopeJson: envelope,
          ),
        );
      },
      onFailure: Result.failure,
    );
  }

  @override
  Future<Result<AuthHealth>> healthCheck({String? binaryPath}) async {
    final binary = _resolveBinary(binaryPath);
    final which = await _processRunner.run(binary, const ['--version']);
    final missing = which.when(
      success: (_) => false,
      onFailure: (failure) => failure.code == FailureCode.cliNotInstalled,
    );
    if (missing) {
      return const Result.failure(
        AppFailure(
          code: FailureCode.cliNotInstalled,
          message: 'Claude CLI was not found',
        ),
      );
    }

    final auth = await _processRunner.run(
      binary,
      const ['auth', 'status', '--json'],
      timeout: const Duration(seconds: 5),
    );

    return auth.when(
      success: (process) {
        if (process.exitCode != 0) {
          return Result.failure(
            AppFailure(
              code: FailureCode.notAuthenticated,
              message: 'Claude authentication check failed',
              detail: _truncate(process.stderr),
            ),
          );
        }
        try {
          final decoded = jsonDecode(process.stdout);
          if (decoded is! Map<String, dynamic>) {
            return const Result.failure(
              AppFailure(
                code: FailureCode.unknownCliOutput,
                message: 'Unexpected auth status payload',
              ),
            );
          }
          final loggedIn = decoded['loggedIn'] == true;
          if (!loggedIn) {
            return const Result.failure(
              AppFailure(
                code: FailureCode.notAuthenticated,
                message: 'Sign in to Claude to view usage',
              ),
            );
          }
          return Result.success(
            AuthHealth(
              loggedIn: true,
              subscriptionType: decoded['subscriptionType'] as String?,
              checkedAt: DateTime.now().toUtc(),
            ),
          );
        } on FormatException {
          return const Result.failure(
            AppFailure(
              code: FailureCode.unknownCliOutput,
              message: 'Could not parse Claude auth status',
            ),
          );
        }
      },
      onFailure: (failure) {
        if (failure.code == FailureCode.cliNotInstalled) {
          return Result.failure(failure);
        }
        return Result.failure(
          AppFailure(
            code: FailureCode.notAuthenticated,
            message: 'Sign in to Claude to view usage',
            detail: failure.detail,
          ),
        );
      },
    );
  }

  String _resolveBinary(String? binaryPath) {
    final trimmed = binaryPath?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return _defaultBinary;
    }
    return trimmed;
  }

  String? _truncate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.length <= 200) return trimmed;
    return '${trimmed.substring(0, 200)}…';
  }
}
