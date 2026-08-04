import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/features/sessions/queue/data/repositories/fake_resume_queue_repository.dart';
import 'package:ai_tray/features/sessions/queue/domain/models/resume_queue_item.dart';
import 'package:ai_tray/features/sessions/queue/presentation/resume_queue_controller.dart';
import 'package:ai_tray/features/sessions/queue/queue_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ProviderContainer container(FakeResumeQueueRepository repository) {
    return ProviderContainer(
      overrides: [
        resumeQueueRepositoryProvider.overrideWithValue(repository),
      ],
    );
  }

  test('build() populates state from the repository', () async {
    final repository = FakeResumeQueueRepository(
      items: [
        ResumeQueueItem(
          id: 'q1',
          sessionId: 'abc',
          cwd: '/x',
          prompt: 'continue',
          maxBudgetUsd: 1,
          createdAt: DateTime.utc(2026, 7, 31),
        ),
      ],
    );
    final ref = container(repository);
    addTearDown(ref.dispose);

    final result = await ref.read(resumeQueueControllerProvider.future);

    expect(result.single.sessionId, 'abc');
  });

  test('enqueue() adds an item and refreshes the list', () async {
    final repository = FakeResumeQueueRepository();
    final ref = container(repository);
    addTearDown(ref.dispose);
    await ref.read(resumeQueueControllerProvider.future);

    final ok = await ref
        .read(resumeQueueControllerProvider.notifier)
        .enqueue(
          sessionId: 'abc',
          cwd: '/x',
          prompt: 'continue',
          maxBudgetUsd: 2,
        );

    expect(ok, isTrue);
    expect(ref.read(resumeQueueControllerProvider).value, hasLength(1));
  });

  test('enqueue() returns false, without throwing, on a repository '
      'failure', () async {
    final repository = FakeResumeQueueRepository()
      ..enqueueFailure = FailureCode.unknown;
    final ref = container(repository);
    addTearDown(ref.dispose);
    await ref.read(resumeQueueControllerProvider.future);

    final ok = await ref
        .read(resumeQueueControllerProvider.notifier)
        .enqueue(
          sessionId: 'abc',
          cwd: '/x',
          prompt: 'continue',
          maxBudgetUsd: 2,
        );

    expect(ok, isFalse);
  });

  test('build() surfaces a repository read failure as AsyncError', () async {
    final repository = FakeResumeQueueRepository()
      ..listFailure = FailureCode.cacheUnavailable;
    final ref = container(repository);
    addTearDown(ref.dispose);

    await expectLater(
      ref.read(resumeQueueControllerProvider.future),
      throwsA(isA<StateError>()),
    );
    expect(ref.read(resumeQueueControllerProvider).hasError, isTrue);
  });

  test('runNext() invokes the executor and refreshes the list', () async {
    final repository = FakeResumeQueueRepository(
      items: [
        ResumeQueueItem(
          id: 'q1',
          sessionId: 'abc',
          cwd: '/nonexistent-path-for-test',
          prompt: 'continue',
          maxBudgetUsd: 1,
          createdAt: DateTime.utc(2026, 7, 31),
        ),
      ],
    );
    final ref = container(repository);
    addTearDown(ref.dispose);
    await ref.read(resumeQueueControllerProvider.future);

    await ref.read(resumeQueueControllerProvider.notifier).runNext();

    // The executor fails fast on a missing cwd (no real process spawned),
    // marking the item failed — confirms runNext() actually drove the
    // executor and then reloaded the list from the repository.
    final items = ref.read(resumeQueueControllerProvider).value!;
    expect(items.single.status, ResumeQueueStatus.failed);
  });
}
