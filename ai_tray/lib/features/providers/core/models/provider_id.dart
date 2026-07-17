import 'package:meta/meta.dart';

/// Stable identifier for a provider implementation.
@immutable
final class ProviderId {
  factory ProviderId(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(value, 'value', 'must not be empty');
    }
    return ProviderId._(normalized);
  }

  const ProviderId._(this.value);

  static const claude = ProviderId._('claude');
  static const copilot = ProviderId._('copilot');

  final String value;

  @override
  bool operator ==(Object other) => other is ProviderId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'ProviderId($value)';
}
