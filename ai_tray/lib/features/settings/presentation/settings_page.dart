import 'dart:async';

import 'package:ai_tray/core/di/providers.dart';
import 'package:ai_tray/core/theme/app_theme_mode.dart';
import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:ai_tray/core/theme/theme_controller.dart';
import 'package:ai_tray/core/widgets/terminal_chrome.dart';
import 'package:ai_tray/features/diagnostics/presentation/diagnostics_page.dart';
import 'package:ai_tray/features/diagnostics/presentation/logs_page.dart';
import 'package:ai_tray/features/settings/domain/models/app_settings.dart';
import 'package:ai_tray/features/tray/presentation/tray_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Developer-oriented settings panel (PD-020).
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late Future<AppSettings> _future;
  late TextEditingController _binaryController;

  @override
  void initState() {
    super.initState();
    _binaryController = TextEditingController();
    _future = ref.read(usageRepositoryProvider).getSettings().then((settings) {
      _binaryController.text = settings.claudeBinaryPath ?? '';
      return settings;
    });
  }

  @override
  void dispose() {
    _binaryController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _future = ref.read(usageRepositoryProvider).getSettings().then((s) {
        _binaryController.text = s.claudeBinaryPath ?? '';
        return s;
      });
    });
  }

  Future<void> _save(AppSettings settings) async {
    final repo = ref.read(usageRepositoryProvider);
    await repo.updateSettings(settings);
    await ref.read(trayControllerProvider).applyLaunchAtLogin(settings);
    await _reload();
  }

  Future<void> _setTheme(AppThemePreference mode) async {
    await ref.read(themeControllerProvider.notifier).setPreference(mode);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final themePref = ref.watch(themeControllerProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: FutureBuilder<AppSettings>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final settings = snapshot.data!;
          final selectedTheme = themePref ?? settings.themeMode;

          return ListView(
            padding: const EdgeInsets.all(Spacing.lg),
            children: [
              const TerminalSectionLabel('Appearance'),
              const SizedBox(height: Spacing.sm),
              SegmentedButton<AppThemePreference>(
                segments: const [
                  ButtonSegment(
                    value: AppThemePreference.system,
                    label: Text('System'),
                  ),
                  ButtonSegment(
                    value: AppThemePreference.dark,
                    label: Text('Dark'),
                  ),
                  ButtonSegment(
                    value: AppThemePreference.light,
                    label: Text('Light'),
                  ),
                ],
                selected: {selectedTheme},
                onSelectionChanged: (selected) {
                  if (selected.isEmpty) return;
                  unawaited(_setTheme(selected.first));
                },
              ),
              const AsciiSeparator(),
              const TerminalSectionLabel('Refresh'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Auto refresh'),
                value: settings.autoRefreshEnabled,
                onChanged: (value) {
                  unawaited(
                    _save(settings.copyWith(autoRefreshEnabled: value)),
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Refresh interval'),
                subtitle: Text('${settings.refreshInterval.inSeconds}s'),
                trailing: DropdownButton<int>(
                  value: settings.refreshInterval.inSeconds,
                  dropdownColor: context.colors.surfaceRaised,
                  style: context.typography.body,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: 30, child: Text('30s')),
                    DropdownMenuItem(value: 45, child: Text('45s')),
                    DropdownMenuItem(value: 60, child: Text('60s')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    unawaited(
                      _save(
                        settings.copyWith(
                          refreshInterval: Duration(seconds: value),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const AsciiSeparator(),
              const TerminalSectionLabel('Notifications'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enable notifications'),
                value: settings.notificationsEnabled,
                onChanged: (value) {
                  unawaited(
                    _save(settings.copyWith(notificationsEnabled: value)),
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Notify at session %'),
                subtitle: Text(
                  settings.notifyAtSessionPercent?.toStringAsFixed(0) ?? 'Off',
                ),
                trailing: DropdownButton<double?>(
                  value: settings.notifyAtSessionPercent,
                  dropdownColor: context.colors.surfaceRaised,
                  style: context.typography.body,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Off')),
                    DropdownMenuItem(value: 50, child: Text('50%')),
                    DropdownMenuItem(value: 75, child: Text('75%')),
                    DropdownMenuItem(value: 90, child: Text('90%')),
                  ],
                  onChanged: (value) {
                    unawaited(
                      _save(
                        AppSettings(
                          autoRefreshEnabled: settings.autoRefreshEnabled,
                          refreshInterval: settings.refreshInterval,
                          notificationsEnabled: settings.notificationsEnabled,
                          launchAtLogin: settings.launchAtLogin,
                          showStaleIndicator: settings.showStaleIndicator,
                          notifyAtSessionPercent: value,
                          claudeBinaryPath: settings.claudeBinaryPath,
                          themeMode: settings.themeMode,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const AsciiSeparator(),
              const TerminalSectionLabel('App behavior'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Launch at login'),
                value: settings.launchAtLogin,
                onChanged: (value) {
                  unawaited(_save(settings.copyWith(launchAtLogin: value)));
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show stale indicator'),
                subtitle: const Text('Highlight Cached status in UI'),
                value: settings.showStaleIndicator,
                onChanged: (value) {
                  unawaited(
                    _save(settings.copyWith(showStaleIndicator: value)),
                  );
                },
              ),
              const AsciiSeparator(),
              const TerminalSectionLabel('CLI'),
              const SizedBox(height: Spacing.sm),
              TextField(
                controller: _binaryController,
                style: context.typography.body,
                decoration: const InputDecoration(
                  labelText: 'Claude binary path (optional)',
                  hintText: 'claude',
                ),
                onSubmitted: (value) {
                  unawaited(
                    _save(
                      AppSettings(
                        autoRefreshEnabled: settings.autoRefreshEnabled,
                        refreshInterval: settings.refreshInterval,
                        notificationsEnabled: settings.notificationsEnabled,
                        launchAtLogin: settings.launchAtLogin,
                        showStaleIndicator: settings.showStaleIndicator,
                        notifyAtSessionPercent: settings.notifyAtSessionPercent,
                        claudeBinaryPath: value.trim().isEmpty
                            ? null
                            : value.trim(),
                        themeMode: settings.themeMode,
                      ),
                    ),
                  );
                },
              ),
              const AsciiSeparator(),
              const TerminalSectionLabel('Diagnostics'),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Open diagnostics'),
                subtitle: const Text('Health, parser, cache, environment'),
                trailing: const Icon(Icons.chevron_right, size: 18),
                onTap: () {
                  unawaited(
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const DiagnosticsPage(),
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Open logs'),
                subtitle: const Text('Ring-buffer viewer · copy · export'),
                trailing: const Icon(Icons.chevron_right, size: 18),
                onTap: () {
                  unawaited(
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const LogsPage(),
                      ),
                    ),
                  );
                },
              ),
              const AsciiSeparator(),
              Text(
                'AI Tray · terminal companion for Claude Code',
                style: context.typography.muted.copyWith(fontSize: 11),
              ),
            ],
          );
        },
      ),
    );
  }
}
