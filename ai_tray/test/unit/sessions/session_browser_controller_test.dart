import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/features/sessions/browser/presentation/session_browser_controller.dart';
import 'package:ai_tray/features/sessions/data/repositories/fake_session_repository.dart';
import 'package:ai_tray/features/sessions/domain/models/session_summary.dart';
import 'package:ai_tray/features/sessions/session_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  SessionSummary summary(String id) {
    return SessionSummary(
      sessionId: id,
      sanitizedProjectDirName: '-home-claude-proj',
      lastActivityAt: DateTime.utc(2026, 7, 31),
      messageCount: 2,
    );
  }

  ProviderContainer container(FakeSessionRepository repository) {
    return ProviderContainer(
      overrides: [
        sessionRepositoryProvider.overrideWithValue(repository),
      ],
    );
  }

  test('build() populates state from the repository', () async {
    final repository = FakeSessionRepository(
      sessions: [summary('a'), summary('b')],
    );
    final ref = container(repository);
    addTearDown(ref.dispose);

    final result = await ref.read(sessionBrowserControllerProvider.future);

    expect(result.map((s) => s.sessionId), ['a', 'b']);
    expect(repository.listSessionsCallCount, 1);
  });

  test('build() surfaces a repository failure as AsyncError', () async {
    final repository = FakeSessionRepository()
      ..setFailure(FailureCode.unknown, message: 'disk error');
    final ref = container(repository);
    addTearDown(ref.dispose);

    await expectLater(
      ref.read(sessionBrowserControllerProvider.future),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          'disk error',
        ),
      ),
    );
    expect(
      ref.read(sessionBrowserControllerProvider).hasError,
      isTrue,
    );
  });

  test('refresh() re-queries the repository and updates state', () async {
    final repository = FakeSessionRepository(sessions: [summary('a')]);
    final ref = container(repository);
    addTearDown(ref.dispose);
    await ref.read(sessionBrowserControllerProvider.future);
    expect(repository.listSessionsCallCount, 1);

    repository.setSessions([summary('a'), summary('b')]);
    await ref.read(sessionBrowserControllerProvider.notifier).refresh();

    expect(repository.listSessionsCallCount, 2);
    expect(
      ref.read(sessionBrowserControllerProvider).value?.map((s) => s.sessionId),
      ['a', 'b'],
    );
  });

  test('refresh() recovers from a prior error', () async {
    final repository = FakeSessionRepository()
      ..setFailure(FailureCode.timeout, message: 'timed out');
    final ref = container(repository);
    addTearDown(ref.dispose);
    await ref.read(sessionBrowserControllerProvider.future).catchError((_) {
      return <SessionSummary>[];
    });
    expect(ref.read(sessionBrowserControllerProvider).hasError, isTrue);

    repository.setSessions([summary('a')]);
    await ref.read(sessionBrowserControllerProvider.notifier).refresh();

    final state = ref.read(sessionBrowserControllerProvider);
    expect(state.hasError, isFalse);
    expect(state.value?.map((s) => s.sessionId), ['a']);
  });

  test('refresh() is a no-op while a load is already in flight', () async {
    final repository = FakeSessionRepository(sessions: [summary('a')]);
    final ref = container(repository);
    addTearDown(ref.dispose);
    await ref.read(sessionBrowserControllerProvider.future);

    repository.holdNextResponse();
    final notifier = ref.read(sessionBrowserControllerProvider.notifier);
    final first = notifier.refresh();
    final second = notifier.refresh();
    repository.releaseResponse();
    await first;
    await second;

    // Only the held call plus the guarded no-op — never two concurrent
    // in-flight loads.
    expect(repository.listSessionsCallCount, 2);
  });
}
