import 'dart:async';

import 'package:ai_tray/core/di/providers.dart';
import 'package:ai_tray/features/settings/presentation/settings_page.dart';
import 'package:ai_tray/features/tray/presentation/tray_controller.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_outcome.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_phase.dart';
import 'package:ai_tray/features/usage/domain/models/refresh_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Root application widget.
class AiTrayApp extends ConsumerWidget {
  const AiTrayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'AI Tray',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1F6FEB)),
        useMaterial3: true,
      ),
      home: const _UsageShell(),
    );
  }
}

class _UsageShell extends ConsumerWidget {
  const _UsageShell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<int>(settingsOpenRequestProvider, (previous, next) {
      if (previous == next) return;
      unawaited(
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
        ),
      );
    });

    final repository = ref.watch(usageRepositoryProvider);
    final textTheme = Theme.of(context).textTheme;

    return StreamBuilder<RefreshStatus>(
      stream: repository.watchStatus(),
      initialData: repository.status,
      builder: (context, snapshot) {
        final status = snapshot.data ?? RefreshStatus.initial();
        final usage = status.lastResult?.usage;
        final outcome = status.lastResult?.status;
        final error = status.lastResult?.error;

        return Scaffold(
          appBar: AppBar(
            title: const Text('AI Tray'),
            actions: [
              IconButton(
                tooltip: 'Settings',
                onPressed: () {
                  unawaited(
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SettingsPage(),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.settings),
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (status.phase == RefreshPhase.refreshing)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: CircularProgressIndicator(),
                      ),
                    if (usage != null) ...[
                      Text(
                        'Session '
                        '${usage.sessionUsedPercent.toStringAsFixed(0)}%',
                        style: textTheme.titleLarge,
                      ),
                      if (usage.sessionResetsAtRaw != null)
                        Text(
                          'Resets ${usage.sessionResetsAtRaw}',
                          style: textTheme.bodyMedium,
                        ),
                      for (final week in usage.weekly)
                        Text(
                          'Week (${week.label}): '
                          '${week.usedPercent.toStringAsFixed(0)}%',
                          style: textTheme.bodyMedium,
                        ),
                      const SizedBox(height: 8),
                      Text(
                        usage.isFromCache
                            ? 'Showing last known usage'
                            : 'Live',
                        style: textTheme.labelLarge,
                      ),
                    ] else
                      Text(
                        error?.message ?? 'No usage data yet',
                        style: textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    if (outcome == RefreshOutcome.softFailure)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Claude did not return limits; showing cache',
                          style: textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (outcome == RefreshOutcome.failure && usage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          error?.message ?? 'Refresh failed',
                          style: textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: status.phase == RefreshPhase.refreshing
                          ? null
                          : () => unawaited(repository.refresh(manual: true)),
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
