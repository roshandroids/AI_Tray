import 'dart:collection';

import 'package:ai_tray/features/providers/core/models/provider_id.dart';
import 'package:ai_tray/features/providers/core/ports/provider_ports.dart';

/// Immutable, insertion-ordered catalog of provider implementations.
final class ProviderRegistry {
  ProviderRegistry({
    required Iterable<AIProvider> providers,
    required ProviderId defaultProviderId,
  }) : _defaultProviderId = defaultProviderId,
       _providers = _index(providers) {
    final defaultProvider = _providers[_defaultProviderId];
    if (defaultProvider == null) {
      throw ArgumentError.value(
        defaultProviderId,
        'defaultProviderId',
        'must reference a registered provider',
      );
    }
    if (!defaultProvider.enabled) {
      throw ArgumentError.value(
        defaultProviderId,
        'defaultProviderId',
        'must reference an enabled provider',
      );
    }
  }

  final Map<ProviderId, AIProvider> _providers;
  final ProviderId _defaultProviderId;

  UnmodifiableListView<AIProvider> get providers {
    return UnmodifiableListView(_providers.values);
  }

  UnmodifiableListView<AIProvider> get enabledProviders {
    return UnmodifiableListView(
      _providers.values.where((provider) => provider.enabled),
    );
  }

  AIProvider get defaultProvider => _providers[_defaultProviderId]!;

  AIProvider? find(ProviderId id) => _providers[id];

  AIProvider requireEnabled(ProviderId id) {
    final provider = _providers[id];
    if (provider == null) {
      throw StateError('Provider "${id.value}" is not registered');
    }
    if (!provider.enabled) {
      throw StateError('Provider "${id.value}" is disabled');
    }
    return provider;
  }

  static Map<ProviderId, AIProvider> _index(Iterable<AIProvider> providers) {
    final indexed = <ProviderId, AIProvider>{};
    for (final provider in providers) {
      if (indexed.containsKey(provider.providerId)) {
        throw ArgumentError(
          'Duplicate provider identifier "${provider.providerId.value}"',
        );
      }
      indexed[provider.providerId] = provider;
    }
    return Map.unmodifiable(indexed);
  }
}
