import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:flutter/material.dart';

/// Settings navigation item for the left rail (PD-021).
///
/// Every section here renders in-place in the content pane (V3) — tools
/// that aren't really "settings" (Diagnostics, Logs, About) live under
/// [SettingsSection.advanced] as plain navigation rows instead of rail
/// items, so the rail never mixes in-place sections with ones that
/// silently push a different page.
enum SettingsSection {
  appearance,
  refresh,
  notifications,
  behavior,
  cli,
  advanced,
}

extension SettingsSectionLabel on SettingsSection {
  String get label => switch (this) {
    SettingsSection.appearance => 'Appearance',
    SettingsSection.refresh => 'Refresh',
    SettingsSection.notifications => 'Notifications',
    SettingsSection.behavior => 'App Behavior',
    SettingsSection.cli => 'CLI',
    SettingsSection.advanced => 'Advanced',
  };

  IconData get icon => switch (this) {
    SettingsSection.appearance => Icons.palette_outlined,
    SettingsSection.refresh => Icons.sync_outlined,
    SettingsSection.notifications => Icons.notifications_outlined,
    SettingsSection.behavior => Icons.tune_outlined,
    SettingsSection.cli => Icons.terminal_outlined,
    SettingsSection.advanced => Icons.build_outlined,
  };

  /// Extra keywords a global settings search matches against, beyond
  /// [label] itself.
  List<String> get searchKeywords => switch (this) {
    SettingsSection.appearance => const [
      'theme',
      'color',
      'font',
      'icon',
      'dark mode',
      'light mode',
      'tray icon',
      'menu bar',
    ],
    SettingsSection.refresh => const ['interval', 'auto refresh', 'polling'],
    SettingsSection.notifications => const [
      'alert',
      'session percent',
      'threshold',
    ],
    SettingsSection.behavior => const [
      'launch at login',
      'startup',
      'stale indicator',
      'cached',
    ],
    SettingsSection.cli => const ['binary', 'executable', 'path'],
    SettingsSection.advanced => const [
      'diagnostics',
      'logs',
      'about',
      'version',
      'copilot',
      'force refresh',
    ],
  };
}

/// Compact left navigation rail for Settings, with a search field that
/// narrows the visible sections by label or keyword (V3 "global settings
/// search").
final class SettingsNavRail extends StatefulWidget {
  const SettingsNavRail({
    required this.selected,
    required this.onSelect,
    super.key,
  });

  final SettingsSection selected;
  final ValueChanged<SettingsSection> onSelect;

  @override
  State<SettingsNavRail> createState() => _SettingsNavRailState();
}

final class _SettingsNavRailState extends State<SettingsNavRail> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final query = _search.text.trim().toLowerCase();
    final sections = query.isEmpty
        ? SettingsSection.values
        : [
            for (final section in SettingsSection.values)
              if (section.label.toLowerCase().contains(query) ||
                  section.searchKeywords.any((k) => k.contains(query)))
                section,
          ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(right: BorderSide(color: colors.border)),
      ),
      child: SizedBox(
        width: Spacing.settingsRailWidth,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(Spacing.sm),
              child: TextField(
                key: const ValueKey('settings-search-field'),
                controller: _search,
                style: context.typography.caption,
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'Search settings…',
                  prefixIcon: Icon(Icons.search, size: 14),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            Expanded(
              child: sections.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(Spacing.sm),
                      child: Text(
                        'No matching settings.',
                        style: context.typography.caption,
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                      children: [
                        for (final section in sections)
                          _RailItem(
                            section: section,
                            selected: section == widget.selected,
                            onTap: () => widget.onSelect(section),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.section,
    required this.selected,
    required this.onTap,
  });

  final SettingsSection section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = selected ? colors.success : colors.textSecondary;
    return Material(
      color: selected
          ? colors.success.withValues(alpha: 0.08)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: colors.surfaceAlt,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: selected ? colors.success : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.sm,
            vertical: Spacing.sm,
          ),
          child: Row(
            children: [
              Icon(section.icon, size: 16, color: color),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  section.label,
                  style: context.typography.label.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
