import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/layout/app_layout_metrics.dart';
import '../../app/layout/app_layout_scope.dart';
import '../../app/routing/app_destination.dart';
import '../../app/routing/app_router.dart';
import '../../app/state/app_shell_controller.dart';
import '../../features/command_palette/application/command_palette_controller.dart';
import '../../features/command_palette/application/command_registry.dart';
import '../../features/command_palette/presentation/command_palette_bindings.dart';
import '../../features/command_palette/presentation/command_palette_dialog.dart';
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

  CommandRegistry? _commandRegistry;
  bool _commandPaletteOpen = false;

  @override
  void initState() {
    super.initState();
    // 中文注释: 初始化延后到首帧后执行，避免控制器在根壳层仍处于构建期时就触发通知。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.initialize();
    });
  }

  /// 懒构建命令注册表。命令闭包捕获的控制器在壳层生命周期内不变，故只需构建一次。
  CommandRegistry _resolveCommandRegistry() {
    return _commandRegistry ??= buildAppCommandRegistry(widget.controller);
  }

  /// 打开命令面板。重入守卫避免 Ctrl+K 连按叠出多个面板。
  void _openCommandPalette(BuildContext context) {
    if (_commandPaletteOpen) return;
    _commandPaletteOpen = true;
    final paletteController =
        CommandPaletteController(_resolveCommandRegistry());
    showCommandPalette(context, controller: paletteController).whenComplete(() {
      _commandPaletteOpen = false;
      paletteController.dispose();
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
        final navigationSections = widget.controller.navigationSections();
        final page = AppLayoutScope(
          metrics: metrics,
          child: _router.buildPageHost(widget.controller),
        );
        widget.controller.navigationTraceService?.markDestinationVisible(
          destination,
        );

        // 中文注释: Ctrl+K / Ctrl+Shift+P 唤起命令面板。这是首个全局快捷键层，
        // 放在根壳层确保任何页面（含设置页文本框）聚焦时都能触发；与页面内
        // Ctrl+F/Ctrl+S 不冲突（不同按键绑定，且页面层 Shortcuts 更具体优先）。
        return CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            const SingleActivator(LogicalKeyboardKey.keyK, control: true):
                () => _openCommandPalette(context),
            const SingleActivator(
              LogicalKeyboardKey.keyP,
              control: true,
              shift: true,
            ): () => _openCommandPalette(context),
          },
          child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: SafeArea(
            child: metrics.isCompact
                ? AppShellCompactScaffold(
                    navigationSections: navigationSections,
                    selectedDestination: destination,
                    actionHandler: widget.controller,
                    onSystemBackRequested: () =>
                        _handleSystemBackRequested(context),
                    onCommandPaletteRequested: () =>
                        _openCommandPalette(context),
                    page: page,
                  )
                : PopScope<Object?>(
                    canPop: false,
                    onPopInvokedWithResult: (didPop, _) async {
                      if (didPop) {
                        return;
                      }
                      await _handleSystemBackRequested(context);
                    },
                    child: Row(
                      children: [
                        AppShellActivityRail(
                          sections: navigationSections,
                          selectedDestination: destination,
                          actionHandler: widget.controller,
                          onCommandPaletteRequested: () =>
                              _openCommandPalette(context),
                        ),
                        Expanded(child: page),
                      ],
                    ),
                  ),
          ),
          ),
        );
      },
    );
  }

  Future<void> _handleSystemBackRequested(BuildContext context) async {
    final shouldAskExit = await widget.controller.handleSystemBackRequested();
    if (!shouldAskExit || !context.mounted) {
      return;
    }
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('退出应用？'),
          content: const Text('当前操作已停在这里。确定要退出吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('退出'),
            ),
          ],
        );
      },
    );
    if (result == true) {
      await SystemNavigator.pop();
    }
  }
}
