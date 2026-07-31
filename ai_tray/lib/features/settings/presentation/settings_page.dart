import 'dart:async';
import 'dart:io';

import 'package:ai_tray/core/components/section_chrome.dart';
import 'package:ai_tray/core/components/settings_chrome.dart';
import 'package:ai_tray/core/di/providers.dart';
import 'package:ai_tray/core/errors/app_failure.dart';
import 'package:ai_tray/core/theme/app_theme_mode.dart';
import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:ai_tray/features/diagnostics/presentation/copilot_diagnostics_controller.dart';
import 'package:ai_tray/features/diagnostics/presentation/diagnostics_page.dart';
import 'package:ai_tray/features/diagnostics/presentation/logs_page.dart';
import 'package:ai_tray/features/providers/domain/ports/ai_provider.dart';
import 'package:ai_tray/features/settings/domain/models/app_settings.dart';
import 'package:ai_tray/features/settings/domain/models/release_history.dart';
import 'package:ai_tray/features/settings/presentation/settings_controller.dart';
import 'package:ai_tray/features/settings/presentation/widgets/app_icon_preset_picker.dart';
import 'package:ai_tray/features/settings/presentation/widgets/font_preset_picker.dart';
import 'package:ai_tray/features/settings/presentation/widgets/theme_mode_picker.dart';
import 'package:ai_tray/features/settings/presentation/widgets/theme_preset_picker.dart';
import 'package:ai_tray/features/settings/release_history_providers.dart';
import 'package:ai_tray/theme/app_icons.dart';
import 'package:ai_tray/theme/personalization_controller.dart';
import 'package:ai_tray/theme/personalization_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Settings with left navigation rail (PD-021).
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late TextEditingController _binaryController;
  SettingsSection _section = SettingsSection.appearance;
  bool _binaryInitialized = false;

  @override
  void initState() {
    super.initState();
    _binaryController = TextEditingController();
  }

  @override
  void dispose() {
    _binaryController.dispose();
    super.dispose();
  }

  Future<void> _save(AppSettings settings) async {
    final saved = await ref
        .read(settingsControllerProvider.notifier)
        .save(settings);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            saved
                ? 'Settings saved'
                : _settingsErrorMessage(
                    ref.read(settingsControllerProvider).error,
                  ),
          ),
        ),
      );
  }

  Future<void> _setTheme(AppThemePreference mode) async {
    await ref
        .read(personalizationControllerProvider.notifier)
        .setThemeMode(mode);
  }

  @override
  Widget build(BuildContext context) {
    final personalization =
        ref.watch(personalizationControllerProvider).value ??
        PersonalizationState.defaults();
    final iconSwitcher = ref.watch(appIconSwitcherProvider);
    final selectedProvider = ref.watch(selectedAIProviderProvider);
    final settingsState = ref.watch(settingsControllerProvider);
    final settings =
        settingsState.value ??
        ref.read(settingsControllerProvider.notifier).lastSettings;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settings == null
          ? _SettingsLoadState(
              loading: settingsState.isLoading,
              message: _settingsErrorMessage(settingsState.error),
              onRetry: () => unawaited(
                ref.read(settingsControllerProvider.notifier).retry(),
              ),
            )
          : Builder(
              builder: (context) {
                if (!_binaryInitialized) {
                  _binaryController.text = settings.claudeBinaryPath ?? '';
                  _binaryInitialized = true;
                }

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
                          if (settingsState.hasError) ...[
                            _InlineError(
                              message: _settingsErrorMessage(
                                settingsState.error,
                              ),
                              onRetry: () => unawaited(
                                ref
                                    .read(settingsControllerProvider.notifier)
                                    .retry(),
                              ),
                            ),
                            const SizedBox(height: Spacing.md),
                          ],
                          Text(
                            _section.label,
                            style: context.typography.title,
                          ),
                          const SizedBox(height: Spacing.md),
                          ..._buildSection(
                            settings,
                            personalization,
                            iconSwitcher.isSupported,
                            selectedProvider,
                            settingsState.isLoading,
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
    PersonalizationState personalization,
    bool iconSwitchSupported,
    AIProvider selectedProvider,
    bool saving,
  ) {
    return switch (_section) {
      SettingsSection.appearance => [
        SettingsGroup(
          title: 'Theme mode',
          children: [
            ThemeModePicker(
              selected: personalization.themeMode,
              onChanged: (mode) => unawaited(_setTheme(mode)),
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        SettingsGroup(
          title: 'Color theme',
          children: [
            ThemePresetPicker(
              selected: personalization.themePreset,
              onChanged: (preset) => unawaited(
                ref
                    .read(personalizationControllerProvider.notifier)
                    .setThemePreset(preset),
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        SettingsGroup(
          title: 'Font',
          children: [
            FontPresetPicker(
              selected: personalization.fontPreset,
              onChanged: (preset) => unawaited(
                ref
                    .read(personalizationControllerProvider.notifier)
                    .setFontPreset(preset),
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        SettingsGroup(
          title: 'App icon',
          children: [
            AppIconPresetPicker(
              selected: personalization.appIconPreset,
              isSupported: iconSwitchSupported,
              onChanged: (preset) => unawaited(
                ref
                    .read(personalizationControllerProvider.notifier)
                    .setAppIconPreset(preset),
              ),
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
              onChanged: saving
                  ? null
                  : (value) {
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
                onChanged: saving
                    ? null
                    : (value) {
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
              onChanged: saving
                  ? null
                  : (value) {
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
                onChanged: saving
                    ? null
                    : (value) {
                        unawaited(
                          _save(
                            AppSettings(
                              autoRefreshEnabled: settings.autoRefreshEnabled,
                              refreshInterval: settings.refreshInterval,
                              notificationsEnabled:
                                  settings.notificationsEnabled,
                              launchAtLogin: settings.launchAtLogin,
                              showStaleIndicator: settings.showStaleIndicator,
                              notifyAtSessionPercent: value,
                              claudeBinaryPath: settings.claudeBinaryPath,
                              selectedProviderId: settings.selectedProviderId,
                              themeMode: settings.themeMode,
                              themePreset: settings.themePreset,
                              fontPreset: settings.fontPreset,
                              appIconPreset: settings.appIconPreset,
                              copilotEnabled: settings.copilotEnabled,
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
              onChanged: saving
                  ? null
                  : (value) {
                      unawaited(_save(settings.copyWith(launchAtLogin: value)));
                    },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Show stale indicator'),
              subtitle: const Text('Highlight Cached status'),
              value: settings.showStaleIndicator,
              onChanged: saving
                  ? null
                  : (value) {
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
                onSubmitted: saving
                    ? null
                    : (value) {
                        unawaited(
                          _save(
                            AppSettings(
                              autoRefreshEnabled: settings.autoRefreshEnabled,
                              refreshInterval: settings.refreshInterval,
                              notificationsEnabled:
                                  settings.notificationsEnabled,
                              launchAtLogin: settings.launchAtLogin,
                              showStaleIndicator: settings.showStaleIndicator,
                              notifyAtSessionPercent:
                                  settings.notifyAtSessionPercent,
                              claudeBinaryPath: value.trim().isEmpty
                                  ? null
                                  : value.trim(),
                              selectedProviderId: settings.selectedProviderId,
                              themeMode: settings.themeMode,
                              themePreset: settings.themePreset,
                              fontPreset: settings.fontPreset,
                              appIconPreset: settings.appIconPreset,
                              copilotEnabled: settings.copilotEnabled,
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
        _buildCopilotSettings(settings, saving),
        const SizedBox(height: Spacing.md),
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
        _AboutSettingsGroup(
          packageInfo: ref.watch(packageInfoProvider),
          history: ref.watch(releaseHistoryProvider),
        ),
      ],
      SettingsSection.diagnostics || SettingsSection.logs => const [],
    };
  }

  Widget _buildCopilotSettings(AppSettings settings, bool saving) {
    final diagnosticsState = ref.watch(copilotDiagnosticsProvider);
    final diagnostics = diagnosticsState.value;
    final diagnosticsError = diagnosticsState.error;

    return SettingsGroup(
      title: 'GitHub Copilot (Experimental)',
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Enable GitHub Copilot'),
          subtitle: const Text(
            'Uses the bundled SDK sidecar and session-scoped quota RPC.',
          ),
          value: settings.copilotEnabled,
          onChanged: saving
              ? null
              : (enabled) {
                  unawaited(
                    _save(settings.copyWith(copilotEnabled: enabled)),
                  );
                },
        ),
        if (!settings.copilotEnabled)
          const Text(
            'Copilot is disabled. Enable it to run SDK, authentication, '
            'version, and quota diagnostics.',
          )
        else if (diagnosticsState.isLoading && diagnostics == null)
          const Row(
            children: [
              SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: Spacing.sm),
              Text('Checking Copilot integration…'),
            ],
          )
        else if (diagnosticsError != null && diagnostics == null)
          _InlineError(
            message: _diagnosticsErrorMessage(diagnosticsError),
            onRetry: () => unawaited(
              ref.read(copilotDiagnosticsProvider.notifier).retry(),
            ),
          )
        else if (diagnostics != null) ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('SDK / CLI version'),
            subtitle: Text(
              '${diagnostics.sdkVersion} / ${diagnostics.cliVersion}',
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Authentication'),
            trailing: Text(diagnostics.authStatus),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Quota RPC'),
            trailing: Text(diagnostics.quotaRpcStatus),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Experimental API'),
            trailing: Text(diagnostics.experimentalStatus),
          ),
        ],
        Wrap(
          spacing: Spacing.sm,
          runSpacing: Spacing.sm,
          children: [
            OutlinedButton(
              onPressed: diagnosticsState.isLoading
                  ? null
                  : () => unawaited(
                      ref.read(copilotDiagnosticsProvider.notifier).retry(),
                    ),
              child: const Text('Retry diagnostics'),
            ),
            OutlinedButton(
              onPressed: () => unawaited(_openCopilotSettings()),
              child: const Text('Open Copilot settings'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _openCopilotSettings() async {
    const url = 'https://github.com/settings/copilot';
    try {
      final command = Platform.isMacOS
          ? ('open', <String>[url])
          : Platform.isWindows
          ? ('cmd', <String>['/c', 'start', '', url])
          : ('xdg-open', <String>[url]);
      final result = await Process.run(
        command.$1,
        command.$2,
      ).timeout(const Duration(seconds: 5));
      if (result.exitCode != 0) {
        throw StateError('External settings could not be opened');
      }
    } on Object catch (_) {
      await Clipboard.setData(const ClipboardData(text: url));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open Copilot settings. The URL was copied.',
            ),
          ),
        );
    }
  }
}

final class _SettingsLoadState extends StatelessWidget {
  const _SettingsLoadState({
    required this.loading,
    required this.message,
    required this.onRetry,
  });

  final bool loading;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: Spacing.md),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

final class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Row(
        children: [
          Icon(Icons.error_outline, color: context.colors.error),
          const SizedBox(width: Spacing.sm),
          Expanded(child: Text(message)),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

/// Settings → About: live version/build + What’s New from release history.
final class _AboutSettingsGroup extends StatelessWidget {
  const _AboutSettingsGroup({
    required this.packageInfo,
    required this.history,
  });

  final AsyncValue<PackageInfo> packageInfo;
  final AsyncValue<ReleaseHistory> history;

  @override
  Widget build(BuildContext context) {
    final info = packageInfo.value;
    final releaseHistory = history.value;
    final version = info?.version;
    final current = version == null
        ? null
        : releaseHistory?.entryForVersion(version);
    final previous = version == null || releaseHistory == null
        ? const <ReleaseEntry>[]
        : releaseHistory.previousReleases(currentVersion: version);

    return SettingsGroup(
      title: 'About',
      children: [
        Text(
          'Terminal-inspired desktop companion for AI coding providers.',
          style: context.typography.caption,
        ),
        const SizedBox(height: Spacing.sm),
        if (packageInfo.isLoading && info == null)
          const InfoRow(label: 'Version', value: '…')
        else if (packageInfo.hasError && info == null)
          const InfoRow(label: 'Version', value: 'unavailable')
        else ...[
          InfoRow(
            label: 'Version',
            value: version == null ? '—' : 'AI Tray $version',
          ),
          InfoRow(
            label: 'Build',
            value: info?.buildNumber ?? '—',
          ),
          InfoRow(
            label: 'Released',
            value: current?.date ?? '—',
          ),
        ],
        const SizedBox(height: Spacing.md),
        Text('What’s New', style: context.typography.section),
        const SizedBox(height: Spacing.xs),
        if (history.isLoading && releaseHistory == null)
          Text('Loading release notes…', style: context.typography.caption)
        else if (history.hasError && releaseHistory == null)
          Text(
            'Release notes could not be loaded.',
            style: context.typography.caption.copyWith(
              color: context.colors.error,
            ),
          )
        else if (current == null || current.notesMarkdown.trim().isEmpty)
          Text(
            'No notes for this build yet. Edit CHANGELOG.md Unreleased '
            'before the next publish.',
            style: context.typography.caption,
          )
        else
          SelectableText(
            current.notesMarkdown,
            style: context.typography.monoData.copyWith(fontSize: 12),
          ),
        if (previous.isNotEmpty) ...[
          const SizedBox(height: Spacing.md),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: Text(
                'Previous releases',
                style: context.typography.section,
              ),
              children: [
                for (final entry in previous) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${entry.version} — ${entry.date}',
                      style: context.typography.monoData,
                    ),
                  ),
                  const SizedBox(height: Spacing.xs),
                  SelectableText(
                    entry.notesMarkdown,
                    style: context.typography.monoData.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: Spacing.md),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

String _settingsErrorMessage(Object? error) {
  if (error is AppFailure) return error.message;
  if (error is TimeoutException) {
    return 'Loading settings timed out. Please retry.';
  }
  if (error is StateError) return error.message;
  return 'Settings could not be loaded or saved. Please retry.';
}

String _diagnosticsErrorMessage(Object error) {
  if (error is TimeoutException) {
    return 'Copilot diagnostics timed out. Check the SDK and retry.';
  }
  return 'Copilot diagnostics failed safely. No secrets were included.';
}
