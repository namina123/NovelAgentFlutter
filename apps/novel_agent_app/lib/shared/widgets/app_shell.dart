import 'package:flutter/material.dart';

import '../../app/layout/app_layout_metrics.dart';
import '../../app/layout/app_layout_scope.dart';
import '../../app/routing/app_router.dart';
import '../../app/state/app_shell_controller.dart';

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
    // 中文注释: 根壳层只监听当前页面切换，不把具体页面布局揉进一个大 build 方法里。
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final metrics = AppLayoutMetrics.fromMediaQuery(MediaQuery.of(context));

        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: SafeArea(
            child: AppLayoutScope(
              metrics: metrics,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: KeyedSubtree(
                  key: ValueKey(widget.controller.viewModel.destination),
                  child: _router.buildPage(widget.controller),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
