import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:ai_tray/features/settings/presentation/widgets/theme_mode_picker.dart';
import 'package:ai_tray/theme/app_icons.dart';
import 'package:flutter/material.dart';

/// App icon grid with live previews; disabled when platform unsupported.
class AppIconPresetPicker extends StatelessWidget {
  const AppIconPresetPicker({
    required this.selected,
    required this.onChanged,
    required this.isSupported,
    super.key,
  });

  final AppIconPreset selected;
  final ValueChanged<AppIconPreset> onChanged;
  final bool isSupported;

  static const unsupportedMessage =
      'Changing the application icon is not currently supported '
      'on this platform.';

  @override
  Widget build(BuildContext context) {
    final grid = GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: Spacing.sm,
      crossAxisSpacing: Spacing.sm,
      childAspectRatio: 0.85,
      children: [
        for (final preset in AppIconPresets.all)
          _IconTile(
            preset: preset,
            selected: preset == selected,
            enabled: isSupported,
            onTap: () => onChanged(preset),
          ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PickerDescription(selected.description),
        if (!isSupported) ...[
          Container(
            padding: const EdgeInsets.all(Spacing.sm),
            decoration: BoxDecoration(
              color: context.colors.surfaceAlt,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: context.colors.border),
            ),
            child: Text(
              unsupportedMessage,
              style: context.typography.caption,
            ),
          ),
          const SizedBox(height: Spacing.sm),
        ],
        if (isSupported)
          grid
        else
          Opacity(
            opacity: 0.55,
            child: IgnorePointer(child: grid),
          ),
      ],
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.preset,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final AppIconPreset preset;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected ? context.colors.focus : context.colors.border,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                preset.previewAssetPath,
                width: 40,
                height: 40,
                filterQuality: FilterQuality.medium,
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                preset.displayName,
                style: context.typography.caption,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SelectionCheck(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}
