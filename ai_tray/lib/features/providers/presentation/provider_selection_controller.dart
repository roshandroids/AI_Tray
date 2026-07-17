import 'package:ai_tray/features/providers/domain/models/provider_id.dart';
import 'package:ai_tray/features/providers/domain/ports/ai_provider.dart';
import 'package:ai_tray/features/providers/provider_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Owns the provider selected by shared presentation.
///
/// Mutations:
/// - [select] updates state only for registered, enabled providers.
/// - Invalid selections fail before UI state can become inconsistent.
final class ProviderSelectionNotifier extends Notifier<ProviderId> {
  @override
  ProviderId build() {
    return ref.watch(providerRegistryProvider).defaultProvider.providerId;
  }

  void select(ProviderId providerId) {
    final provider = ref
        .read(providerRegistryProvider)
        .requireEnabled(
          providerId,
        );
    if (state == provider.providerId) return;
    state = provider.providerId;
  }
}

/// Feature-scoped selected provider identifier.
final selectedProviderIdProvider =
    NotifierProvider<ProviderSelectionNotifier, ProviderId>(
      ProviderSelectionNotifier.new,
    );

/// Selected enabled provider metadata consumed by shared UI.
final selectedAIProviderProvider = Provider<AIProvider>((ref) {
  final selectedId = ref.watch(selectedProviderIdProvider);
  return ref.watch(providerRegistryProvider).requireEnabled(selectedId);
});
