import 'dart:convert';

import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/logging/app_logger.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/layout/domain/models/panel_layout_state.dart';
import 'package:ai_tray/features/layout/domain/repositories/panel_layout_repository.dart';
import 'package:ai_tray/features/usage/data/cache/usage_cache.dart' show Unit;
import 'package:shared_preferences/shared_preferences.dart';

/// Production [PanelLayoutRepository]: one JSON object under a single,
/// versioned `SharedPreferences` key — same pattern as
/// `SharedPreferencesNotificationHistoryRepository`.
final class SharedPreferencesPanelLayoutRepository
    implements PanelLayoutRepository {
  SharedPreferencesPanelLayoutRepository(
    this._prefs, {
    required AppLogger logger,
  }) : _logger = logger;

  static const _key = 'panel_layout_v1';

  final SharedPreferences _prefs;
  final AppLogger _logger;

  @override
  Future<Result<Map<String, PanelLayoutState>>> loadAll() async {
    try {
      final raw = _prefs.getString(_key);
      if (raw == null || raw.isEmpty) return const Result.success({});

      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return const Result.failure(
          AppFailure(
            code: FailureCode.cacheUnavailable,
            message: "Couldn't load panel layout",
          ),
        );
      }

      final states = <String, PanelLayoutState>{};
      for (final entry in decoded.entries) {
        final panelId = entry.key;
        final value = entry.value;
        if (panelId is! String || value is! Map) {
          _logger.warning(
            'skipping malformed panel layout entry',
            name: 'panel_layout',
          );
          continue;
        }
        final parsed = PanelLayoutState.tryFromJson(
          Map<String, Object?>.from(value),
        );
        if (parsed == null) {
          _logger.warning(
            'skipping malformed panel layout entry',
            name: 'panel_layout',
          );
          continue;
        }
        states[panelId] = parsed;
      }
      return Result.success(states);
    } on FormatException {
      return const Result.failure(
        AppFailure(
          code: FailureCode.cacheUnavailable,
          message: "Couldn't load panel layout",
        ),
      );
    } on Exception {
      return const Result.failure(
        AppFailure(
          code: FailureCode.cacheUnavailable,
          message: "Couldn't load panel layout",
        ),
      );
    }
  }

  @override
  Future<Result<Unit>> save(String panelId, PanelLayoutState state) async {
    final loaded = await loadAll();
    final failure = loaded.failureOrNull;
    if (failure != null) return Result.failure(failure);
    final states = Map<String, PanelLayoutState>.from(loaded.valueOrNull!);
    states[panelId] = state;
    return _writeAll(states);
  }

  @override
  Future<Result<Unit>> clear() => _writeAll(const {});

  Future<Result<Unit>> _writeAll(Map<String, PanelLayoutState> states) async {
    try {
      final encoded = jsonEncode({
        for (final entry in states.entries) entry.key: entry.value.toJson(),
      });
      final saved = await _prefs.setString(_key, encoded);
      if (!saved) {
        return const Result.failure(
          AppFailure(
            code: FailureCode.cacheUnavailable,
            message: "Couldn't save panel layout",
          ),
        );
      }
      return const Result.success(Unit.unit);
    } on Exception {
      return const Result.failure(
        AppFailure(
          code: FailureCode.cacheUnavailable,
          message: "Couldn't save panel layout",
        ),
      );
    }
  }
}
