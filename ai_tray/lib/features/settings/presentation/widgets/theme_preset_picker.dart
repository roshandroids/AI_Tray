import 'package:ai_tray/core/components/tray_accordion.dart';
import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:ai_tray/features/settings/presentation/widgets/theme_mode_picker.dart';
import 'package:ai_tray/theme/theme_presets.dart';
import 'package:flutter/material.dart';

/// Compact expandable color-theme picker with palette-strip previews.
class ThemePresetPicker extends StatefulWidget {
  const ThemePresetPicker({
    required this.selected,
    required this.onChanged,
    required this.expanded,
    required this.onExpansionChanged,
    super.key,
  });

  final ThemePreset selected;
  final ValueChanged<ThemePreset> onChanged;
  final bool expanded;
  final ValueChanged<bool> onExpansionChanged;

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
    final brightness = Theme.of(context).brightness;
    final q = _query.text.trim().toLowerCase();
    final presets = ThemePreset.values.where((p) {
      if (q.isEmpty) return true;
      return p.displayName.toLowerCase().contains(q);
    }).toList();

    return TrayAccordion(
      title: 'Color Theme',
      subtitle: widget.selected.displayName,
      isExpanded: widget.expanded,
      onExpandedChanged: widget.onExpansionChanged,
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      trailing: _PaletteStrip(
        colors: widget.selected.paletteFor(brightness).previewStrip,
        width: 72,
      ),
      bodyBuilder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PersonalizationSearchField(
            controller: _query,
            hintText: 'Search themes',
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _PaletteStrip(
                              colors: preset
                                  .paletteFor(brightness)
                                  .previewStrip,
                              height: 28,
                            ),
                            const SizedBox(height: Spacing.sm),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    preset.displayName,
                                    style: context.typography.body.copyWith(
                                      fontWeight: selected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: selected
                                          ? context.colors.purpleAccent
                                          : context.colors.textPrimary,
                                    ),
                                  ),
                                ),
                                SelectionCheck(selected: selected),
                              ],
                            ),
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

class _PaletteStrip extends StatelessWidget {
  const _PaletteStrip({required this.colors, this.width, this.height = 14});

  final List<Color> colors;
  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Row(
          children: [
            for (final color in colors)
              Expanded(
                child: ColoredBox(color: color),
              ),
          ],
        ),
      ),
    );
  }
}
