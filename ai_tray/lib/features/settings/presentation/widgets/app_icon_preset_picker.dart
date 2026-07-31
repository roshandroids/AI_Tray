import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:ai_tray/theme/app_icons.dart';
import 'package:flutter/material.dart';

/// Compact expandable app-icon grid (Launchpad-style tiles).
class AppIconPresetPicker extends StatelessWidget {
  const AppIconPresetPicker({
    required this.selected,
    required this.onChanged,
    required this.isSupported,
    required this.expanded,
    required this.onExpansionChanged,
    super.key,
  });

  final AppIconPreset selected;
  final ValueChanged<AppIconPreset> onChanged;
  final bool isSupported;
  final bool expanded;
  final ValueChanged<bool> onExpansionChanged;

  static const unsupportedMessage =
      'Changing the application icon is not currently supported '
      'on this platform.';

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      key: ValueKey('icon-$expanded'),
      initiallyExpanded: expanded,
      onExpansionChanged: onExpansionChanged,
      title: Text('App Icon', style: context.typography.body),
      subtitle: Text(selected.displayName, style: context.typography.caption),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            selected.previewAssetPath,
            width: 22,
            height: 22,
            filterQuality: FilterQuality.medium,
          ),
          const SizedBox(width: Spacing.xs),
          Icon(
            expanded ? Icons.expand_less : Icons.expand_more,
            size: 18,
            color: context.colors.textSecondary,
          ),
        ],
      ),
      children: [
        if (!isSupported) ...[
          Text(unsupportedMessage, style: context.typography.caption),
          const SizedBox(height: Spacing.sm),
        ],
        Opacity(
          opacity: isSupported ? 1 : 0.55,
          child: IgnorePointer(
            ignoring: !isSupported,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth < 320 ? 4 : 6;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: AppIconPresets.all.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: Spacing.sm,
                    crossAxisSpacing: Spacing.sm,
                    childAspectRatio: 0.9,
                  ),
                  itemBuilder: (context, index) {
                    final preset = AppIconPresets.all[index];
                    return _IconTile(
                      preset: preset,
                      selected: preset == selected,
                      onTap: () => onChanged(preset),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final AppIconPreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? context.colors.focus : context.colors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(Spacing.xs),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  preset.previewAssetPath,
                  width: 28,
                  height: 28,
                  filterQuality: FilterQuality.medium,
                ),
                const SizedBox(height: 2),
                Text(
                  preset.displayName,
                  style: context.typography.caption.copyWith(fontSize: 10),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
