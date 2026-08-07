import 'package:ai_tray/core/components/tray_accordion.dart';
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

    return TrayAccordion(
      title: 'Font',
      subtitle: widget.selected.displayName,
      isExpanded: widget.expanded,
      onExpandedChanged: widget.onExpansionChanged,
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      bodyBuilder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PersonalizationSearchField(
            controller: _query,
            hintText: 'Search fonts',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Spacing.sm),
          // No height cap: `shrinkWrap` sizes to content and the outer
          // Settings page is itself scrollable, so a tall preview-card list
          // doesn't need its own nested scroll region.
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: presets.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: context.colors.border,
            ),
            itemBuilder: (context, index) {
              final preset = presets[index];
              final selected = preset == widget.selected;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(RadiusTokens.md),
                    border: Border.all(
                      color: selected
                          ? context.colors.purpleAccent
                          : context.colors.border,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(RadiusTokens.md),
                      onTap: () => widget.onChanged(preset),
                      child: Padding(
                        padding: const EdgeInsets.all(Spacing.sm),
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
                                      fontFamilyFallback:
                                          preset.fontFamilyFallback,
                                      fontWeight: selected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: selected
                                          ? context.colors.purpleAccent
                                          : context.colors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    preset.previewText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.typography.body.copyWith(
                                      fontSize: 16,
                                      fontFamily: preset.fontFamily,
                                      fontFamilyFallback:
                                          preset.fontFamilyFallback,
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
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
