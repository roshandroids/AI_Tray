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

  test('live usage builds concise native menu', () {
    final snapshot = TrayMenuBuilder.fromStatus(
      statusWith(usage: sampleUsage()),
      iconTitle: '24%',
    );

    expect(snapshot.headerLine, 'Claude · Live');
    expect(snapshot.sessionLine, contains('Session 24%'));
    expect(snapshot.sessionLine, contains('Resets'));
    expect(snapshot.weekLine, 'Week 11%');
    expect(snapshot.toolTip, contains('Session 24%'));
    expect(snapshot.toolTip, contains('Live'));
    expect(snapshot.iconTitle, '24%');

    final menu = snapshot.buildMenu();
    final items = menu.items ?? [];
    expect(items.length, 10); // 4 info + sep + 3 actions + sep + quit
    expect(items.where((i) => i.key == 'open').first.label, 'Open Dashboard');
    expect(items.where((i) => i.key == 'settings').first.label, 'Settings…');
    expect(items.where((i) => i.key == 'quit').first.label, 'Quit AI Tray');
  });

  test('cached usage shows cached badge without emoji', () {
    final snapshot = TrayMenuBuilder.fromStatus(
      statusWith(
        usage: sampleUsage(cached: true),
        outcome: RefreshOutcome.softFailure,
      ),
    );
    expect(snapshot.headerLine, 'Claude · Cached');
    expect(snapshot.headerLine.contains('🟡'), isFalse);
  });

  test('refreshing shows refreshing header', () {
    final snapshot = TrayMenuBuilder.fromStatus(
      statusWith(
        phase: RefreshPhase.refreshing,
        usage: sampleUsage(),
      ),
    );
    expect(snapshot.headerLine, 'Claude · Refreshing');
  });

  test('cli missing shows actionable header', () {
    final snapshot = TrayMenuBuilder.fromStatus(
      statusWith(
        outcome: RefreshOutcome.failure,
        error: const AppFailure(
          code: FailureCode.cliNotInstalled,
          message: 'missing',
        ),
      ),
    );
    expect(snapshot.headerLine, contains('not found'));
  });
}
