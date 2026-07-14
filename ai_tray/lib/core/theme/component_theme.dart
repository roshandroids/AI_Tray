import 'package:ai_tray/core/theme/color_tokens.dart';
import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/typography.dart';
import 'package:flutter/material.dart';

/// Shared component-level theme helpers (PD-021).
///
/// Prefer these over one-off [BoxDecoration] / button styles in feature UIs.
abstract final class ComponentTheme {
  static BoxDecoration panel(TrayColorTokens colors) {
    return BoxDecoration(
      color: colors.surface,
      borderRadius: BorderRadius.circular(RadiusTokens.md),
      border: Border.all(color: colors.border),
    );
  }

  static BoxDecoration panelAlt(TrayColorTokens colors) {
    return BoxDecoration(
      color: colors.surfaceAlt,
      borderRadius: BorderRadius.circular(RadiusTokens.md),
      border: Border.all(color: colors.border),
    );
  }

  static ButtonStyle outlinedAction({
    required TrayColorTokens colors,
    required TrayTypography typography,
  }) {
    return OutlinedButton.styleFrom(
      foregroundColor: colors.textPrimary,
      side: BorderSide(color: colors.border),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      textStyle: typography.caption,
    );
  }
}
