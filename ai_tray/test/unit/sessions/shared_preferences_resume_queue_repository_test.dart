import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/logging/console_app_logger.dart';
import 'package:ai_tray/features/sessions/queue/data/repositories/shared_preferences_resume_queue_repository.dart';
import 'package:ai_tray/features/sessions/queue/domain/models/resume_queue_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferencesResumeQueueRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repository = SharedPreferencesResumeQueueRepository(
      prefs,
      logger: ConsoleAppLogger(defaultName: 'resume_queue_repo_test'),
    );
  });

  test('list() is empty for a fresh install', () async {
    final result = await repository.list();

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, isEmpty);
  });

  test('enqueue() adds an item that list() then returns', () async {
    final enqueueResult = await repository.enqueue(
      sessionId: 'abc',
      cwd: '/home/claude/proj',
      prompt: 'continue',
      maxBudgetUsd: 2,
    );

    expect(enqueueResult.isSuccess, isTrue);
    final item = enqueueResult.valueOrNull!;
    expect(item.status, ResumeQueueStatus.pending);
    expect(item.forkSession, isTrue);

    final listResult = await repository.list();
    expect(listResult.valueOrNull!.single.id, item.id);
  });

  test('persists across repository instances sharing the same prefs', () async {
    await repository.enqueue(
      sessionId: 'abc',
      cwd: '/home/claude/proj',
      prompt: 'continue',
      maxBudgetUsd: 2,
    );

    final prefs = await SharedPreferences.getInstance();
    final reloaded = SharedPreferencesResumeQueueRepository(
      prefs,
      logger: ConsoleAppLogger(defaultName: 'resume_queue_repo_test'),
    );

    final result = await reloaded.list();
    expect(result.valueOrNull, hasLength(1));
  });

  test('constructing an item without a positive budget cap throws '
      'ArgumentError', () async {
    await expectLater(
      repository.enqueue(
        sessionId: 'abc',
        cwd: '/home/claude/proj',
        prompt: 'continue',
        maxBudgetUsd: 0,
      ),
      throwsArgumentError,
    );
  });

  test('updateStatus updates only the matching item', () async {
    final a = (await repository.enqueue(
      sessionId: 'a',
      cwd: '/x',
      prompt: 'p',
      maxBudgetUsd: 1,
    )).valueOrNull!;
    final b = (await repository.enqueue(
      sessionId: 'b',
      cwd: '/x',
      prompt: 'p',
      maxBudgetUsd: 1,
    )).valueOrNull!;

    await repository.updateStatus(a.id, status: ResumeQueueStatus.running);

    final items = (await repository.list()).valueOrNull!;
    final updatedA = items.firstWhere((i) => i.id == a.id);
    final untouchedB = items.firstWhere((i) => i.id == b.id);
    expect(updatedA.status, ResumeQueueStatus.running);
    expect(untouchedB.status, ResumeQueueStatus.pending);
  });

  test('remove() deletes only the matching item', () async {
    final a = (await repository.enqueue(
      sessionId: 'a',
      cwd: '/x',
      prompt: 'p',
      maxBudgetUsd: 1,
    )).valueOrNull!;
    await repository.enqueue(
      sessionId: 'b',
      cwd: '/x',
      prompt: 'p',
      maxBudgetUsd: 1,
    );

    await repository.remove(a.id);

    final items = (await repository.list()).valueOrNull!;
    expect(items.map((i) => i.sessionId), ['b']);
  });

  test(
    'cancel() marks a pending item cancelled instead of deleting it',
    () async {
      final a = (await repository.enqueue(
        sessionId: 'a',
        cwd: '/x',
        prompt: 'p',
        maxBudgetUsd: 1,
      )).valueOrNull!;

      await repository.cancel(a.id);

      final items = (await repository.list()).valueOrNull!;
      expect(items, hasLength(1));
      expect(items.single.status, ResumeQueueStatus.cancelled);
    },
  );

  test(
    'evicts the oldest succeeded/failed item first when the bounded list '
    'is full',
    () async {
      // Fill to capacity with already-completed items (oldest first).
      for (var i = 0; i < SharedPreferencesResumeQueueRepository.maxSize; i++) {
        final added = (await repository.enqueue(
          sessionId: 'session-$i',
          cwd: '/x',
          prompt: 'p',
          maxBudgetUsd: 1,
        )).valueOrNull!;
        await repository.updateStatus(
          added.id,
          status: ResumeQueueStatus.succeeded,
        );
      }

      final enqueueResult = await repository.enqueue(
        sessionId: 'newest',
        cwd: '/x',
        prompt: 'p',
        maxBudgetUsd: 1,
      );

      expect(enqueueResult.isSuccess, isTrue);
      final items = (await repository.list()).valueOrNull!;
      expect(items, hasLength(SharedPreferencesResumeQueueRepository.maxSize));
      expect(
        items.map((i) => i.sessionId),
        isNot(contains('session-0')),
      );
      expect(items.map((i) => i.sessionId), contains('newest'));
    },
  );

  test(
    'fails fast — never evicts a pending/running item — when the bounded '
    'list is full with nothing eligible to evict',
    () async {
      for (var i = 0; i < SharedPreferencesResumeQueueRepository.maxSize; i++) {
        await repository.enqueue(
          sessionId: 'session-$i',
          cwd: '/x',
          prompt: 'p',
          maxBudgetUsd: 1,
        );
      }

      final enqueueResult = await repository.enqueue(
        sessionId: 'overflow',
        cwd: '/x',
        prompt: 'p',
        maxBudgetUsd: 1,
      );

      expect(enqueueResult.isFailure, isTrue);
      final items = (await repository.list()).valueOrNull!;
      expect(items, hasLength(SharedPreferencesResumeQueueRepository.maxSize));
      expect(items.map((i) => i.sessionId), isNot(contains('overflow')));
    },
  );

  test(
    'a malformed stored item (missing budget cap) is skipped, not fatal '
    'to list()',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'resume_queue_v1',
        '[{"id":"bad","sessionId":"x","cwd":"/x","prompt":"p",'
            '"createdAt":"2026-07-31T00:00:00.000Z"}]',
      );

      final result = await repository.list();

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isEmpty);
    },
  );

  test('a non-JSON stored value maps to cacheUnavailable', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('resume_queue_v1', 'not-json{{{');

    final result = await repository.list();

    expect(result.failureOrNull?.code, FailureCode.cacheUnavailable);
  });
}
