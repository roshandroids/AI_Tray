import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:ai_tray/features/settings/presentation/widgets/theme_mode_picker.dart';
import 'package:ai_tray/theme/theme_presets.dart';
import 'package:flutter/material.dart';

/// Searchable theme preset list with live color previews.
class ThemePresetPicker extends StatefulWidget {
  const ThemePresetPicker({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final ThemePreset selected;
  final ValueChanged<ThemePreset> onChanged;

  @override
  State<ThemePresetPicker> createState() => _ThemePresetPickerState();
}

class _ThemePresetPickerState extends State<ThemePresetPicker> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.text.trim().toLowerCase();
    final presets = ThemePreset.values.where((p) {
      if (q.isEmpty) return true;
      return p.displayName.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PersonalizationSearchField(
          controller: _query,
          hintText: 'Search themes',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: Spacing.sm),
        PickerDescription(widget.selected.description),
        for (final preset in presets)
          Material(
            type: MaterialType.transparency,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: preset.previewColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.colors.border),
                ),
              ),
              title: Text(preset.displayName, style: context.typography.body),
              subtitle: Text(
                preset.description,
                style: context.typography.caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: SelectionCheck(selected: preset == widget.selected),
              onTap: () => widget.onChanged(preset),
            ),
          ),
      ],
    );
  }
}
