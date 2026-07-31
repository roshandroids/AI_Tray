import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:flutter/material.dart';

/// Settings navigation item for the left rail (PD-021).
enum SettingsSection {
  appearance,
  refresh,
  notifications,
  behavior,
  cli,
  diagnostics,
  logs,
  advanced,
  about,
}

extension SettingsSectionLabel on SettingsSection {
  String get label => switch (this) {
    SettingsSection.appearance => 'Appearance',
    SettingsSection.refresh => 'Refresh',
    SettingsSection.notifications => 'Notifications',
    SettingsSection.behavior => 'App Behavior',
    SettingsSection.cli => 'CLI',
    SettingsSection.diagnostics => 'Diagnostics',
    SettingsSection.logs => 'Logs',
    SettingsSection.advanced => 'Advanced',
    SettingsSection.about => 'About',
  };

  IconData get icon => switch (this) {
    SettingsSection.appearance => Icons.palette_outlined,
    SettingsSection.refresh => Icons.sync_outlined,
    SettingsSection.notifications => Icons.notifications_outlined,
    SettingsSection.behavior => Icons.tune_outlined,
    SettingsSection.cli => Icons.terminal_outlined,
    SettingsSection.diagnostics => Icons.monitor_heart_outlined,
    SettingsSection.logs => Icons.article_outlined,
    SettingsSection.advanced => Icons.build_outlined,
    SettingsSection.about => Icons.info_outline,
  };
}

/// Compact left navigation rail for Settings.
final class SettingsNavRail extends StatelessWidget {
  const SettingsNavRail({
    required this.selected,
    required this.onSelect,
    super.key,
  });

  final SettingsSection selected;
  final ValueChanged<SettingsSection> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(right: BorderSide(color: colors.border)),
      ),
      child: SizedBox(
        width: Spacing.settingsRailWidth,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
          children: [
            for (final section in SettingsSection.values)
              _RailItem(
                section: section,
                selected: section == selected,
                onTap: () => onSelect(section),
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

/// Settings group title + children.
final class SettingsGroup extends StatelessWidget {
  const SettingsGroup({
    required this.title,
    required this.children,
    super.key,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title.toUpperCase(),
          style: context.typography.section.copyWith(
            fontSize: 12,
            letterSpacing: 0.8,
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Material(
          color: context.colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RadiusTokens.md),
            side: BorderSide(color: context.colors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    Divider(height: Spacing.md, color: context.colors.border),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
