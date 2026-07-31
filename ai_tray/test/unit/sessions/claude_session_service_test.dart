import 'dart:convert';

import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/logging/console_app_logger.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/providers/data/process/fake_process_runner.dart';
import 'package:ai_tray/features/providers/data/process/process_runner.dart';
import 'package:ai_tray/features/sessions/data/process/claude_session_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeProcessRunner runner;
  late ClaudeSessionService service;

  setUp(() {
    runner = FakeProcessRunner();
    service = ClaudeSessionService(
      processRunner: runner,
      logger: ConsoleAppLogger(defaultName: 'claude_session_service_test'),
    );
  });

  test('calls agents --json --all', () async {
    runner.handler = (exe, args) {
      expect(exe, 'claude');
      expect(args, ['agents', '--json', '--all']);
      return const Result.success(
        ProcessRunResult(
          exitCode: 0,
          stdout: '[]',
          stderr: '',
          duration: Duration.zero,
        ),
      );
    };

    await service.listLiveSessions();
  });

  test('successful enrichment extracts session ids', () async {
    runner.handler = (exe, args) {
      return Result.success(
        ProcessRunResult(
          exitCode: 0,
          stdout: jsonEncode([
            {'sessionId': 'abc123', 'model': 'claude-x'},
            {'session_id': 'def456'},
            {'id': 'ghi789'},
          ]),
          stderr: '',
          duration: Duration.zero,
        ),
      );
    };

    final result = await service.listLiveSessions();
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, {'abc123', 'def456', 'ghi789'});
  });

  test('empty result returns an empty set, not a failure', () async {
    runner.handler = (exe, args) {
      return const Result.success(
        ProcessRunResult(
          exitCode: 0,
          stdout: '[]',
          stderr: '',
          duration: Duration.zero,
        ),
      );
    };

    final result = await service.listLiveSessions();
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, isEmpty);
  });

  test('malformed JSON maps to unknownCliOutput, never throws', () async {
    runner.handler = (exe, args) {
      return const Result.success(
        ProcessRunResult(
          exitCode: 0,
          stdout: 'not-json{{{',
          stderr: '',
          duration: Duration.zero,
        ),
      );
    };

    final result = await service.listLiveSessions();
    expect(result.failureOrNull?.code, FailureCode.unknownCliOutput);
  });

  test('non-list JSON shape maps to unknownCliOutput', () async {
    runner.handler = (exe, args) {
      return const Result.success(
        ProcessRunResult(
          exitCode: 0,
          stdout: '{"unexpected": "shape"}',
          stderr: '',
          duration: Duration.zero,
        ),
      );
    };

    final result = await service.listLiveSessions();
    expect(result.failureOrNull?.code, FailureCode.unknownCliOutput);
  });

  test('unknown/unrecognized fields on an entry are skipped, not fatal', () async {
    runner.handler = (exe, args) {
      return Result.success(
        ProcessRunResult(
          exitCode: 0,
          stdout: jsonEncode([
            {'unexpectedField': 'no id here'},
            'not-even-a-map',
            42,
            {'sessionId': 'kept-one'},
          ]),
          stderr: '',
          duration: Duration.zero,
        ),
      );
    };

    final result = await service.listLiveSessions();
    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, {'kept-one'});
  });

  test('timeout is reported as a failure, not thrown', () async {
    runner.handler = (exe, args) {
      return const Result.failure(
        AppFailure(code: FailureCode.timeout, message: 'timed out'),
      );
    };

    final result = await service.listLiveSessions();
    expect(result.failureOrNull?.code, FailureCode.timeout);
  });

  test('process launch failure is reported as a failure, not thrown', () async {
    runner.handler = (exe, args) {
      return const Result.failure(
        AppFailure(
          code: FailureCode.processLaunchFailed,
          message: 'could not start claude',
        ),
      );
    };

    final result = await service.listLiveSessions();
    expect(result.failureOrNull?.code, FailureCode.processLaunchFailed);
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

    final result = await service.listLiveSessions();
    expect(result.failureOrNull?.code, FailureCode.processNonZeroExit);
  });

  test('respects a custom executable path', () async {
    runner.handler = (exe, args) {
      expect(exe, '/opt/homebrew/bin/claude');
      return const Result.success(
        ProcessRunResult(
          exitCode: 0,
          stdout: '[]',
          stderr: '',
          duration: Duration.zero,
        ),
      );
    };

    await service.listLiveSessions(executablePath: '/opt/homebrew/bin/claude');
  });
}
