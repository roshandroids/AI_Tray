import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/errors/failure_code.dart';
import 'package:ai_tray/core/logging/buffered_app_logger.dart';
import 'package:ai_tray/core/logging/log_entry.dart';
import 'package:ai_tray/core/logging/log_level.dart';
import 'package:ai_tray/core/logging/logging_providers.dart';
import 'package:ai_tray/core/result/result.dart';
import 'package:ai_tray/features/diagnostics/presentation/logs_page.dart';
import 'package:ai_tray/features/providers/core/models/provider_models.dart';
import 'package:ai_tray/features/providers/domain/models/provider_id.dart';
import 'package:ai_tray/features/providers/domain/ports/ai_provider.dart';
import 'package:ai_tray/features/providers/domain/ports/ai_provider_port.dart';
import 'package:ai_tray/features/providers/domain/ports/provider_usage_parser.dart';
import 'package:ai_tray/features/usage/data/parsers/usage_parser.dart';
import 'package:ai_tray/features/usage/presentation/widgets/tray_empty_state.dart';
import 'package:ai_tray/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TrayEmptyState', () {
    testWidgets('shows Copilot actionable guidance variants', (tester) async {
      Future<void> pumpFailure(AppFailure? failure, {bool enabled = true}) {
        return tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark(),
            home: Scaffold(
              body: TrayEmptyState(
                failure: failure,
                provider: _FakeProvider(
                  ProviderId.copilot,
                  enabled: enabled,
                ),
              ),
            ),
          ),
        );
      }

      await pumpFailure(null, enabled: false);
      expect(find.text('GitHub Copilot is disabled'), findsOneWidget);
      expect(
        find.textContaining('Enable GitHub Copilot in Settings'),
        findsOneWidget,
      );

      await pumpFailure(
        const AppFailure(
          code: FailureCode.cliNotInstalled,
          message: 'SDK missing',
        ),
      );
      expect(find.text('Copilot SDK is missing'), findsOneWidget);

      await pumpFailure(
        const AppFailure(
          code: FailureCode.notAuthenticated,
          message: 'Signed out',
        ),
      );
      expect(find.text('Authentication expired'), findsOneWidget);
      expect(find.textContaining('Sign in to GitHub Copilot'), findsOneWidget);

      await pumpFailure(
        const AppFailure(
          code: FailureCode.unknown,
          message: 'quota rpc unavailable',
        ),
      );
      expect(find.text('Copilot quota unavailable'), findsOneWidget);

      await pumpFailure(
        const AppFailure(
          code: FailureCode.unknown,
          message: 'experimental API disabled',
        ),
      );
      expect(find.text('Experimental Copilot API unavailable'), findsOneWidget);
    });
  });

  group('BufferedAppLogger metadata', () {
    test('tags provider and category for reliable filtering', () {
      final logger = BufferedAppLogger()
        ..info('refresh started', name: 'claude_adapter')
        ..info(
          'quota probe',
          name: 'sdk',
          provider: 'copilot',
          category: 'diagnostics',
        )
        ..info('generic event', name: 'bootstrap');

      expect(logger.entries[0].provider, 'claude');
      expect(logger.entries[0].category, 'provider');
      expect(logger.entries[1].provider, 'copilot');
      expect(logger.entries[1].category, 'diagnostics');
      expect(logger.entries[2].provider, isNull);
      expect(
        logger.exportPlainText(),
        contains('provider=copilot category=diagnostics'),
      );
    });
  });

  group('LogsPage', () {
    testWidgets('distinguishes empty, filtered, and provider matches', (
      tester,
    ) async {
      final logger = BufferedAppLogger();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bufferedAppLoggerProvider.overrideWithValue(logger),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const LogsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('logs-empty')), findsOneWidget);

      logger
        ..info('claude refresh', name: 'claude_cli', provider: 'claude')
        ..info(
          'copilot diagnostics',
          name: 'copilot_diagnostics',
          provider: 'copilot',
          category: 'diagnostics',
        );
      await tester.pumpAndSettle();

      expect(find.textContaining('claude refresh'), findsOneWidget);
      expect(find.textContaining('copilot diagnostics'), findsOneWidget);
      expect(find.textContaining('diagnostics'), findsWidgets);

      await tester.tap(find.text('COPILOT'));
      await tester.pumpAndSettle();
      expect(find.textContaining('copilot diagnostics'), findsOneWidget);
      expect(find.textContaining('claude refresh'), findsNothing);

      await tester.tap(find.text('CLAUDE'));
      await tester.pumpAndSettle();
      expect(find.textContaining('claude refresh'), findsOneWidget);
      expect(find.textContaining('copilot diagnostics'), findsNothing);

      await tester.enterText(find.byType(TextField), 'no-such-entry');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('logs-no-match')), findsOneWidget);
    });

    testWidgets('clear and export give mounted-safe feedback', (tester) async {
      final logger = BufferedAppLogger()
        ..info('keep me', name: 'claude_cli', provider: 'claude');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bufferedAppLoggerProvider.overrideWithValue(logger),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const LogsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Clear'));
      await tester.pumpAndSettle();
      expect(find.text('Logs cleared'), findsOneWidget);
      expect(logger.entries, isEmpty);
      expect(find.byKey(const ValueKey('logs-empty')), findsOneWidget);

      await tester.tap(find.byTooltip('Export'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Export as .txt'));
      await tester.pumpAndSettle();
      expect(find.text('No logs to export'), findsOneWidget);
    });

    testWidgets('tapping a row expands a metadata drawer with the error '
        'and recovery hint', (tester) async {
      final logger = BufferedAppLogger()
        ..warning(
          'refresh failed',
          name: 'claude_cli',
          provider: 'claude',
          error: const AppFailure(
            code: FailureCode.timeout,
            message: 'timed out',
          ),
        );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bufferedAppLoggerProvider.overrideWithValue(logger),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const LogsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Timestamp'), findsNothing);

      await tester.tap(find.textContaining('refresh failed'));
      await tester.pumpAndSettle();

      expect(find.text('Timestamp'), findsOneWidget);
      expect(find.textContaining('timed out'), findsWidgets);
    });

    testWidgets('grouping by provider groups rows under provider headers', (
      tester,
    ) async {
      final logger = BufferedAppLogger()
        ..info('claude refresh', name: 'claude_cli', provider: 'claude')
        ..info(
          'copilot diagnostics',
          name: 'copilot_diagnostics',
          provider: 'copilot',
        );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bufferedAppLoggerProvider.overrideWithValue(logger),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const LogsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Group by provider'));
      await tester.pumpAndSettle();

      expect(find.textContaining('CLAUDE · 1'), findsOneWidget);
      expect(find.textContaining('COPILOT · 1'), findsOneWidget);
    });
  });

  test('LogEntry plain line includes optional metadata', () {
    final entry = LogEntry(
      timestamp: DateTime.utc(2026, 7, 17, 12),
      level: LogLevel.info,
      message: 'hello',
      component: 'copilot_diagnostics',
      provider: 'copilot',
      category: 'diagnostics',
    );
    expect(entry.toPlainLine(), contains('provider=copilot'));
    expect(entry.toPlainLine(), contains('category=diagnostics'));
  });
}

final class _FakeProvider implements AIProvider {
  const _FakeProvider(this.providerId, {this.enabled = true});

  @override
  final ProviderId providerId;

  @override
  final bool enabled;

  @override
  String get displayName =>
      providerId == ProviderId.claude ? 'Claude' : 'GitHub Copilot';

  @override
  String get sourceLabel =>
      providerId == ProviderId.claude ? 'Claude CLI' : 'Copilot SDK';

  @override
  ProviderCapabilities get capabilities => providerId == ProviderId.claude
      ? ProviderCapabilities.claude
      : ProviderCapabilities.copilot;

  @override
  ProviderUsageParser get parser => const UsageParser();

  @override
  String get limitsUnavailableMessage => 'Unavailable';

  @override
  Future<Result<UsageRawFetch>> fetchUsageRaw({
    ProviderExecutionConfig config = const ProviderExecutionConfig(),
  }) async {
    return const Result.failure(
      AppFailure(code: FailureCode.unknown, message: 'unused'),
    );
  }

  @override
  Future<Result<AuthHealth>> healthCheck({
    ProviderExecutionConfig config = const ProviderExecutionConfig(),
  }) async {
    return const Result.failure(
      AppFailure(code: FailureCode.unknown, message: 'unused'),
    );
  }
}
