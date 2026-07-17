import 'package:ai_tray/features/providers/core/models/provider_id.dart';

/// Bounded in-memory cache for provider health and compatibility metadata.
///
/// Successful loads are cached by provider, concurrent loads are coalesced,
/// and failures are never retained. This cache intentionally excludes quota
/// snapshots, which use the durable provider-scoped usage cache.
final class ProviderMetadataCache<T> {
  ProviderMetadataCache({
    this.ttl = const Duration(minutes: 5),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    if (ttl.isNegative) {
      throw ArgumentError.value(ttl, 'ttl', 'must not be negative');
    }
  }

  final Duration ttl;
  final DateTime Function() _clock;
  final Map<ProviderId, _MetadataEntry<T>> _entries = {};
  final Map<ProviderId, Future<T>> _inFlight = {};

  /// Returns valid metadata or loads it once for all concurrent callers.
  Future<T> getOrLoad(
    ProviderId providerId,
    Future<T> Function() loader, {
    bool forceRefresh = false,
  }) {
    if (!forceRefresh) {
      final cached = read(providerId);
      if (cached != null) return Future.value(cached);
      final existing = _inFlight[providerId];
      if (existing != null) return existing;
    }

    final future = loader().then((value) {
      _entries[providerId] = _MetadataEntry(
        value: value,
        expiresAt: _clock().toUtc().add(ttl),
      );
      return value;
    });
    _inFlight[providerId] = future;
    return future.whenComplete(() {
      if (identical(_inFlight[providerId], future)) {
        _inFlight.remove(providerId);
      }
    });
  }

  /// Reads unexpired metadata without triggering external work.
  T? read(ProviderId providerId) {
    final entry = _entries[providerId];
    if (entry == null) return null;
    if (!_clock().toUtc().isBefore(entry.expiresAt)) {
      _entries.remove(providerId);
      return null;
    }
    return entry.value;
  }

  /// Removes metadata for one provider or all providers.
  void invalidate([ProviderId? providerId]) {
    if (providerId == null) {
      _entries.clear();
      return;
    }
    _entries.remove(providerId);
  }
}

final class _MetadataEntry<T> {
  const _MetadataEntry({required this.value, required this.expiresAt});

  final T value;
  final DateTime expiresAt;
}
