import 'dart:convert';

import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/logging/console_app_logger.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/providers/data/claude/claude_cli_adapter.dart';
import 'package:ai_tray/features/providers/data/process/fake_process_runner.dart';
import 'package:ai_tray/features/providers/data/process/process_runner.dart';
import 'package:ai_tray/features/providers/domain/models/provider_execution_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeProcessRunner runner;
  late ClaudeCliAdapter adapter;

  setUp(() {
    runner = FakeProcessRunner();
    adapter = ClaudeCliAdapter(
      processRunner: runner,
      logger: ConsoleAppLogger(defaultName: 'adapter_test'),
    );
  });

  test('fetchUsageRaw uses -p /usage json and never --bare', () async {
    runner.handler = (exe, args) {
      expect(exe, 'claude');
      expect(args, ['-p', '/usage', '--output-format', 'json']);
      expect(args, isNot(contains('--bare')));
      return Result.success(
        ProcessRunResult(
          exitCode: 0,
          stdout: jsonEncode({
            'type': 'result',
            'result': 'Current session: 1% used · resets later',
          }),
          stderr: '',
          duration: Duration.zero,
        ),
      );
    };

    final result = await adapter.fetchUsageRaw();
    expect(result.isSuccess, isTrue);
  });

  test('respects custom binary path', () async {
    runner.handler = (exe, args) {
      expect(exe, '/opt/homebrew/bin/claude');
      return Result.success(
        ProcessRunResult(
          exitCode: 0,
          stdout: jsonEncode({'type': 'result', 'result': 'x'}),
          stderr: '',
          duration: Duration.zero,
        ),
      );
    };

    await adapter.fetchUsageRaw(
      config: const ProviderExecutionConfig(
        executablePath: '/opt/homebrew/bin/claude',
      ),
    );
  });

  test('non-zero exit maps to processNonZeroExit', () async {
    runner.handler = (exe, args) {
      return const Result.success(
        ProcessRunResult(
          exitCode: 1,
          stdout: '',
          stderr: 'boom',
          duration: Duration.zero,
        ),
      );
    };

    final result = await adapter.fetchUsageRaw();
    expect(result.failureOrNull?.code, FailureCode.processNonZeroExit);
  });

  test('invalid JSON maps to unknownCliOutput', () async {
    runner.handler = (exe, args) {
      return const Result.success(
        ProcessRunResult(
          exitCode: 0,
          stdout: 'not-json',
          stderr: '',
          duration: Duration.zero,
        ),
      );
    };

    final result = await adapter.fetchUsageRaw();
    expect(result.failureOrNull?.code, FailureCode.unknownCliOutput);
  });

  test('healthCheck loggedIn false → notAuthenticated', () async {
    runner.handler = (exe, args) {
      if (args.contains('--version')) {
        return const Result.success(
          ProcessRunResult(
            exitCode: 0,
            stdout: '1.0.0',
            stderr: '',
            duration: Duration.zero,
          ),
        );
      }
      return Result.success(
        ProcessRunResult(
          exitCode: 0,
          stdout: jsonEncode({'loggedIn': false}),
          stderr: '',
          duration: Duration.zero,
        ),
      );
    };

    final result = await adapter.healthCheck();
    expect(result.failureOrNull?.code, FailureCode.notAuthenticated);
  });

  test('healthCheck missing binary → cliNotInstalled', () async {
    runner.handler = (exe, args) {
      return const Result.failure(
        AppFailure(
          code: FailureCode.cliNotInstalled,
          message: 'missing',
        ),
      );
    };

    final result = await adapter.healthCheck();
    expect(result.failureOrNull?.code, FailureCode.cliNotInstalled);
  });
}
