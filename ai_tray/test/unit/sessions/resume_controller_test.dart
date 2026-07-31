import 'dart:convert';

import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/logging/console_app_logger.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/providers/data/process/fake_process_runner.dart';
import 'package:ai_tray/features/providers/data/process/process_runner.dart';
import 'package:ai_tray/features/sessions/data/process/claude_session_service.dart';
import 'package:ai_tray/features/sessions/resume/presentation/resume_controller.dart';
import 'package:ai_tray/features/sessions/session_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ProviderContainer container(FakeProcessRunner runner) {
    return ProviderContainer(
      overrides: [
        claudeSessionServiceProvider.overrideWithValue(
          ClaudeSessionService(
            processRunner: runner,
            logger: ConsoleAppLogger(defaultName: 'resume_controller_test'),
          ),
        ),
      ],
    );
  }

  test(
    'resume() populates state with the outcome, tagged by session id',
    () async {
      final runner = FakeProcessRunner()
        ..handler = (exe, args) {
          expect(args, isNot(contains('--fork-session')));
          return Result.success(
            ProcessRunResult(
              exitCode: 0,
              stdout: jsonEncode({
                'is_error': false,
                'num_turns': 2,
                'stop_reason': 'end_turn',
                'session_id': 'abc',
                'total_cost_usd': 0.01,
                'usage': {'input_tokens': 5, 'output_tokens': 3},
                'result': 'done',
              }),
              stderr: '',
              duration: Duration.zero,
            ),
          );
        };
      final ref = container(runner);
      addTearDown(ref.dispose);
      await ref.read(resumeControllerProvider.future);

      await ref
          .read(resumeControllerProvider.notifier)
          .resume(
            sessionId: 'abc',
            prompt: 'continue',
            workingDirectory: '/x',
          );

      final state = ref.read(resumeControllerProvider);
      expect(state.hasError, isFalse);
      expect(state.value?.sessionId, 'abc');
      expect(state.value?.outcome.numTurns, 2);
      expect(state.value?.outcome.resultText, 'done');
    },
  );

  test(
    'a resume failure surfaces as AsyncError, not a thrown exception',
    () async {
      final runner = FakeProcessRunner()
        ..handler = (exe, args) {
          return const Result.failure(
            AppFailure(code: FailureCode.timeout, message: 'timed out'),
          );
        };
      final ref = container(runner);
      addTearDown(ref.dispose);
      await ref.read(resumeControllerProvider.future);

      await ref
          .read(resumeControllerProvider.notifier)
          .resume(
            sessionId: 'abc',
            prompt: 'continue',
            workingDirectory: '/x',
          );

      final state = ref.read(resumeControllerProvider);
      expect(state.hasError, isTrue);
    },
  );

  test('resume() is a no-op while already in flight', () async {
    var callCount = 0;
    final runner = FakeProcessRunner()
      ..handler = (exe, args) {
        callCount++;
        return Result.success(
          ProcessRunResult(
            exitCode: 0,
            stdout: jsonEncode({'session_id': 'abc'}),
            stderr: '',
            duration: Duration.zero,
          ),
        );
      };
    final ref = container(runner);
    addTearDown(ref.dispose);
    await ref.read(resumeControllerProvider.future);
    final notifier = ref.read(resumeControllerProvider.notifier);

    final first = notifier.resume(
      sessionId: 'abc',
      prompt: 'continue',
      workingDirectory: '/x',
    );
    final second = notifier.resume(
      sessionId: 'abc',
      prompt: 'another',
      workingDirectory: '/x',
    );
    await first;
    await second;

    expect(callCount, 1);
  });
}
