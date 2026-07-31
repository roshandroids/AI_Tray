import 'package:ai_tray/core/theme/app_theme_mode.dart';
import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:flutter/material.dart';

/// Segmented control for system / light / dark theme mode.
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
      selected: {selected},
      onSelectionChanged: (selected) {
        if (selected.isEmpty) return;
        onChanged(selected.first);
      },
    );
  }
}

/// Shared search field used by personalization pickers.
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
        prefixIcon: const Icon(Icons.search, size: 18),
        isDense: true,
      ),
    );
  }
}

/// Selection checkmark for the active personalization option.
class SelectionCheck extends StatelessWidget {
  const SelectionCheck({required this.selected, super.key});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    if (!selected) return const SizedBox(width: 20);
    return Icon(
      Icons.check_circle,
      size: 18,
      color: context.colors.success,
    );
  }
}

/// Compact description under a picker title.
class PickerDescription extends StatelessWidget {
  const PickerDescription(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Text(text, style: context.typography.caption),
    );
  }
}
