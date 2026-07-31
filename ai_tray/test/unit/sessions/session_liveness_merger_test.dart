import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/sessions/data/process/session_liveness_merger.dart';
import 'package:ai_tray/features/sessions/domain/models/session_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  SessionSummary summaryFor(String sessionId) {
    return SessionSummary(
      sessionId: sessionId,
      sanitizedProjectDirName: '-home-claude-testproj',
      lastActivityAt: DateTime.utc(2026, 7, 31),
      messageCount: 3,
    );
  }

  test('successful liveness marks matching ids live, others not live', () {
    final summaries = [summaryFor('live-one'), summaryFor('not-live')];

    final merged = mergeSessionLiveness(
      summaries,
      const Result.success({'live-one'}),
    );

    expect(merged[0].isLive, isTrue);
    expect(merged[1].isLive, isFalse);
  });

  test(
    'failed liveness leaves the summary list unchanged — Browser still '
    'renders fully from JSONL alone',
    () {
      final summaries = [summaryFor('a'), summaryFor('b')];

      final merged = mergeSessionLiveness(
        summaries,
        const Result.failure(
          AppFailure(code: FailureCode.timeout, message: 'timed out'),
        ),
      );

      expect(merged, summaries);
      expect(merged.every((s) => s.isLive == null), isTrue);
    },
  );

  test('is pure — does not mutate the input list or its elements', () {
    final summaries = [summaryFor('a'), summaryFor('b')];
    final originalFirst = summaries.first;

    mergeSessionLiveness(summaries, const Result.success({'a'}));

    expect(summaries.first, same(originalFirst));
    expect(summaries.first.isLive, isNull);
  });

  test('is deterministic — same inputs produce equal outputs', () {
    final summaries = [summaryFor('a'), summaryFor('b')];
    const liveness = Result<Set<String>>.success({'a'});

    final first = mergeSessionLiveness(summaries, liveness);
    final second = mergeSessionLiveness(summaries, liveness);

    expect(first, second);
  });

  test('empty summary list stays empty regardless of liveness shape', () {
    expect(
      mergeSessionLiveness(const [], const Result.success({'x'})),
      isEmpty,
    );
    expect(
      mergeSessionLiveness(
        const [],
        const Result.failure(
          AppFailure(code: FailureCode.unknownCliOutput, message: 'bad'),
        ),
      ),
      isEmpty,
    );
  });
}
