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

    return ExpansionTile(
      key: ValueKey('theme-${widget.expanded}'),
      initiallyExpanded: widget.expanded,
      onExpansionChanged: widget.onExpansionChanged,
      title: Text('Color Theme', style: context.typography.body),
      subtitle: Text(
        widget.selected.displayName,
        style: context.typography.caption,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PaletteStrip(
            colors: widget.selected.paletteFor(brightness).previewStrip,
            width: 72,
          ),
          const SizedBox(width: Spacing.xs),
          Icon(
            widget.expanded ? Icons.expand_less : Icons.expand_more,
            size: 18,
            color: context.colors.textSecondary,
          ),
        ],
      ),
      children: [
        PersonalizationSearchField(
          controller: _query,
          hintText: 'Search themes',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: Spacing.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 220),
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
                        _PaletteStrip(
                          colors: preset.paletteFor(brightness).previewStrip,
                          width: 88,
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

class _PaletteStrip extends StatelessWidget {
  const _PaletteStrip({required this.colors, required this.width});

  final List<Color> colors;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 14,
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
