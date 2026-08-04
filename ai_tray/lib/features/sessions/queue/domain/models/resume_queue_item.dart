import 'package:ai_tray/features/sessions/domain/models/resume_outcome.dart';
import 'package:ai_tray/features/sessions/domain/models/session_token_totals.dart';
import 'package:meta/meta.dart';

/// Lifecycle of one queued resume (§8 of
/// `docs/planning/v2-vision-and-roadmap.md`).
enum ResumeQueueStatus { pending, running, succeeded, failed }

/// One unattended (or queued-but-attended) resume request (§8). Lives in
/// the `queue/` subdomain — used only there, unlike `ResumeOutcome` which
/// is shared with `resume/`.
@immutable
final class ResumeQueueItem {
  /// Validates the mandatory budget cap synchronously — mirrors
  /// `AppSettings`'s constructor-level `ArgumentError` pattern (design
  /// principle 2: "there is no 'run without a cap' path"). Used for
  /// **new** items (the enqueue path). For deserializing a previously
  /// stored item that might be missing this field, use [tryFromJson]
  /// instead, which degrades instead of throwing.
  factory ResumeQueueItem({
    required String id,
    required String sessionId,
    required String cwd,
    required String prompt,
    required double maxBudgetUsd,
    required DateTime createdAt,
    bool forkSession = true,
    ResumeQueueStatus status = ResumeQueueStatus.pending,
    DateTime? executedAt,
    ResumeOutcome? result,
  }) {
    if (maxBudgetUsd <= 0 || maxBudgetUsd.isNaN) {
      throw ArgumentError.value(
        maxBudgetUsd,
        'maxBudgetUsd',
        'a positive budget cap is mandatory for a queued resume',
      );
    }
    return ResumeQueueItem._(
      id: id,
      sessionId: sessionId,
      cwd: cwd,
      prompt: prompt,
      maxBudgetUsd: maxBudgetUsd,
      createdAt: createdAt,
      forkSession: forkSession,
      status: status,
      executedAt: executedAt,
      result: result,
    );
  }

  const ResumeQueueItem._({
    required this.id,
    required this.sessionId,
    required this.cwd,
    required this.prompt,
    required this.maxBudgetUsd,
    required this.createdAt,
    required this.forkSession,
    required this.status,
    this.executedAt,
    this.result,
  });

  /// App-generated, unique within this device's stored queue.
  final String id;
  final String sessionId;

  /// Working directory the resume runs in. Checked for existence
  /// immediately before execution (design principle 2) — never created
  /// or substituted if missing.
  final String cwd;
  final String prompt;

  /// Mandatory — see the constructor's own validation.
  final double maxBudgetUsd;

  /// Defaults `true` (fork) for anything auto-executed; `false` only for
  /// items created via the attended "Resume now" action (design
  /// principle 2 — unattended execution never silently mutates a
  /// transcript the user might be continuing elsewhere by hand).
  final bool forkSession;

  final ResumeQueueStatus status;
  final DateTime createdAt;
  final DateTime? executedAt;
  final ResumeOutcome? result;

  ResumeQueueItem copyWith({
    ResumeQueueStatus? status,
    DateTime? executedAt,
    ResumeOutcome? result,
  }) {
    return ResumeQueueItem._(
      id: id,
      sessionId: sessionId,
      cwd: cwd,
      prompt: prompt,
      maxBudgetUsd: maxBudgetUsd,
      createdAt: createdAt,
      forkSession: forkSession,
      status: status ?? this.status,
      executedAt: executedAt ?? this.executedAt,
      result: result ?? this.result,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'cwd': cwd,
      'prompt': prompt,
      'maxBudgetUsd': maxBudgetUsd,
      'forkSession': forkSession,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'executedAt': executedAt?.toIso8601String(),
      if (result != null)
        'result': {
          'sessionId': result!.sessionId,
          'isError': result!.isError,
          'costUsd': result!.costUsd,
          'numTurns': result!.numTurns,
          'stopReason': result!.stopReason,
          'resultText': result!.resultText,
          'tokens': {
            'inputTokens': result!.tokens.inputTokens,
            'outputTokens': result!.tokens.outputTokens,
            'cacheCreationInputTokens': result!.tokens.cacheCreationInputTokens,
            'cacheReadInputTokens': result!.tokens.cacheReadInputTokens,
          },
        },
    };
  }

  /// Tolerant deserialization for a previously stored item (§9's
  /// tolerate-and-degrade discipline). Returns `null` — never throws —
  /// when a required field (including the mandatory budget cap) is
  /// missing or malformed; the repository logs a
  /// `FailureCode.budgetCapRequired` warning and skips that one item
  /// rather than failing the whole `list()` call.
  static ResumeQueueItem? tryFromJson(Map<String, Object?> json) {
    final id = json['id'];
    final sessionId = json['sessionId'];
    final cwd = json['cwd'];
    final prompt = json['prompt'];
    final maxBudgetUsd = json['maxBudgetUsd'];
    final createdAtRaw = json['createdAt'];
    if (id is! String ||
        sessionId is! String ||
        cwd is! String ||
        prompt is! String ||
        maxBudgetUsd is! num ||
        maxBudgetUsd <= 0 ||
        createdAtRaw is! String) {
      return null;
    }
    final createdAt = DateTime.tryParse(createdAtRaw);
    if (createdAt == null) return null;

    final statusName = json['status'];
    ResumeQueueStatus? status;
    for (final candidate in ResumeQueueStatus.values) {
      if (candidate.name == statusName) {
        status = candidate;
        break;
      }
    }
    final executedAtRaw = json['executedAt'];
    final executedAt = executedAtRaw is String
        ? DateTime.tryParse(executedAtRaw)
        : null;
    final resultJson = json['result'];

    return ResumeQueueItem._(
      id: id,
      sessionId: sessionId,
      cwd: cwd,
      prompt: prompt,
      maxBudgetUsd: maxBudgetUsd.toDouble(),
      createdAt: createdAt,
      forkSession: json['forkSession'] == true,
      status: status ?? ResumeQueueStatus.pending,
      executedAt: executedAt,
      result: resultJson is Map<String, Object?>
          ? _tryOutcomeFromJson(resultJson)
          : null,
    );
  }

  static ResumeOutcome? _tryOutcomeFromJson(Map<String, Object?> json) {
    final sessionId = json['sessionId'];
    final resultText = json['resultText'];
    if (sessionId is! String || resultText is! String) return null;
    final tokensJson = json['tokens'];
    final tokens = tokensJson is Map<String, Object?>
        ? SessionTokenTotals(
            inputTokens: _asInt(tokensJson['inputTokens']),
            outputTokens: _asInt(tokensJson['outputTokens']),
            cacheCreationInputTokens: _asInt(
              tokensJson['cacheCreationInputTokens'],
            ),
            cacheReadInputTokens: _asInt(tokensJson['cacheReadInputTokens']),
          )
        : const SessionTokenTotals();
    return ResumeOutcome(
      sessionId: sessionId,
      isError: json['isError'] == true,
      costUsd: _asDouble(json['costUsd']),
      tokens: tokens,
      numTurns: _asInt(json['numTurns']),
      stopReason: json['stopReason'] as String?,
      resultText: resultText,
    );
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  static double _asDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return 0;
  }

  @override
  bool operator ==(Object other) {
    return other is ResumeQueueItem &&
        other.id == id &&
        other.sessionId == sessionId &&
        other.cwd == cwd &&
        other.prompt == prompt &&
        other.maxBudgetUsd == maxBudgetUsd &&
        other.forkSession == forkSession &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.executedAt == executedAt &&
        other.result == result;
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    cwd,
    prompt,
    maxBudgetUsd,
    forkSession,
    status,
    createdAt,
    Object.hash(executedAt, result),
  );

  @override
  String toString() =>
      'ResumeQueueItem(id: $id, sessionId: $sessionId, status: $status)';
}
