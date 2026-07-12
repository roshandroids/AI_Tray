import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/features/providers/domain/models/provider_id.dart';
import 'package:ai_tray/features/tray/presentation/tray_menu_builder.dart';
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
  UsageInfo sampleUsage({
    bool cached = false,
    double session = 24,
  }) {
    return UsageInfo(
      sessionUsedPercent: session,
      fetchedAt: DateTime.utc(2026, 7, 12, 22, 0),
      source: UsageSource.cli,
      isFromCache: cached,
      providerId: ProviderId.claude,
      sessionResetsAtRaw: '10pm (America/Toronto)',
      weekly: [
        WeeklyUsage(
          label: 'all models',
          usedPercent: 11,
          resetsAtRaw: 'Sat 7am (America/Toronto)',
        ),
      ],
    );
  }

  RefreshStatus statusWith({
    RefreshPhase phase = RefreshPhase.idle,
    UsageInfo? usage,
    RefreshOutcome? outcome,
    AppFailure? error,
    DateTime? lastSuccessAt,
  }) {
    return RefreshStatus(
      phase: phase,
      lastResult: RefreshResult(
        status: outcome ?? RefreshOutcome.success,
        parserState: ParserState(
          shape: UsageShape.rateLimitsPresent,
          rateLimitsPresent: true,
          matchedSessionLine: true,
          matchedWeekLineCount: 1,
          validation: ValidationStatus.valid,
          rawTextLength: 100,
        ),
        duration: const Duration(milliseconds: 100),
        usage: usage,
        error: error,
      ),
      lastSuccessAt: lastSuccessAt ?? usage?.fetchedAt,
    );
  }

  test('live usage builds rich menu sections', () {
    final snapshot = TrayMenuBuilder.fromStatus(
      statusWith(usage: sampleUsage()),
    );

    expect(snapshot.connectionLabel, contains('connected'));
    expect(snapshot.sessionPercentLine, '24% used');
    expect(snapshot.sessionBarLine, '██░░░░░░░░');
    expect(snapshot.weekTitleLine, 'Current Week (all models)');
    expect(snapshot.footerStatusLine, '🟢 Live');
    expect(snapshot.toolTip, contains('Session 24%'));

    final menu = snapshot.buildMenu();
    final items = menu.items ?? [];
    expect(items.length, greaterThan(10));
    expect(
      items.where((i) => i.key == 'open').first.label,
      'Open Dashboard',
    );
  });

  test('cached usage shows cached badge', () {
    final snapshot = TrayMenuBuilder.fromStatus(
      statusWith(
        usage: sampleUsage(cached: true),
        outcome: RefreshOutcome.softFailure,
      ),
    );
    expect(snapshot.footerStatusLine, '🟡 Cached');
  });

  test('refreshing shows refreshing states', () {
    final snapshot = TrayMenuBuilder.fromStatus(
      statusWith(
        phase: RefreshPhase.refreshing,
        usage: sampleUsage(),
      ),
    );
    expect(snapshot.connectionLabel, contains('Refreshing'));
    expect(snapshot.footerStatusLine, '🔄 Refreshing');
    expect(snapshot.iconTitle, isEmpty);
  });

  test('cli missing shows error connection state', () {
    final snapshot = TrayMenuBuilder.fromStatus(
      statusWith(
        error: const AppFailure(
          code: FailureCode.cliNotInstalled,
          message: 'Claude CLI was not found',
        ),
        outcome: RefreshOutcome.failure,
      ),
    );
    expect(snapshot.connectionLabel, contains('not found'));
    expect(snapshot.footerStatusLine, '🔴 Error');
  });
}
