import 'dart:convert';

import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/providers/domain/models/provider_id.dart';
import 'package:ai_tray/features/usage/domain/models/usage_info.dart';
import 'package:ai_tray/features/usage/domain/models/usage_source.dart';
import 'package:ai_tray/features/usage/domain/models/weekly_usage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists last-known-good Shape A [UsageInfo] (ADR-002).
abstract interface class UsageCache {
  Future<Result<UsageInfo?>> read();

  Future<Result<Unit>> write(UsageInfo usage);

  Future<Result<Unit>> clear();
}

/// Sentinel for void success.
enum Unit { unit }

final class SharedPreferencesUsageCache implements UsageCache {
  SharedPreferencesUsageCache(this._prefs);

  static const _key = 'usage_lkg_v1';

  final SharedPreferences _prefs;

  @override
  Future<Result<UsageInfo?>> read() async {
    try {
      final raw = _prefs.getString(_key);
      if (raw == null || raw.isEmpty) {
        return const Result.success(null);
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        await _prefs.remove(_key);
        return const Result.failure(
          AppFailure(
            code: FailureCode.cacheUnavailable,
            message: "Couldn't load local usage cache",
          ),
        );
      }
      return Result.success(_fromJson(decoded).copyWith(isFromCache: true));
    } on FormatException {
      return const Result.failure(
        AppFailure(
          code: FailureCode.cacheUnavailable,
          message: "Couldn't load local usage cache",
        ),
      );
    } on Exception {
      return const Result.failure(
        AppFailure(
          code: FailureCode.cacheUnavailable,
          message: "Couldn't load local usage cache",
        ),
      );
    }
  }

  @override
  Future<Result<Unit>> write(UsageInfo usage) async {
    try {
      // Only Shape A LKG should be written by callers.
      await _prefs.setString(_key, jsonEncode(_toJson(usage)));
      return const Result.success(Unit.unit);
    } on Exception {
      return const Result.failure(
        AppFailure(
          code: FailureCode.cacheUnavailable,
          message: "Couldn't save local usage cache",
        ),
      );
    }
  }

  @override
  Future<Result<Unit>> clear() async {
    try {
      await _prefs.remove(_key);
      return const Result.success(Unit.unit);
    } on Exception {
      return const Result.failure(
        AppFailure(
          code: FailureCode.cacheUnavailable,
          message: "Couldn't clear local usage cache",
        ),
      );
    }
  }

  Map<String, dynamic> _toJson(UsageInfo usage) {
    return {
      'sessionUsedPercent': usage.sessionUsedPercent,
      'sessionResetsAtRaw': usage.sessionResetsAtRaw,
      'sessionResetsAt': usage.sessionResetsAt?.toIso8601String(),
      'weekly': [
        for (final week in usage.weekly)
          {
            'label': week.label,
            'usedPercent': week.usedPercent,
            'resetsAtRaw': week.resetsAtRaw,
            'resetsAt': week.resetsAt?.toIso8601String(),
          },
      ],
      'fetchedAt': usage.fetchedAt.toIso8601String(),
      'source': usage.source.name,
      'providerId': usage.providerId.value,
    };
  }

  UsageInfo _fromJson(Map<String, dynamic> json) {
    final weeklyJson = json['weekly'];
    final weekly = <WeeklyUsage>[];
    if (weeklyJson is List) {
      for (final item in weeklyJson) {
        if (item is! Map<String, dynamic>) continue;
        weekly.add(
          WeeklyUsage(
            label: item['label'] as String? ?? '',
            usedPercent: (item['usedPercent'] as num).toDouble(),
            resetsAtRaw: item['resetsAtRaw'] as String?,
            resetsAt: item['resetsAt'] == null
                ? null
                : DateTime.tryParse(item['resetsAt'] as String),
          ),
        );
      }
    }

    return UsageInfo(
      sessionUsedPercent: (json['sessionUsedPercent'] as num).toDouble(),
      sessionResetsAtRaw: json['sessionResetsAtRaw'] as String?,
      sessionResetsAt: json['sessionResetsAt'] == null
          ? null
          : DateTime.tryParse(json['sessionResetsAt'] as String),
      weekly: weekly,
      fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      source: UsageSource.values.byName(json['source'] as String? ?? 'cli'),
      isFromCache: true,
      providerId: ProviderId(json['providerId'] as String? ?? 'claude'),
    );
  }
}

/// In-memory cache for tests.
final class InMemoryUsageCache implements UsageCache {
  UsageInfo? _value;

  @override
  Future<Result<UsageInfo?>> read() async => Result.success(_value);

  @override
  Future<Result<Unit>> write(UsageInfo usage) async {
    _value = usage.copyWith(isFromCache: true);
    return const Result.success(Unit.unit);
  }

  @override
  Future<Result<Unit>> clear() async {
    _value = null;
    return const Result.success(Unit.unit);
  }
}
