import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/features/providers/domain/models/provider_id.dart';
import 'package:ai_tray/features/settings/domain/models/app_settings.dart';
import 'package:ai_tray/features/usage/domain/models/parser_state.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_outcome.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_phase.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_result.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_status.dart';
import 'package:ai_tray/features/usage/domain/models/usage_info.dart';
import 'package:ai_tray/features/usage/domain/models/usage_shape.dart';
import 'package:ai_tray/features/usage/domain/models/usage_source.dart';
import 'package:ai_tray/features/usage/domain/models/validation_status.dart';
import 'package:ai_tray/features/usage/domain/models/weekly_usage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UsageInfo', () {
    test('creates valid snapshot', () {
      final fetchedAt = DateTime.utc(2026, 7, 12, 21);
      final info = UsageInfo(
        sessionUsedPercent: 12.5,
        sessionResetsAtRaw: 'Jul 12 at 10pm',
        weekly: [
          WeeklyUsage(label: 'all models', usedPercent: 0),
        ],
        fetchedAt: fetchedAt,
        source: UsageSource.cli,
        isFromCache: false,
        providerId: ProviderId.claude,
      );

      expect(info.sessionUsedPercent, 12.5);
      expect(info.weekly, hasLength(1));
      expect(info.providerId, ProviderId.claude);
    });

    test('rejects percent outside 0–100', () {
      expect(
        () => UsageInfo(
          sessionUsedPercent: 101,
          fetchedAt: DateTime.utc(2026),
          source: UsageSource.cli,
          isFromCache: false,
          providerId: ProviderId.claude,
        ),
        throwsArgumentError,
      );
    });

    test('copyWith preserves immutability of weekly list', () {
      final info = UsageInfo(
        sessionUsedPercent: 1,
        fetchedAt: DateTime.utc(2026),
        source: UsageSource.cli,
        isFromCache: true,
        providerId: ProviderId.claude,
      );
      expect(
        () => info.weekly.add(
          WeeklyUsage(label: 'x', usedPercent: 1),
        ),
        throwsUnsupportedError,
      );
    });
  });

  group('ParserState', () {
    test('empty factory is unknown/invalid', () {
      final state = ParserState.empty();
      expect(state.shape, UsageShape.unknown);
      expect(state.validation, ValidationStatus.invalid);
      expect(state.rateLimitsPresent, isFalse);
    });

    test('rejects negative counters', () {
      expect(
        () => ParserState(
          shape: UsageShape.contributionOnly,
          rateLimitsPresent: false,
          matchedSessionLine: false,
          matchedWeekLineCount: -1,
          validation: ValidationStatus.incomplete,
          rawTextLength: 0,
        ),
        throwsArgumentError,
      );
    });
  });

  group('RefreshResult / RefreshStatus', () {
    test('builds success result', () {
      final usage = UsageInfo(
        sessionUsedPercent: 2,
        fetchedAt: DateTime.utc(2026, 7, 12),
        source: UsageSource.cli,
        isFromCache: false,
        providerId: ProviderId.claude,
      );
      final result = RefreshResult(
        status: RefreshOutcome.success,
        usage: usage,
        parserState: ParserState(
          shape: UsageShape.rateLimitsPresent,
          rateLimitsPresent: true,
          matchedSessionLine: true,
          matchedWeekLineCount: 2,
          validation: ValidationStatus.valid,
          rawTextLength: 200,
        ),
        duration: const Duration(milliseconds: 1100),
        cliExitCode: 0,
      );

      expect(result.status, RefreshOutcome.success);
      expect(result.error, isNull);
    });

    test('soft failure can carry AppFailure and cached usage', () {
      final cached = UsageInfo(
        sessionUsedPercent: 2,
        fetchedAt: DateTime.utc(2026, 7, 12),
        source: UsageSource.cli,
        isFromCache: true,
        providerId: ProviderId.claude,
      );
      final result = RefreshResult(
        status: RefreshOutcome.softFailure,
        usage: cached,
        parserState: ParserState(
          shape: UsageShape.contributionOnly,
          rateLimitsPresent: false,
          matchedSessionLine: false,
          matchedWeekLineCount: 0,
          validation: ValidationStatus.incomplete,
          rawTextLength: 400,
        ),
        error: const AppFailure(
          code: FailureCode.incompleteOutput,
          message: 'Usage limits temporarily unavailable',
        ),
        duration: const Duration(seconds: 1),
      );

      expect(result.usage?.isFromCache, isTrue);
      expect(result.error?.code, FailureCode.incompleteOutput);
    });

    test('initial refresh status is idle', () {
      final status = RefreshStatus.initial();
      expect(status.phase, RefreshPhase.idle);
      expect(status.consecutiveSoftFailures, 0);
    });

    test('rejects negative duration', () {
      expect(
        () => RefreshResult(
          status: RefreshOutcome.failure,
          parserState: ParserState.empty(),
          duration: const Duration(seconds: -1),
        ),
        throwsArgumentError,
      );
    });
  });

  group('AppSettings', () {
    test('defaults are within MVP interval bounds', () {
      final settings = AppSettings.defaults();
      expect(settings.autoRefreshEnabled, isTrue);
      expect(settings.refreshInterval, AppSettings.defaultRefreshInterval);
      expect(
        settings.refreshInterval,
        greaterThanOrEqualTo(AppSettings.minRefreshInterval),
      );
      expect(
        settings.refreshInterval,
        lessThanOrEqualTo(AppSettings.maxRefreshInterval),
      );
    });

    test('rejects interval below minimum', () {
      expect(
        () => AppSettings(
          autoRefreshEnabled: true,
          refreshInterval: const Duration(seconds: 10),
          notificationsEnabled: false,
          launchAtLogin: false,
          showStaleIndicator: true,
        ),
        throwsArgumentError,
      );
    });

    test('rejects interval above maximum', () {
      expect(
        () => AppSettings(
          autoRefreshEnabled: true,
          refreshInterval: const Duration(seconds: 90),
          notificationsEnabled: false,
          launchAtLogin: false,
          showStaleIndicator: true,
        ),
        throwsArgumentError,
      );
    });

    test('trims empty binary path to null', () {
      final settings = AppSettings(
        autoRefreshEnabled: true,
        refreshInterval: const Duration(seconds: 30),
        notificationsEnabled: true,
        launchAtLogin: false,
        claudeBinaryPath: '   ',
        showStaleIndicator: true,
      );
      expect(settings.claudeBinaryPath, isNull);
    });
  });

  group('ProviderId', () {
    test('claude constant is stable', () {
      expect(ProviderId.claude.value, 'claude');
    });

    test('rejects empty value', () {
      expect(() => ProviderId('  '), throwsArgumentError);
    });
  });
}
