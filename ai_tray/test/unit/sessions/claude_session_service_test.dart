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

  group('resume', () {
    test('builds the confirmed --resume grammar', () async {
      runner.handler = (exe, args) {
        expect(exe, 'claude');
        expect(args, [
          '--resume',
          'abc123',
          '-p',
          'continue',
          '--output-format',
          'json',
        ]);
        return const Result.success(
          ProcessRunResult(
            exitCode: 0,
            stdout: '{}',
            stderr: '',
            duration: Duration.zero,
          ),
        );
      };

      await service.resume(
        sessionId: 'abc123',
        prompt: 'continue',
        workingDirectory: '/home/claude/proj',
      );
    });

    test(
      'passes workingDirectory and a generous, non-default timeout through '
      'to the process runner',
      () async {
        runner.handler = (exe, args) {
          return const Result.success(
            ProcessRunResult(
              exitCode: 0,
              stdout: '{}',
              stderr: '',
              duration: Duration.zero,
            ),
          );
        };

        await service.resume(
          sessionId: 'abc123',
          prompt: 'continue',
          workingDirectory: '/home/claude/proj',
        );

        final call = runner.calls.single;
        expect(call.workingDirectory, '/home/claude/proj');
        expect(call.timeout, isNot(const Duration(seconds: 8)));
        expect(call.timeout, greaterThan(const Duration(minutes: 1)));
      },
    );

    test('includes --fork-session only when forkSession is true', () async {
      runner.handler = (exe, args) {
        expect(args, contains('--fork-session'));
        return const Result.success(
          ProcessRunResult(
            exitCode: 0,
            stdout: '{}',
            stderr: '',
            duration: Duration.zero,
          ),
        );
      };

      await service.resume(
        sessionId: 'abc123',
        prompt: 'continue',
        workingDirectory: '/home/claude/proj',
        forkSession: true,
      );
    });

    test('omits --fork-session for the attended default', () async {
      runner.handler = (exe, args) {
        expect(args, isNot(contains('--fork-session')));
        return const Result.success(
          ProcessRunResult(
            exitCode: 0,
            stdout: '{}',
            stderr: '',
            duration: Duration.zero,
          ),
        );
      };

      await service.resume(
        sessionId: 'abc123',
        prompt: 'continue',
        workingDirectory: '/home/claude/proj',
      );
    });

    test('includes --max-budget-usd only when a cap is supplied', () async {
      runner.handler = (exe, args) {
        expect(args, containsAllInOrder(['--max-budget-usd', '2.5']));
        return const Result.success(
          ProcessRunResult(
            exitCode: 0,
            stdout: '{}',
            stderr: '',
            duration: Duration.zero,
          ),
        );
      };

      await service.resume(
        sessionId: 'abc123',
        prompt: 'continue',
        workingDirectory: '/home/claude/proj',
        maxBudgetUsd: 2.5,
      );
    });

    test('includes --fallback-model as a comma-joined list', () async {
      runner.handler = (exe, args) {
        expect(
          args,
          containsAllInOrder([
            '--fallback-model',
            'claude-opus-5,claude-sonnet-5',
          ]),
        );
        return const Result.success(
          ProcessRunResult(
            exitCode: 0,
            stdout: '{}',
            stderr: '',
            duration: Duration.zero,
          ),
        );
      };

      await service.resume(
        sessionId: 'abc123',
        prompt: 'continue',
        workingDirectory: '/home/claude/proj',
        fallbackModels: ['claude-opus-5', 'claude-sonnet-5'],
      );
    });

    test('parses cost, tokens, turns, stop reason, and result text', () async {
      runner.handler = (exe, args) {
        return Result.success(
          ProcessRunResult(
            exitCode: 0,
            stdout: jsonEncode({
              'is_error': false,
              'num_turns': 3,
              'stop_reason': 'end_turn',
              'session_id': 'abc123',
              'total_cost_usd': 0.042,
              'usage': {
                'input_tokens': 100,
                'output_tokens': 50,
                'cache_creation_input_tokens': 10,
                'cache_read_input_tokens': 5,
              },
              'result': 'Done — added the feature.',
              'type': 'result',
            }),
            stderr: '',
            duration: Duration.zero,
          ),
        );
      };

      final result = await service.resume(
        sessionId: 'abc123',
        prompt: 'continue',
        workingDirectory: '/home/claude/proj',
      );

      expect(result.isSuccess, isTrue);
      final outcome = result.valueOrNull!;
      expect(outcome.sessionId, 'abc123');
      expect(outcome.isError, isFalse);
      expect(outcome.costUsd, 0.042);
      expect(outcome.numTurns, 3);
      expect(outcome.stopReason, 'end_turn');
      expect(outcome.resultText, 'Done — added the feature.');
      expect(outcome.tokens.inputTokens, 100);
      expect(outcome.tokens.outputTokens, 50);
      expect(outcome.tokens.cacheCreationInputTokens, 10);
      expect(outcome.tokens.cacheReadInputTokens, 5);
    });

    test('a resume that completed with is_error still parses fully', () async {
      runner.handler = (exe, args) {
        return Result.success(
          ProcessRunResult(
            exitCode: 0,
            stdout: jsonEncode({
              'is_error': true,
              'num_turns': 1,
              'stop_reason': 'stop_sequence',
              'session_id': 'abc123',
              'total_cost_usd': 0,
              'usage': {'input_tokens': 0, 'output_tokens': 0},
              'result': 'Not logged in · Please run /login',
              'type': 'result',
            }),
            stderr: '',
            duration: Duration.zero,
          ),
        );
      };

      final result = await service.resume(
        sessionId: 'abc123',
        prompt: 'continue',
        workingDirectory: '/home/claude/proj',
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.isError, isTrue);
      expect(result.valueOrNull!.resultText, 'Not logged in · Please run /login');
    });

    test(
      'a bogus session id fails immediately with plain stderr, not JSON',
      () async {
        runner.handler = (exe, args) {
          return const Result.success(
            ProcessRunResult(
              exitCode: 1,
              stdout: '',
              stderr:
                  'No conversation found with session ID: '
                  '00000000-0000-0000-0000-000000000000',
              duration: Duration.zero,
            ),
          );
        };

        final result = await service.resume(
          sessionId: '00000000-0000-0000-0000-000000000000',
          prompt: 'continue',
          workingDirectory: '/home/claude/proj',
        );

        expect(result.failureOrNull?.code, FailureCode.processNonZeroExit);
      },
    );

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

      final result = await service.resume(
        sessionId: 'abc123',
        prompt: 'continue',
        workingDirectory: '/home/claude/proj',
      );

      expect(result.failureOrNull?.code, FailureCode.unknownCliOutput);
    });

    test('non-object JSON shape maps to unknownCliOutput', () async {
      runner.handler = (exe, args) {
        return const Result.success(
          ProcessRunResult(
            exitCode: 0,
            stdout: '[1,2,3]',
            stderr: '',
            duration: Duration.zero,
          ),
        );
      };

      final result = await service.resume(
        sessionId: 'abc123',
        prompt: 'continue',
        workingDirectory: '/home/claude/proj',
      );

      expect(result.failureOrNull?.code, FailureCode.unknownCliOutput);
    });

    test('a timeout is a handled failure, not a crash', () async {
      runner.handler = (exe, args) {
        return const Result.failure(
          AppFailure(code: FailureCode.timeout, message: 'timed out'),
        );
      };

      final result = await service.resume(
        sessionId: 'abc123',
        prompt: 'continue',
        workingDirectory: '/home/claude/proj',
      );

      expect(result.failureOrNull?.code, FailureCode.timeout);
    });

    test(
      'a process launch failure is a handled failure, not a crash',
      () async {
        runner.handler = (exe, args) {
          return const Result.failure(
            AppFailure(
              code: FailureCode.processLaunchFailed,
              message: 'could not start claude',
            ),
          );
        };

        final result = await service.resume(
          sessionId: 'abc123',
          prompt: 'continue',
          workingDirectory: '/home/claude/proj',
        );

        expect(result.failureOrNull?.code, FailureCode.processLaunchFailed);
      },
    );

    test('respects a custom executable path', () async {
      runner.handler = (exe, args) {
        expect(exe, '/opt/homebrew/bin/claude');
        return const Result.success(
          ProcessRunResult(
            exitCode: 0,
            stdout: '{}',
            stderr: '',
            duration: Duration.zero,
          ),
        );
      };

      await service.resume(
        sessionId: 'abc123',
        prompt: 'continue',
        workingDirectory: '/home/claude/proj',
        executablePath: '/opt/homebrew/bin/claude',
      );
    });
  });
}
