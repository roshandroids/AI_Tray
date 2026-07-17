import 'dart:async';

import 'package:ai_tray/core/components/settings_chrome.dart';
import 'package:ai_tray/core/di/providers.dart';
import 'package:ai_tray/core/theme/app_theme_mode.dart';
import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:ai_tray/core/theme/theme_controller.dart';
import 'package:ai_tray/features/diagnostics/presentation/diagnostics_page.dart';
import 'package:ai_tray/features/diagnostics/presentation/logs_page.dart';
import 'package:ai_tray/features/providers/domain/ports/ai_provider.dart';
import 'package:ai_tray/features/settings/domain/models/app_settings.dart';
import 'package:ai_tray/features/tray/presentation/tray_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings with left navigation rail (PD-021).
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late Future<AppSettings> _future;
  late TextEditingController _binaryController;
  SettingsSection _section = SettingsSection.appearance;

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
    final selectedProvider = ref.watch(selectedAIProviderProvider);

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

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SettingsNavRail(
                selected: _section,
                onSelect: (section) {
                  if (section == SettingsSection.diagnostics) {
                    unawaited(
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const DiagnosticsPage(),
                        ),
                      ),
                    );
                    return;
                  }
                  if (section == SettingsSection.logs) {
                    unawaited(
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const LogsPage(),
                        ),
                      ),
                    );
                    return;
                  }
                  setState(() => _section = section);
                },
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(Spacing.md),
                  children: [
                    Text(
                      _section.label,
                      style: context.typography.title,
                    ),
                    const SizedBox(height: Spacing.md),
                    ..._buildSection(
                      settings,
                      selectedTheme,
                      selectedProvider,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildSection(
    AppSettings settings,
    AppThemePreference selectedTheme,
    AIProvider selectedProvider,
  ) {
    return switch (_section) {
      SettingsSection.appearance => [
        SettingsGroup(
          title: 'Theme',
          children: [
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
            const SizedBox(height: Spacing.sm),
            Text('Accent', style: context.typography.label),
            const SizedBox(height: Spacing.sm),
            Wrap(
              spacing: Spacing.sm,
              children: [
                for (final color in [
                  context.colors.success,
                  context.colors.warning,
                  context.colors.highUsage,
                  context.colors.error,
                  context.colors.info,
                  context.colors.purpleAccent,
                  context.colors.cyanAccent,
                ])
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: context.colors.border),
                    ),
                  ),
              ],
            ),
            Text(
              'Accent swatches are status palette (fixed in PD-021).',
              style: context.typography.caption,
            ),
          ],
        ),
      ],
      SettingsSection.refresh => [
        SettingsGroup(
          title: 'Refresh',
          children: [
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
              trailing: DropdownButton<int>(
                value: settings.refreshInterval.inSeconds,
                underline: const SizedBox.shrink(),
                dropdownColor: context.colors.surfaceAlt,
                style: context.typography.body,
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
          ],
        ),
      ],
      SettingsSection.notifications => [
        SettingsGroup(
          title: 'Notifications',
          children: [
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
              trailing: DropdownButton<double?>(
                value: settings.notifyAtSessionPercent,
                underline: const SizedBox.shrink(),
                dropdownColor: context.colors.surfaceAlt,
                style: context.typography.body,
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
          ],
        ),
      ],
      SettingsSection.behavior => [
        SettingsGroup(
          title: 'App behavior',
          children: [
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
              subtitle: const Text('Highlight Cached status'),
              value: settings.showStaleIndicator,
              onChanged: (value) {
                unawaited(
                  _save(settings.copyWith(showStaleIndicator: value)),
                );
              },
            ),
          ],
        ),
      ],
      SettingsSection.cli => [
        if (selectedProvider.capabilities.customExecutable)
          SettingsGroup(
            title: '${selectedProvider.displayName} CLI',
            children: [
              TextField(
                controller: _binaryController,
                style: context.typography.body,
                decoration: InputDecoration(
                  labelText: 'Binary path (optional)',
                  hintText: selectedProvider.providerId.value,
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
            ],
          )
        else
          SettingsGroup(
            title: selectedProvider.displayName,
            children: const [
              Text('No executable configuration is required.'),
            ],
          ),
      ],
      SettingsSection.advanced => [
        SettingsGroup(
          title: 'Advanced',
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Force refresh'),
              trailing: const Icon(Icons.chevron_right, size: 16),
              onTap: () {
                unawaited(
                  ref.read(usageRepositoryProvider).refresh(manual: true),
                );
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Open diagnostics'),
              trailing: const Icon(Icons.chevron_right, size: 16),
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
              trailing: const Icon(Icons.chevron_right, size: 16),
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
          ],
        ),
      ],
      SettingsSection.about => [
        SettingsGroup(
          title: 'About',
          children: [
            Text('AI Tray 1.1.0', style: context.typography.monoData),
            const SizedBox(height: Spacing.sm),
            Text(
              'Terminal-inspired desktop companion for AI coding providers.',
              style: context.typography.caption,
            ),
          ],
        ),
      ],
      SettingsSection.diagnostics || SettingsSection.logs => const [],
    };
  }
}
