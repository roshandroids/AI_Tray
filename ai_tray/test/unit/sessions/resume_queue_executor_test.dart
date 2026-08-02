import 'dart:convert';

import 'package:ai_tray/core/logging/console_app_logger.dart';
import 'package:ai_tray/core/notifications/fake_notification_gateway.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/providers/data/process/fake_process_runner.dart';
import 'package:ai_tray/features/providers/data/process/process_runner.dart';
import 'package:ai_tray/features/sessions/data/process/claude_session_service.dart';
import 'package:ai_tray/features/sessions/queue/data/repositories/fake_resume_queue_repository.dart';
import 'package:ai_tray/features/sessions/queue/data/services/resume_queue_executor.dart';
import 'package:ai_tray/features/sessions/queue/domain/models/resume_queue_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ResumeQueueItem pendingItem({String sessionId = 'abc', String cwd = '/x'}) {
    return ResumeQueueItem(
      id: 'q-$sessionId',
      sessionId: sessionId,
      cwd: cwd,
      prompt: 'continue',
      maxBudgetUsd: 2,
      createdAt: DateTime.utc(2026, 7, 31),
    );
  }

  ResumeQueueExecutor executor({
    required FakeResumeQueueRepository repository,
    required FakeProcessRunner runner,
    bool Function(String path)? directoryExists,
    FakeNotificationGateway? notificationGateway,
    void Function(String sessionId)? onOpenSessionDetail,
  }) {
    return ResumeQueueExecutor(
      repository: repository,
      sessionService: ClaudeSessionService(
        processRunner: runner,
        logger: ConsoleAppLogger(defaultName: 'resume_queue_executor_test'),
      ),
      logger: ConsoleAppLogger(defaultName: 'resume_queue_executor_test'),
      directoryExists: directoryExists ?? (_) => true,
      notificationGateway: notificationGateway ?? FakeNotificationGateway(),
      onOpenSessionDetail: onOpenSessionDetail,
    );
  }

  test('runs the oldest pending item and marks it succeeded', () async {
    final repository = FakeResumeQueueRepository(items: [pendingItem()]);
    final runner = FakeProcessRunner()
      ..handler = (exe, args) {
        expect(args, contains('--fork-session'));
        return Result.success(
          ProcessRunResult(
            exitCode: 0,
            stdout: jsonEncode({
              'is_error': false,
              'num_turns': 1,
              'session_id': 'abc',
              'total_cost_usd': 0.01,
              'usage': {'input_tokens': 1, 'output_tokens': 1},
              'result': 'done',
            }),
            stderr: '',
            duration: Duration.zero,
          ),
        );
      };

    await executor(repository: repository, runner: runner).runNext();

    final items = (await repository.list()).valueOrNull!;
    expect(items.single.status, ResumeQueueStatus.succeeded);
    expect(items.single.result?.resultText, 'done');
  });

  test('passes forkSession true through — the unattended default', () async {
    final repository = FakeResumeQueueRepository(items: [pendingItem()]);
    var sawForkFlag = false;
    final runner = FakeProcessRunner()
      ..handler = (exe, args) {
        sawForkFlag = args.contains('--fork-session');
        return Result.success(
          ProcessRunResult(
            exitCode: 0,
            stdout: jsonEncode({'session_id': 'abc'}),
            stderr: '',
            duration: Duration.zero,
          ),
        );
      };

    await executor(repository: repository, runner: runner).runNext();

    expect(sawForkFlag, isTrue);
  });

  test(
    'a stale cwd fails fast without ever calling the process runner',
    () async {
      final repository = FakeResumeQueueRepository(items: [pendingItem()]);
      final runner = FakeProcessRunner();

      await executor(
        repository: repository,
        runner: runner,
        directoryExists: (_) => false,
      ).runNext();

      expect(runner.calls, isEmpty);
      final items = (await repository.list()).valueOrNull!;
      expect(items.single.status, ResumeQueueStatus.failed);
    },
  );

  test('a resume failure marks the item failed, not succeeded', () async {
    final repository = FakeResumeQueueRepository(items: [pendingItem()]);
    final runner = FakeProcessRunner()
      ..handler = (exe, args) {
        return const Result.success(
          ProcessRunResult(
            exitCode: 1,
            stdout: '',
            stderr: 'boom',
            duration: Duration.zero,
          ),
        );
      };

    await executor(repository: repository, runner: runner).runNext();

    final items = (await repository.list()).valueOrNull!;
    expect(items.single.status, ResumeQueueStatus.failed);
  });

  test('does nothing when there is no pending item', () async {
    final repository = FakeResumeQueueRepository(
      items: [pendingItem().copyWith(status: ResumeQueueStatus.succeeded)],
    );
    final runner = FakeProcessRunner();

    await executor(repository: repository, runner: runner).runNext();

    expect(runner.calls, isEmpty);
  });

  test(
    'only one item executes at a time even if runNext is triggered twice '
    'concurrently',
    () async {
      final repository = FakeResumeQueueRepository(
        items: [
          pendingItem(sessionId: 'a'),
          pendingItem(sessionId: 'b'),
        ],
      );
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
      final resumeExecutor = executor(repository: repository, runner: runner);

      final first = resumeExecutor.runNext();
      final second = resumeExecutor.runNext();
      await first;
      await second;

      // The second concurrent call is a no-op (joins nothing, does
      // nothing new) — only the first call's single item executes.
      expect(callCount, 1);
    },
  );

  group('completion notifications (Feature 2.3.1)', () {
    test('notifies with an onClick on a successful completion', () async {
      final repository = FakeResumeQueueRepository(items: [pendingItem()]);
      final runner = FakeProcessRunner()
        ..handler = (exe, args) {
          return Result.success(
            ProcessRunResult(
              exitCode: 0,
              stdout: jsonEncode({'session_id': 'abc'}),
              stderr: '',
              duration: Duration.zero,
            ),
          );
        };
      final gateway = FakeNotificationGateway();

      await executor(
        repository: repository,
        runner: runner,
        notificationGateway: gateway,
      ).runNext();

      expect(gateway.calls, hasLength(1));
      expect(gateway.calls.single.onClick, isNotNull);
      expect(gateway.calls.single.body, contains('completed'));
    });

    test('notifies with an onClick on a failed completion too', () async {
      final repository = FakeResumeQueueRepository(items: [pendingItem()]);
      final runner = FakeProcessRunner()
        ..handler = (exe, args) {
          return const Result.success(
            ProcessRunResult(
              exitCode: 1,
              stdout: '',
              stderr: 'boom',
              duration: Duration.zero,
            ),
          );
        };
      final gateway = FakeNotificationGateway();

      await executor(
        repository: repository,
        runner: runner,
        notificationGateway: gateway,
      ).runNext();

      expect(gateway.calls, hasLength(1));
      expect(gateway.calls.single.onClick, isNotNull);
      expect(gateway.calls.single.body, contains('failed'));
    });

    test('notifies on a stale-cwd fast failure too', () async {
      final repository = FakeResumeQueueRepository(items: [pendingItem()]);
      final gateway = FakeNotificationGateway();

      await executor(
        repository: repository,
        runner: FakeProcessRunner(),
        directoryExists: (_) => false,
        notificationGateway: gateway,
      ).runNext();

      expect(gateway.calls, hasLength(1));
    });

    test(
      'invoking onClick calls onOpenSessionDetail with the completed '
      "item's session id",
      () async {
        final repository = FakeResumeQueueRepository(
          items: [pendingItem(sessionId: 'the-right-session')],
        );
        final runner = FakeProcessRunner()
          ..handler = (exe, args) {
            return Result.success(
              ProcessRunResult(
                exitCode: 0,
                stdout: jsonEncode({'session_id': 'the-right-session'}),
                stderr: '',
                duration: Duration.zero,
              ),
            );
          };
        final gateway = FakeNotificationGateway();
        String? openedSessionId;

        await executor(
          repository: repository,
          runner: runner,
          notificationGateway: gateway,
          onOpenSessionDetail: (sessionId) => openedSessionId = sessionId,
        ).runNext();
        gateway.calls.single.onClick!();

        expect(openedSessionId, 'the-right-session');
      },
    );

    test('does not notify when there is no pending item', () async {
      final repository = FakeResumeQueueRepository(
        items: [pendingItem().copyWith(status: ResumeQueueStatus.succeeded)],
      );
      final gateway = FakeNotificationGateway();

      await executor(
        repository: repository,
        runner: FakeProcessRunner(),
        notificationGateway: gateway,
      ).runNext();

      expect(gateway.calls, isEmpty);
    });
  });
}
