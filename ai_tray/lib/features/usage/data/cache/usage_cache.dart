import 'dart:convert';

import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/providers/domain/models/provider_id.dart';
import 'package:ai_tray/features/providers/domain/models/provider_usage_metric.dart';
import 'package:ai_tray/features/usage/domain/models/usage_info.dart';
import 'package:ai_tray/features/usage/domain/models/usage_source.dart';
import 'package:ai_tray/features/usage/domain/models/weekly_usage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists last-known-good Shape A [UsageInfo] (ADR-002).
abstract interface class UsageCache {
  Future<Result<UsageInfo?>> read({ProviderId? providerId});

  Future<Result<Unit>> write(UsageInfo usage);

  Future<Result<Unit>> clear({ProviderId? providerId});
}

/// Sentinel for void success.
enum Unit { unit }

final class SharedPreferencesUsageCache implements UsageCache {
  SharedPreferencesUsageCache(this._prefs);

  static const _key = 'usage_lkg_v1';
  static const _scopedPrefix = 'usage_lkg_v2_';

  final SharedPreferences _prefs;

  @override
  Future<Result<UsageInfo?>> read({ProviderId? providerId}) async {
    try {
      final effectiveProviderId = providerId ?? ProviderId.claude;
      final scopedKey = _keyFor(effectiveProviderId);
      var raw = _prefs.getString(scopedKey);
      var fromLegacy = false;
      if (raw == null && effectiveProviderId == ProviderId.claude) {
        raw = _prefs.getString(_key);
        fromLegacy = raw != null;
      }
      if (raw == null || raw.isEmpty) {
        return const Result.success(null);
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        await _prefs.remove(fromLegacy ? _key : scopedKey);
        return const Result.failure(
          AppFailure(
            code: FailureCode.cacheUnavailable,
            message: "Couldn't load local usage cache",
          ),
        );
      }
      final usage = _fromJson(decoded).copyWith(isFromCache: true);
      if (usage.providerId != effectiveProviderId) {
        return const Result.success(null);
      }
      if (fromLegacy) {
        await _prefs.setString(scopedKey, raw);
        await _prefs.remove(_key);
      }
      return Result.success(usage);
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
      await _prefs.setString(
        _keyFor(usage.providerId),
        jsonEncode(_toJson(usage)),
      );
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
  Future<Result<Unit>> clear({ProviderId? providerId}) async {
    try {
      if (providerId == null) {
        await Future.wait([
          _prefs.remove(_key),
          _prefs.remove(_keyFor(ProviderId.claude)),
          _prefs.remove(_keyFor(ProviderId.copilot)),
        ]);
      } else {
        await _prefs.remove(_keyFor(providerId));
        if (providerId == ProviderId.claude) {
          await _prefs.remove(_key);
        }
      }
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

  String _keyFor(ProviderId providerId) {
    return '$_scopedPrefix${providerId.value}';
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
      'metrics': [
        for (final metric in usage.metrics)
          {
            'key': metric.key,
            'label': metric.label,
            'usedPercent': metric.usedPercent,
            'primary': metric.primary,
            'resetsAtRaw': metric.resetsAtRaw,
            'resetsAt': metric.resetsAt?.toIso8601String(),
            'value': metric.value,
            'total': metric.total,
            'unit': metric.unit,
            'remainingPercent': metric.remainingPercent,
            'unlimited': metric.unlimited,
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

    final metrics = <ProviderUsageMetric>[];
    final metricsJson = json['metrics'];
    if (metricsJson is List) {
      for (final item in metricsJson) {
        if (item is! Map<String, dynamic>) continue;
        final percent = item['usedPercent'];
        if (percent is! num) continue;
        metrics.add(
          ProviderUsageMetric(
            key: item['key'] as String? ?? '',
            label: item['label'] as String? ?? '',
            usedPercent: percent.toDouble(),
            primary: item['primary'] == true,
            resetsAtRaw: item['resetsAtRaw'] as String?,
            resetsAt: item['resetsAt'] == null
                ? null
                : DateTime.tryParse(item['resetsAt'] as String),
            value: item['value'] as num?,
            total: item['total'] as num?,
            unit: item['unit'] as String?,
            remainingPercent: (item['remainingPercent'] as num?)?.toDouble(),
            unlimited: item['unlimited'] == true,
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
      metrics: metrics,
      fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      source: UsageSource.values.byName(json['source'] as String? ?? 'cli'),
      isFromCache: true,
      providerId: ProviderId(json['providerId'] as String? ?? 'claude'),
    );
  }
}

/// In-memory cache for tests.
final class InMemoryUsageCache implements UsageCache {
  final Map<ProviderId, UsageInfo> _values = {};

  @override
  Future<Result<UsageInfo?>> read({ProviderId? providerId}) async {
    if (providerId != null) {
      return Result.success(_values[providerId]);
    }
    return Result.success(_values.isEmpty ? null : _values.values.first);
  }

  @override
  Future<Result<Unit>> write(UsageInfo usage) async {
    _values[usage.providerId] = usage.copyWith(isFromCache: true);
    return const Result.success(Unit.unit);
  }

  @override
  Future<Result<Unit>> clear({ProviderId? providerId}) async {
    if (providerId == null) {
      _values.clear();
    } else {
      _values.remove(providerId);
    }
    return const Result.success(Unit.unit);
  }
}
