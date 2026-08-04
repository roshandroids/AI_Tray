import 'package:ai_tray/core/logging/console_app_logger.dart';
import 'package:ai_tray/core/theme/app_theme.dart';
import 'package:ai_tray/features/providers/data/claude/claude_cli_adapter.dart';
import 'package:ai_tray/features/providers/data/copilot/copilot_provider.dart';
import 'package:ai_tray/features/providers/data/process/fake_process_runner.dart';
import 'package:ai_tray/features/providers/domain/models/provider_id.dart';
import 'package:ai_tray/features/providers/domain/services/provider_registry.dart';
import 'package:ai_tray/features/providers/presentation/widgets/provider_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('selector renders enabled providers only', (tester) async {
    final registry = ProviderRegistry(
      providers: [
        ClaudeCliAdapter(
          processRunner: FakeProcessRunner(),
          logger: ConsoleAppLogger(defaultName: 'test'),
        ),
        const CopilotProvider(),
      ],
      defaultProviderId: ProviderId.claude,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: ProviderSelector(
            providers: registry.enabledProviders.toList(),
            selectedId: ProviderId.claude,
            onSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Claude'), findsOneWidget);
    expect(find.text('GitHub Copilot'), findsNothing);
  });
}
