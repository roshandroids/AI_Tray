import 'package:meta/meta.dart';

/// Persisted size/collapse state for one `ResizablePanel`.
@immutable
final class PanelLayoutState {
  const PanelLayoutState({required this.heightPx, required this.isExpanded});

  final double heightPx;
  final bool isExpanded;

  Map<String, Object?> toJson() {
    return {'heightPx': heightPx, 'isExpanded': isExpanded};
  }

  /// Tolerant deserialization (design principle 4) — returns `null`
  /// rather than throwing on a malformed or missing field.
  static PanelLayoutState? tryFromJson(Map<String, Object?> json) {
    final heightPx = json['heightPx'];
    final isExpanded = json['isExpanded'];
    if (heightPx is! num || isExpanded is! bool) return null;
    return PanelLayoutState(
      heightPx: heightPx.toDouble(),
      isExpanded: isExpanded,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PanelLayoutState &&
        other.heightPx == heightPx &&
        other.isExpanded == isExpanded;
  }

  @override
  int get hashCode => Object.hash(heightPx, isExpanded);

  @override
  String toString() =>
      'PanelLayoutState(heightPx: $heightPx, isExpanded: $isExpanded)';
}
