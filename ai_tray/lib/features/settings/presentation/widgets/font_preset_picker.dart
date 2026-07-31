import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:ai_tray/features/settings/presentation/widgets/theme_mode_picker.dart';
import 'package:ai_tray/theme/font_presets.dart';
import 'package:flutter/material.dart';

/// Compact expandable font picker with inline family previews.
class FontPresetPicker extends StatefulWidget {
  const FontPresetPicker({
    required this.selected,
    required this.onChanged,
    required this.expanded,
    required this.onExpansionChanged,
    super.key,
  });

  final FontPreset selected;
  final ValueChanged<FontPreset> onChanged;
  final bool expanded;
  final ValueChanged<bool> onExpansionChanged;

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

    return ExpansionTile(
      key: ValueKey('font-${widget.expanded}'),
      initiallyExpanded: widget.expanded,
      onExpansionChanged: widget.onExpansionChanged,
      title: Text('Font', style: context.typography.body),
      subtitle: Text(
        widget.selected.displayName,
        style: context.typography.caption.copyWith(
          fontFamily: widget.selected.fontFamily,
          fontFamilyFallback: widget.selected.fontFamilyFallback,
        ),
      ),
      children: [
        PersonalizationSearchField(
          controller: _query,
          hintText: 'Search fonts',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: Spacing.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: presets.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: context.colors.border,
            ),
            itemBuilder: (context, index) {
              final preset = presets[index];
              final selected = preset == widget.selected;
              return Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: () => widget.onChanged(preset),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                preset.displayName,
                                style: context.typography.body.copyWith(
                                  fontFamily: preset.fontFamily,
                                  fontFamilyFallback: preset.fontFamilyFallback,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                              Text(
                                preset.previewText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.typography.caption.copyWith(
                                  fontFamily: preset.fontFamily,
                                  fontFamilyFallback: preset.fontFamilyFallback,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          preset.recommendedForLabel,
                          style: context.typography.caption,
                        ),
                        const SizedBox(width: Spacing.sm),
                        SelectionCheck(selected: selected),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
