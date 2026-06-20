import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class HorizontalOverflowScrollbar extends StatefulWidget {
  const HorizontalOverflowScrollbar({super.key, this.builder, this.child})
    : assert(builder != null || child != null);

  final Widget Function(BuildContext context, ScrollController controller)?
  builder;
  final Widget? child;

  @override
  State<HorizontalOverflowScrollbar> createState() =>
      _HorizontalOverflowScrollbarState();
}

class _HorizontalOverflowScrollbarState
    extends State<HorizontalOverflowScrollbar> {
  late final ScrollController _controller;
  ScrollPosition? _trackedPosition;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.builder?.call(context, _controller) ?? widget.child!;
    return Listener(
      onPointerSignal: _handlePointerSignal,
      child: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: NotificationListener<ScrollMetricsNotification>(
          onNotification: _handleScrollMetricsNotification,
          child: Scrollbar(
            controller: _controller.hasClients ? _controller : null,
            notificationPredicate: (notification) =>
                notification.metrics.axis == Axis.horizontal,
            child: child,
          ),
        ),
      ),
    );
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) {
      return;
    }
    final position = _resolvePosition();
    if (position == null) {
      return;
    }
    if (position.axis != Axis.horizontal) {
      return;
    }
    final delta = event.scrollDelta.dx.abs() > event.scrollDelta.dy.abs()
        ? event.scrollDelta.dx
        : event.scrollDelta.dy;
    if (delta == 0) {
      return;
    }
    final nextOffset = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (nextOffset == position.pixels) {
      return;
    }
    position.jumpTo(nextOffset.toDouble());
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    final metrics = notification.metrics;
    if (metrics.axis != Axis.horizontal) {
      return false;
    }
    final context = notification.context;
    if (context == null) {
      return false;
    }
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable != null) {
      _trackedPosition = scrollable.position;
    }
    return false;
  }

  bool _handleScrollMetricsNotification(
    ScrollMetricsNotification notification,
  ) {
    if (notification.metrics.axis != Axis.horizontal) {
      return false;
    }
    final context = notification.context;
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable != null) {
      _trackedPosition = scrollable.position;
    }
    return false;
  }

  ScrollPosition? _resolvePosition() {
    if (_controller.hasClients) {
      return _controller.position;
    }
    return _trackedPosition;
  }
}
