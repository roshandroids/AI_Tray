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
    super.key,
  });

  final List<AIProvider> providers;
  final ProviderId selectedId;
  final ValueChanged<ProviderId> onSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'AI provider',
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ProviderId>(
          value: selectedId,
          isDense: true,
          borderRadius: BorderRadius.circular(RadiusTokens.md),
          dropdownColor: context.colors.surface,
          style: context.typography.label,
          icon: const Icon(Icons.expand_more, size: 16),
          onChanged: providers.length <= 1
              ? null
              : (providerId) {
                  if (providerId != null) onSelected(providerId);
                },
          items: [
            for (final provider in providers)
              DropdownMenuItem(
                value: provider.providerId,
                child: Text(provider.displayName),
              ),
          ],
        ),
      ),
    );
  }
}
