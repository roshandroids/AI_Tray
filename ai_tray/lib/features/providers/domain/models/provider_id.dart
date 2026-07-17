import 'package:meta/meta.dart';

/// Identifies an AI provider in the platform.
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

  /// Claude Code / Claude.ai subscription usage (MVP).
  static const claude = ProviderId._('claude');

  /// GitHub Copilot placeholder; disabled until parsing is implemented.
  static const copilot = ProviderId._('copilot');

  final String value;

  @override
  bool operator ==(Object other) => other is ProviderId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'ProviderId($value)';
}
