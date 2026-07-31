import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:ai_tray/features/settings/presentation/widgets/theme_mode_picker.dart';
import 'package:ai_tray/theme/font_presets.dart';
import 'package:flutter/material.dart';

/// Searchable font preset list with live typography preview.
class FontPresetPicker extends StatefulWidget {
  const FontPresetPicker({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final FontPreset selected;
  final ValueChanged<FontPreset> onChanged;

  @override
  State<FontPresetPicker> createState() => _FontPresetPickerState();
}

class _FontPresetPickerState extends State<FontPresetPicker> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.text.trim().toLowerCase();
    final presets = FontPreset.values.where((p) {
      if (q.isEmpty) return true;
      return p.displayName.toLowerCase().contains(q) ||
          p.recommendedForLabel.toLowerCase().contains(q);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PersonalizationSearchField(
          controller: _query,
          hintText: 'Search fonts',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: Spacing.sm),
        PickerDescription(
          '${widget.selected.displayName} · '
          '${widget.selected.recommendedForLabel}'
          '${widget.selected.isBundled ? '' : ' · system fallback'}',
        ),
        for (final preset in presets)
          Material(
            type: MaterialType.transparency,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                preset.displayName,
                style: context.typography.body.copyWith(
                  fontFamily: preset.fontFamily,
                  fontFamilyFallback: preset.fontFamilyFallback,
                ),
              ),
              subtitle: Text(
                preset.previewText,
                style: context.typography.caption.copyWith(
                  fontFamily: preset.fontFamily,
                  fontFamilyFallback: preset.fontFamilyFallback,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    preset.recommendedForLabel,
                    style: context.typography.caption,
                  ),
                  const SizedBox(width: Spacing.sm),
                  SelectionCheck(selected: preset == widget.selected),
                ],
              ),
              onTap: () => widget.onChanged(preset),
            ),
          ),
      ],
    );
  }
}
