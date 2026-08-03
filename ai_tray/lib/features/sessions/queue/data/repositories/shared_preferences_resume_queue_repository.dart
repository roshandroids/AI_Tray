import 'dart:convert';

import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/logging/app_logger.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/sessions/domain/models/resume_outcome.dart';
import 'package:ai_tray/features/sessions/queue/domain/models/resume_queue_item.dart';
import 'package:ai_tray/features/sessions/queue/domain/repositories/resume_queue_repository.dart';
import 'package:ai_tray/features/usage/data/cache/usage_cache.dart' show Unit;
import 'package:shared_preferences/shared_preferences.dart';

/// Production [ResumeQueueRepository]: one JSON array under a single,
/// versioned `SharedPreferences` key — the same "read-modify-write full
/// list" shape `SharedPreferencesSettingsRepository` already proves,
/// adapted from per-field keys to one array key since a queue is a
/// variable-length list, not a fixed set of fields (§9).
final class SharedPreferencesResumeQueueRepository
    implements ResumeQueueRepository {
  SharedPreferencesResumeQueueRepository(
    this._prefs, {
    required AppLogger logger,
  }) : _logger = logger;

  static const _key = 'resume_queue_v1';

  /// Bounded per §9 ("e.g. 50 items — oldest completed items evicted
  /// first").
  static const maxSize = 50;

  final SharedPreferences _prefs;
  final AppLogger _logger;
  int _idCounter = 0;

  @override
  Future<Result<List<ResumeQueueItem>>> list() async {
    try {
      final raw = _prefs.getString(_key);
      if (raw == null || raw.isEmpty) return const Result.success([]);

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const Result.failure(
          AppFailure(
            code: FailureCode.cacheUnavailable,
            message: "Couldn't load the resume queue",
          ),
        );
      }

      final items = <ResumeQueueItem>[];
      for (final entry in decoded) {
        if (entry is! Map) continue;
        final item = ResumeQueueItem.tryFromJson(
          Map<String, Object?>.from(entry),
        );
        if (item == null) {
          // Tolerate-and-degrade (§9): a stored item missing its
          // mandatory budget cap (or another required field, e.g. an
          // older build's schema) is skipped, not fatal to the whole
          // list() call.
          _logger.warning(
            'skipping malformed resume queue item',
            name: 'resume_queue',
            error: const AppFailure(
              code: FailureCode.budgetCapRequired,
              message:
                  'Stored queue item is missing its mandatory budget cap '
                  'or another required field',
            ),
          );
          continue;
        }
        items.add(item);
      }
      return Result.success(items);
    } on FormatException {
      return const Result.failure(
        AppFailure(
          code: FailureCode.cacheUnavailable,
          message: "Couldn't load the resume queue",
        ),
      );
    } on Exception {
      return const Result.failure(
        AppFailure(
          code: FailureCode.cacheUnavailable,
          message: "Couldn't load the resume queue",
        ),
      );
    }
  }

  @override
  Future<Result<ResumeQueueItem>> enqueue({
    required String sessionId,
    required String cwd,
    required String prompt,
    required double maxBudgetUsd,
    bool forkSession = true,
  }) async {
    final listResult = await list();
    final listFailure = listResult.failureOrNull;
    if (listFailure != null) return Result.failure(listFailure);
    var items = listResult.valueOrNull ?? const <ResumeQueueItem>[];

    if (items.length >= maxSize) {
      final evictable =
          items
              .where(
                (i) =>
                    i.status == ResumeQueueStatus.succeeded ||
                    i.status == ResumeQueueStatus.failed,
              )
              .toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      if (evictable.isEmpty) {
        // Fail fast and surface — never silently evict a pending/running
        // item a user is still waiting on (§9, same rule as stale cwd).
        return const Result.failure(
          AppFailure(
            code: FailureCode.unknown,
            message:
                'Resume queue is full — remove a completed item or wait '
                'for one to finish before adding more.',
          ),
        );
      }
      final oldest = evictable.first;
      items = items.where((i) => i.id != oldest.id).toList();
    }

    final newItem = ResumeQueueItem(
      id: _generateId(),
      sessionId: sessionId,
      cwd: cwd,
      prompt: prompt,
      maxBudgetUsd: maxBudgetUsd,
      createdAt: DateTime.now().toUtc(),
      forkSession: forkSession,
    );

    final writeResult = await _writeAll([...items, newItem]);
    final writeFailure = writeResult.failureOrNull;
    if (writeFailure != null) return Result.failure(writeFailure);
    return Result.success(newItem);
  }

  @override
  Future<Result<Unit>> updateStatus(
    String id, {
    required ResumeQueueStatus status,
    DateTime? startedAt,
    DateTime? executedAt,
    ResumeOutcome? result,
  }) async {
    final listResult = await list();
    final listFailure = listResult.failureOrNull;
    if (listFailure != null) return Result.failure(listFailure);
    final items = listResult.valueOrNull ?? const <ResumeQueueItem>[];

    final updated = <ResumeQueueItem>[
      for (final item in items)
        if (item.id == id)
          item.copyWith(
            status: status,
            startedAt: startedAt,
            executedAt: executedAt,
            result: result,
          )
        else
          item,
    ];
    return _writeAll(updated);
  }

  @override
  Future<Result<Unit>> remove(String id) async {
    final listResult = await list();
    final listFailure = listResult.failureOrNull;
    if (listFailure != null) return Result.failure(listFailure);
    final items = listResult.valueOrNull ?? const <ResumeQueueItem>[];
    return _writeAll(items.where((i) => i.id != id).toList());
  }

  @override
  Future<Result<Unit>> retry(String id) async {
    final listResult = await list();
    final listFailure = listResult.failureOrNull;
    if (listFailure != null) return Result.failure(listFailure);
    final items = listResult.valueOrNull ?? const <ResumeQueueItem>[];

    final updated = <ResumeQueueItem>[
      for (final item in items)
        if (item.id == id)
          ResumeQueueItem(
            id: item.id,
            sessionId: item.sessionId,
            cwd: item.cwd,
            prompt: item.prompt,
            maxBudgetUsd: item.maxBudgetUsd,
            createdAt: item.createdAt,
            forkSession: item.forkSession,
          )
        else
          item,
    ];
    return _writeAll(updated);
  }

  Future<Result<Unit>> _writeAll(List<ResumeQueueItem> items) async {
    try {
      final encoded = jsonEncode(items.map((i) => i.toJson()).toList());
      final saved = await _prefs.setString(_key, encoded);
      if (!saved) {
        return const Result.failure(
          AppFailure(
            code: FailureCode.cacheUnavailable,
            message: "Couldn't save the resume queue",
          ),
        );
      }
      return const Result.success(Unit.unit);
    } on Exception {
      return const Result.failure(
        AppFailure(
          code: FailureCode.cacheUnavailable,
          message: "Couldn't save the resume queue",
        ),
      );
    }
  }

  String _generateId() {
    // App-generated, unique for this device's lifetime — no new `uuid`
    // dependency needed (§6: no new package required for M1–M3); a
    // microsecond timestamp plus an in-memory counter is sufficient since
    // ids never need to be globally unique or survive a reinstall.
    final id = '${DateTime.now().toUtc().microsecondsSinceEpoch}-$_idCounter';
    _idCounter++;
    return id;
  }
}
