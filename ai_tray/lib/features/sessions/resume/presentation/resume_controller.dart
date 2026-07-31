import 'package:ai_tray/core/logging/logging_providers.dart';
import 'package:ai_tray/features/sessions/domain/models/resume_outcome.dart';
import 'package:ai_tray/features/sessions/session_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

/// One completed "Resume now" attempt, tagged with the session it belongs
/// to. `ResumeController` is a single, app-wide instance (not keyed per
/// session — see its own doc comment), so the page reads this tag to
/// decide whether a stored outcome is actually *its* result, rather than a
/// stale one left over from a previously viewed session.
@immutable
final class ResumeAttempt {
  const ResumeAttempt({required this.sessionId, required this.outcome});

  final String sessionId;
  final ResumeOutcome outcome;
}

/// Drives the attended "Resume now" action from Session Detail (Feature
/// 2.2.1). Always resumes in place (`forkSession: false`) — attended,
/// human-watched resumes are the one case design principle 2 permits to
/// continue the original transcript rather than forking; unattended
/// execution (the queue executor, Feature 2.2.2) must fork by default.
///
/// A single `AsyncNotifier`, not a family provider: unlike
/// `sessionDetailProvider` (which *loads* per-id data automatically),
/// this is an imperative action — the session id is passed as an argument
/// to [resume], the same shape `SettingsNotifier.save(settings)` already
/// uses, so no per-argument provider is needed at all.
final class ResumeController extends AsyncNotifier<ResumeAttempt?> {
  @override
  Future<ResumeAttempt?> build() async => null;

  /// Runs the resume. `state.isLoading` guards against a second concurrent
  /// attempt, mirroring `SettingsNotifier.save()`'s same guard.
  Future<void> resume({
    required String sessionId,
    required String prompt,
    required String workingDirectory,
  }) async {
    if (state.isLoading) return;
    state = const AsyncLoading();

    final result = await ref
        .read(claudeSessionServiceProvider)
        .resume(
          sessionId: sessionId,
          prompt: prompt,
          workingDirectory: workingDirectory,
        );

    final failure = result.failureOrNull;
    if (failure != null) {
      ref
          .read(appLoggerProvider)
          .warning(
            'resume failed sessionId=$sessionId',
            name: 'resume',
            error: failure,
          );
      state = AsyncError(StateError(failure.message), StackTrace.current);
      return;
    }

    state = AsyncData(
      ResumeAttempt(sessionId: sessionId, outcome: result.valueOrNull!),
    );
  }
}

final resumeControllerProvider =
    AsyncNotifierProvider<ResumeController, ResumeAttempt?>(
      ResumeController.new,
    );
