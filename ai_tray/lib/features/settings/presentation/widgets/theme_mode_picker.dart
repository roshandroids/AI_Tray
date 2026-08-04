import 'package:ai_tray/core/theme/app_theme_mode.dart';
import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:flutter/material.dart';

/// Compact segmented control for system / light / dark theme mode.
class ThemeModePicker extends StatelessWidget {
  const ThemeModePicker({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final AppThemePreference selected;
  final ValueChanged<AppThemePreference> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<AppThemePreference>(
      segments: const [
        ButtonSegment(
          value: AppThemePreference.system,
          label: Text('System'),
          icon: Icon(Icons.brightness_auto_outlined, size: 16),
        ),
        ButtonSegment(
          value: AppThemePreference.dark,
          label: Text('Dark'),
          icon: Icon(Icons.dark_mode_outlined, size: 16),
        ),
        ButtonSegment(
          value: AppThemePreference.light,
          label: Text('Light'),
          icon: Icon(Icons.light_mode_outlined, size: 16),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (selected) {
        if (selected.isEmpty) return;
        onChanged(selected.first);
      },
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

/// Shared dense search field for personalization pickers.
class PersonalizationSearchField extends StatelessWidget {
  const PersonalizationSearchField({
    required this.controller,
    required this.hintText,
    this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: context.typography.body,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search, size: 16),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm,
          vertical: Spacing.xs,
        ),
      ),
    );
  }
}

/// Small selection checkmark for the active option.
class SelectionCheck extends StatelessWidget {
  const SelectionCheck({required this.selected, super.key});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    if (!selected) return const SizedBox(width: 16, height: 16);
    return Icon(
      Icons.check_circle,
      size: 16,
      color: context.colors.success,
    );
  }
}

/// Which Appearance expandable section is open (accordion).
enum AppearanceExpandedSection {
  none,
  colorTheme,
  font,
  appIcon,
}
