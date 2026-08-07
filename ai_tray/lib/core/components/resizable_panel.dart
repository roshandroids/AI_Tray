import 'package:ai_tray/core/components/tray_accordion.dart';
import 'package:ai_tray/core/theme/theme_context.dart';
import 'package:ai_tray/features/layout/domain/models/panel_layout_state.dart';
import 'package:flutter/material.dart';

/// A `TrayAccordion` panel whose expanded body height can be dragged, with
/// the height and expanded/collapsed state persisted across launches.
///
/// Plain [StatefulWidget] with no Riverpod dependency, matching
/// `SectionCard`/`PageHeader`/`TrayAccordion` — the caller loads
/// [initialState] (e.g. from `panelLayoutRepositoryProvider`) and persists
/// via [onStateChanged].
final class ResizablePanel extends StatefulWidget {
  const ResizablePanel({
    required this.panelId,
    required this.title,
    required this.bodyBuilder,
    required this.onStateChanged,
    super.key,
    this.initialState,
    this.subtitle,
    this.headerStyle = AccordionHeaderStyle.sectionLabel,
    this.minHeight = 160.0,
    this.maxHeightFraction = 0.5,
    this.defaultHeight = 240.0,
    this.defaultExpanded = false,
  });

  /// Persistence key, e.g. `'session_detail.queue_task'`.
  final String panelId;
  final String title;
  final String? subtitle;
  final WidgetBuilder bodyBuilder;
  final AccordionHeaderStyle headerStyle;

  /// `null` on first launch, or while still loading — falls back to
  /// [defaultHeight]/[defaultExpanded].
  final PanelLayoutState? initialState;
  final ValueChanged<PanelLayoutState> onStateChanged;

  final double minHeight;

  /// Of the current `MediaQuery` viewport height, re-clamped on every
  /// build (not just once at load) so a height saved on a large monitor
  /// never overflows a smaller window later.
  final double maxHeightFraction;
  final double defaultHeight;
  final bool defaultExpanded;

  @override
  State<ResizablePanel> createState() => _ResizablePanelState();
}

final class _ResizablePanelState extends State<ResizablePanel> {
  late bool _expanded;
  late double _height;

  /// While actively dragging, `TrayAccordion`'s `AnimatedSize` must not
  /// tween towards each new height — that would lag the drag behind the
  /// cursor instead of tracking it 1:1. Zeroed only for the drag's
  /// duration; expand/collapse still animates normally otherwise.
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initialState?.isExpanded ?? widget.defaultExpanded;
    _height = widget.initialState?.heightPx ?? widget.defaultHeight;
  }

  double _clampedHeight(BuildContext context) {
    final maxHeight =
        MediaQuery.sizeOf(context).height * widget.maxHeightFraction;
    return _height.clamp(widget.minHeight, maxHeight);
  }

  void _persist(double heightPx, bool isExpanded) {
    widget.onStateChanged(
      PanelLayoutState(heightPx: heightPx, isExpanded: isExpanded),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = _clampedHeight(context);

    return TrayAccordion(
      title: widget.title,
      subtitle: widget.subtitle,
      headerStyle: widget.headerStyle,
      isExpanded: _expanded,
      onExpandedChanged: (value) {
        setState(() => _expanded = value);
        _persist(height, value);
      },
      expandedHeight: height,
      animationDuration: _isDragging
          ? Duration.zero
          : const Duration(milliseconds: 200),
      bodyBuilder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Builder(builder: widget.bodyBuilder),
            ),
          ),
          _ResizeHandle(
            onDragStart: () => setState(() => _isDragging = true),
            onDragDelta: (dy) => setState(() {
              _height = (_height + dy).clamp(
                widget.minHeight,
                MediaQuery.sizeOf(context).height * widget.maxHeightFraction,
              );
            }),
            onDragEnd: () {
              setState(() => _isDragging = false);
              _persist(_clampedHeight(context), _expanded);
            },
          ),
        ],
      ),
    );
  }
}

final class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle({
    required this.onDragStart,
    required this.onDragDelta,
    required this.onDragEnd,
  });

  final VoidCallback onDragStart;
  final ValueChanged<double> onDragDelta;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeRow,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: (_) => onDragStart(),
        onVerticalDragUpdate: (details) => onDragDelta(details.delta.dy),
        onVerticalDragEnd: (_) => onDragEnd(),
        child: Align(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: context.colors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}
