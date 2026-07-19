import 'package:ai_tray/core/theme/spacing.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:ai_tray/features/providers/domain/models/provider_id.dart';
import 'package:ai_tray/features/providers/domain/ports/ai_provider.dart';
import 'package:flutter/material.dart';

/// Compact selector for enabled AI providers.
///
/// Data Source:
/// - Receives an already-filtered list from the provider registry.
///
/// Side Effects:
/// - Reports selection through [onSelected]; business validation remains in
///   the provider selection notifier.
final class ProviderSelector extends StatelessWidget {
  const ProviderSelector({
    required this.providers,
    required this.selectedId,
    required this.onSelected,
    this.enabled = true,
    super.key,
  });

  final List<AIProvider> providers;
  final ProviderId selectedId;
  final ValueChanged<ProviderId> onSelected;

  /// When false, the dropdown is disabled (e.g. while selection is saving).
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final canChange = enabled && providers.length > 1;
    return Semantics(
      label: 'AI provider',
      enabled: canChange,
      button: true,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ProviderId>(
          value: selectedId,
          isDense: true,
          borderRadius: BorderRadius.circular(RadiusTokens.md),
          dropdownColor: context.colors.surface,
          style: context.typography.label,
          icon: const Icon(Icons.expand_more, size: 16),
          onChanged: canChange
              ? (providerId) {
                  if (providerId != null) onSelected(providerId);
                }
              : null,
          items: [
            for (final provider in providers)
              DropdownMenuItem(
                value: provider.providerId,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(provider.displayName),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
