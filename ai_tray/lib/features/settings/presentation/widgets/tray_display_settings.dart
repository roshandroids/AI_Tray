import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:ai_tray/features/settings/domain/models/app_settings.dart';
import 'package:ai_tray/features/settings/presentation/widgets/theme_mode_picker.dart';
import 'package:ai_tray/features/tray/domain/tray_display_mode.dart';
import 'package:flutter/material.dart';

/// Appearance controls for menu-bar title density.
class TrayDisplaySettingsGroup extends StatelessWidget {
  const TrayDisplaySettingsGroup({
    required this.mode,
    required this.threshold,
    required this.onModeChanged,
    required this.onThresholdChanged,
    this.enabled = true,
    super.key,
  });

  final TrayDisplayMode mode;
  final double threshold;
  final ValueChanged<TrayDisplayMode> onModeChanged;
  final ValueChanged<double> onThresholdChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Adaptive keeps the bar quiet and reveals % when usage is high.',
          style: context.typography.caption,
        ),
        const SizedBox(height: Spacing.sm),
        for (final value in TrayDisplayMode.values)
          Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: enabled ? () => onModeChanged(value) : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            value.displayName,
                            style: context.typography.body.copyWith(
                              fontWeight: value == mode
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: value == mode
                                  ? context.colors.purpleAccent
                                  : context.colors.textPrimary,
                            ),
                          ),
                          Text(
                            value.description,
                            style: context.typography.caption,
                          ),
                        ],
                      ),
                    ),
                    SelectionCheck(selected: value == mode),
                  ],
                ),
              ),
            ),
          ),
        if (mode == TrayDisplayMode.adaptive) ...[
          const SizedBox(height: Spacing.sm),
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text('Reveal at', style: context.typography.body),
            subtitle: Text(
              'Show session % beside the icon at or above this level.',
              style: context.typography.caption,
            ),
            trailing: DropdownButton<double>(
              value: threshold,
              underline: const SizedBox.shrink(),
              dropdownColor: context.colors.surfaceAlt,
              style: context.typography.body,
              items: const [
                DropdownMenuItem(value: 75, child: Text('75%')),
                DropdownMenuItem(value: 90, child: Text('90%')),
                DropdownMenuItem(value: 95, child: Text('95%')),
              ],
              onChanged: enabled
                  ? (value) {
                      if (value != null) onThresholdChanged(value);
                    }
                  : null,
            ),
          ),
        ],
      ],
    );
  }
}

/// Convenience: thresholds offered in Settings.
abstract final class TrayDisplayThresholdOptions {
  static const values = <double>[75, 90, 95];

  static double coerce(double value) {
    if (values.contains(value)) return value;
    return AppSettings.defaultTrayPercentThreshold;
  }
}
