import 'package:meta/meta.dart';

/// One provider-supplied weekly or scoped usage bucket.
@immutable
final class WeeklyUsage {
  factory WeeklyUsage({
    required String label,
    required double usedPercent,
    DateTime? resetsAt,
    String? resetsAtRaw,
  }) {
    return WeeklyUsage._(
      label: label.trim(),
      usedPercent: _requirePercent(usedPercent, 'usedPercent'),
      resetsAt: resetsAt,
      resetsAtRaw: resetsAtRaw,
    );
  }

  const WeeklyUsage._({
    required this.label,
    required this.usedPercent,
    required this.resetsAt,
    required this.resetsAtRaw,
  });

  final String label;
  final double usedPercent;
  final DateTime? resetsAt;
  final String? resetsAtRaw;

  WeeklyUsage copyWith({
    String? label,
    double? usedPercent,
    DateTime? resetsAt,
    String? resetsAtRaw,
  }) {
    return WeeklyUsage(
      label: label ?? this.label,
      usedPercent: usedPercent ?? this.usedPercent,
      resetsAt: resetsAt ?? this.resetsAt,
      resetsAtRaw: resetsAtRaw ?? this.resetsAtRaw,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is WeeklyUsage &&
        other.label == label &&
        other.usedPercent == usedPercent &&
        other.resetsAt == resetsAt &&
        other.resetsAtRaw == resetsAtRaw;
  }

  @override
  int get hashCode => Object.hash(label, usedPercent, resetsAt, resetsAtRaw);
}

double _requirePercent(double value, String name) {
  if (value.isNaN || value < 0 || value > 100) {
    throw ArgumentError.value(value, name, 'must be between 0 and 100');
  }
  return value;
}
