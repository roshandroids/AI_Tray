import 'package:ai_tray/features/sessions/domain/models/resume_outcome.dart';
import 'package:ai_tray/features/sessions/domain/models/session_token_totals.dart';
import 'package:ai_tray/features/sessions/queue/domain/models/resume_queue_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ResumeQueueItem item({double maxBudgetUsd = 2}) {
    return ResumeQueueItem(
      id: 'q1',
      sessionId: 'abc',
      cwd: '/home/claude/proj',
      prompt: 'continue',
      maxBudgetUsd: maxBudgetUsd,
      createdAt: DateTime.utc(2026, 7, 31),
    );
  }

  group('constructor budget cap validation', () {
    test('throws ArgumentError when maxBudgetUsd is missing a positive '
        'value (zero)', () {
      expect(() => item(maxBudgetUsd: 0), throwsArgumentError);
    });

    test('throws ArgumentError for a negative budget cap', () {
      expect(() => item(maxBudgetUsd: -1), throwsArgumentError);
    });

    test('throws ArgumentError for a NaN budget cap', () {
      expect(() => item(maxBudgetUsd: double.nan), throwsArgumentError);
    });

    test('accepts a positive budget cap', () {
      expect(item(maxBudgetUsd: 2.5).maxBudgetUsd, 2.5);
    });
  });

  test('forkSession defaults to true (unattended default)', () {
    expect(item().forkSession, isTrue);
  });

  test('status defaults to pending', () {
    expect(item().status, ResumeQueueStatus.pending);
  });

  test('copyWith updates status/executedAt/result without touching other '
      'fields', () {
    final original = item();
    const outcome = ResumeOutcome(
      sessionId: 'abc',
      isError: false,
      costUsd: 0.01,
      tokens: SessionTokenTotals(),
      numTurns: 1,
      resultText: 'done',
    );
    final updated = original.copyWith(
      status: ResumeQueueStatus.succeeded,
      executedAt: DateTime.utc(2026, 7, 31, 1),
      result: outcome,
    );

    expect(updated.status, ResumeQueueStatus.succeeded);
    expect(updated.executedAt, DateTime.utc(2026, 7, 31, 1));
    expect(updated.result, outcome);
    expect(updated.id, original.id);
    expect(updated.sessionId, original.sessionId);
    expect(updated.maxBudgetUsd, original.maxBudgetUsd);
  });

  group('JSON round-trip', () {
    test('toJson then tryFromJson reconstructs an equal item', () {
      final original = item();
      final roundTripped = ResumeQueueItem.tryFromJson(original.toJson());

      expect(roundTripped, original);
    });

    test('round-trips a completed item with a result', () {
      const outcome = ResumeOutcome(
        sessionId: 'abc',
        isError: false,
        costUsd: 0.042,
        tokens: SessionTokenTotals(
          inputTokens: 10,
          outputTokens: 5,
          cacheCreationInputTokens: 1,
          cacheReadInputTokens: 2,
        ),
        numTurns: 3,
        stopReason: 'end_turn',
        resultText: 'Done.',
      );
      final original = item().copyWith(
        status: ResumeQueueStatus.succeeded,
        executedAt: DateTime.utc(2026, 7, 31, 2),
        result: outcome,
      );

      final roundTripped = ResumeQueueItem.tryFromJson(original.toJson());

      expect(roundTripped, original);
      expect(roundTripped?.result?.tokens.inputTokens, 10);
    });

    test('tryFromJson returns null when maxBudgetUsd is missing — the '
        'read-path degrade case, not a throw', () {
      final json = item().toJson()..remove('maxBudgetUsd');

      expect(ResumeQueueItem.tryFromJson(json), isNull);
    });

    test('tryFromJson returns null when maxBudgetUsd is zero/invalid', () {
      final json = Map<String, Object?>.from(item().toJson());
      json['maxBudgetUsd'] = 0;

      expect(ResumeQueueItem.tryFromJson(json), isNull);
    });

    test('tryFromJson returns null when a required string field is '
        'missing', () {
      final json = item().toJson()..remove('sessionId');

      expect(ResumeQueueItem.tryFromJson(json), isNull);
    });

    test('tryFromJson returns null for an unparseable createdAt', () {
      final json = Map<String, Object?>.from(item().toJson());
      json['createdAt'] = 'not-a-date';

      expect(ResumeQueueItem.tryFromJson(json), isNull);
    });

    test('tryFromJson falls back to pending for an unrecognized status '
        'string', () {
      final json = Map<String, Object?>.from(item().toJson());
      json['status'] = 'unknown-status-from-a-newer-build';

      expect(
        ResumeQueueItem.tryFromJson(json)?.status,
        ResumeQueueStatus.pending,
      );
    });
  });
}
