import 'package:flutter/material.dart';

import '../../app/layout/app_layout_metrics.dart';
import '../../app/layout/app_layout_scope.dart';
import '../../app/routing/app_destination.dart';
import '../../app/routing/app_router.dart';
import '../../app/state/app_shell_controller.dart';
import 'app_shell_activity_rail.dart';
import 'app_shell_compact_scaffold.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.controller});

  final AppShellController controller;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final AppRouter _router = const AppRouter();

  @override
  void initState() {
    super.initState();
    // 中文注释: 初始化延后到首帧后执行，避免控制器在根壳层仍处于构建期时就触发通知。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.initialize();
    });
  }

  @override
  void dispose() {
    // 中文注释: 根壳层负责释放自己的 UI 控制器，避免监听器在页面销毁后悬挂。
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 中文注释: 根壳层只监听目的地切换，把页面内部数据更新留给各自 page-scope listenable 处理。
    return ValueListenableBuilder<AppDestination>(
      valueListenable: widget.controller.destinationListenable,
      builder: (context, destination, _) {
        final metrics = AppLayoutMetrics.fromMediaQuery(MediaQuery.of(context));
        final page = AppLayoutScope(
          metrics: metrics,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: KeyedSubtree(
              key: ValueKey(destination),
              child: _router.buildPage(widget.controller),
            ),
          ),
        );

        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: SafeArea(
            child: metrics.isCompact
                ? AppShellCompactScaffold(
                    selectedDestination: destination,
                    actionHandler: widget.controller,
                    page: page,
                  )
                : Row(
                    children: [
                      AppShellActivityRail(
                        selectedDestination: destination,
                        actionHandler: widget.controller,
                      ),
                      Expanded(child: page),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
