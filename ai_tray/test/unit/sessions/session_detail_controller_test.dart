import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/features/sessions/data/repositories/fake_session_repository.dart';
import 'package:ai_tray/features/sessions/detail/presentation/session_detail_controller.dart';
import 'package:ai_tray/features/sessions/domain/models/claude_session.dart';
import 'package:ai_tray/features/sessions/domain/models/session_token_totals.dart';
import 'package:ai_tray/features/sessions/session_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ClaudeSession session(String id, {bool isComplete = true}) {
    return ClaudeSession(
      sessionId: id,
      sanitizedProjectDirName: '-home-claude-proj',
      messageCount: 4,
      tokenTotals: const SessionTokenTotals(inputTokens: 10, outputTokens: 5),
      isComplete: isComplete,
      model: 'claude-x',
      gitBranch: 'main',
    );
  }

  ProviderContainer container(FakeSessionRepository repository) {
    return ProviderContainer(
      overrides: [
        sessionRepositoryProvider.overrideWithValue(repository),
      ],
    );
  }

  test('loads and exposes the session for its id', () async {
    final repository = FakeSessionRepository()..setSession(session('abc'));
    final ref = container(repository);
    addTearDown(ref.dispose);

    final result = await ref.read(sessionDetailProvider('abc').future);

    expect(result.sessionId, 'abc');
    expect(result.model, 'claude-x');
  });

  test('is keyed independently per session id', () async {
    final repository = FakeSessionRepository()
      ..setSession(session('abc'))
      ..setSession(session('def'));
    final ref = container(repository);
    addTearDown(ref.dispose);

    final a = await ref.read(sessionDetailProvider('abc').future);
    final b = await ref.read(sessionDetailProvider('def').future);

    expect(a.sessionId, 'abc');
    expect(b.sessionId, 'def');
  });

  test(
    'surfaces sessionNotFound as a SessionLoadException carrying the code',
    () async {
      final repository = FakeSessionRepository()
        ..setSessionFailure('missing', FailureCode.sessionNotFound);
      final ref = container(repository);
      addTearDown(ref.dispose);

      await expectLater(
        ref.read(sessionDetailProvider('missing').future),
        throwsA(
          isA<SessionLoadException>().having(
            (e) => e.code,
            'code',
            FailureCode.sessionNotFound,
          ),
        ),
      );
    },
  );

  test(
    'surfaces other failures with their own code, not sessionNotFound',
    () async {
      final repository = FakeSessionRepository()
        ..setSessionFailure(
          'abc',
          FailureCode.unknown,
          message: 'disk error',
        );
      final ref = container(repository);
      addTearDown(ref.dispose);

      await expectLater(
        ref.read(sessionDetailProvider('abc').future),
        throwsA(
          isA<SessionLoadException>()
              .having((e) => e.code, 'code', FailureCode.unknown)
              .having((e) => e.message, 'message', 'disk error'),
        ),
      );
    },
  );
}
