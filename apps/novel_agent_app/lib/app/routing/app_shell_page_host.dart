import 'package:flutter/material.dart';

import 'app_destination.dart';
import 'app_shell_page_descriptor.dart';

class AppShellPageHost extends StatefulWidget {
  const AppShellPageHost({
    super.key,
    required this.selectedDestination,
    required this.pageDescriptors,
  });

  final AppDestination selectedDestination;
  final List<AppShellPageDescriptor> pageDescriptors;

  @override
  State<AppShellPageHost> createState() => _AppShellPageHostState();
}

class _AppShellPageHostState extends State<AppShellPageHost> {
  final Map<AppDestination, Widget> _cachedPages =
      <AppDestination, Widget>{};

  @override
  Widget build(BuildContext context) {
    // 中文注释: 页面宿主通过 offstage + ticker mode 保留已访问页面状态，同时只让当前目的地可见。
    _ensureSelectedPageCached(context);
    final children = <Widget>[];
    for (var index = 0; index < widget.pageDescriptors.length; index += 1) {
      final descriptor = widget.pageDescriptors[index];
      final page = _cachedPages[descriptor.destination];
      if (page == null) {
        continue;
      }
      final isVisible = descriptor.destination == widget.selectedDestination;
      children.add(
        KeyedSubtree(
          key: ValueKey<AppDestination>(descriptor.destination),
          child: Offstage(
            offstage: !isVisible,
            child: TickerMode(
              enabled: isVisible,
              child: page,
            ),
          ),
        ),
      );
    }
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }
    return Stack(
      fit: StackFit.expand,
      children: children,
    );
  }

  void _ensureSelectedPageCached(BuildContext context) {
    // 中文注释: 这里只补建当前目的地页面，避免所有 destination 一次性挂载引发首屏初始化风暴。
    final descriptor = _descriptorFor(widget.selectedDestination);
    if (descriptor == null || _cachedPages.containsKey(descriptor.destination)) {
      return;
    }
    _cachedPages[descriptor.destination] = descriptor.builder(context);
  }

  AppShellPageDescriptor? _descriptorFor(AppDestination destination) {
    for (final descriptor in widget.pageDescriptors) {
      if (descriptor.destination == destination) {
        return descriptor;
      }
    }
    return null;
  }
}
