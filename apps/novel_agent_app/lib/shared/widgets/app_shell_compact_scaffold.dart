import 'package:flutter/material.dart';

import '../../app/navigation/app_shell_navigation_action_handler.dart';
import '../../app/navigation/app_shell_navigation_section.dart';
import '../../app/routing/app_destination.dart';
import 'app_shell_compact_bar.dart';
import 'app_shell_compact_dock_layout.dart';
import 'app_shell_compact_drawer_controller.dart';
import 'app_shell_compact_drawer_host.dart';
import 'app_shell_compact_page_frame.dart';

class AppShellCompactScaffold extends StatefulWidget {
  const AppShellCompactScaffold({
    super.key,
    required this.page,
    required this.navigationSections,
    required this.selectedDestination,
    required this.actionHandler,
    required this.onSystemBackRequested,
    required this.onCommandPaletteRequested,
  });

  final Widget page;
  final List<AppShellNavigationSection> navigationSections;
  final AppDestination selectedDestination;
  final AppShellNavigationActionHandler actionHandler;
  final Future<void> Function() onSystemBackRequested;

  /// 命令面板入口回调，由顶部条放大镜按钮触发。
  final VoidCallback onCommandPaletteRequested;

  @override
  State<AppShellCompactScaffold> createState() =>
      _AppShellCompactScaffoldState();
}

class _AppShellCompactScaffoldState extends State<AppShellCompactScaffold> {
  final AppShellCompactDrawerController _drawerController =
      AppShellCompactDrawerController();

  @override
  void didUpdateWidget(covariant AppShellCompactScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDestination != widget.selectedDestination) {
      // 中文注释: 页面切换后主动收口，避免抽拉栏跨页面残留挡住新的主视图。
      _drawerController.close();
    }
  }

  @override
  void dispose() {
    _drawerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dockLayout = AppShellCompactDockLayout.fromMediaQuery(
      MediaQuery.of(context),
    );
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          return;
        }
        if (_drawerController.isOpen) {
          _drawerController.close();
          return;
        }
        await widget.onSystemBackRequested();
      },
      child: Column(
        children: [
          AppShellCompactBar(
            navigationSections: widget.navigationSections,
            selectedDestination: widget.selectedDestination,
            onMenuRequested: _drawerController.toggle,
            onCommandPaletteRequested: widget.onCommandPaletteRequested,
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: AppShellCompactPageFrame(
                    bottomInset: dockLayout.pageBottomInset,
                    child: widget.page,
                  ),
                ),
                Positioned.fill(
                  child: AppShellCompactDrawerHost(
                    navigationSections: widget.navigationSections,
                    selectedDestination: widget.selectedDestination,
                    actionHandler: widget.actionHandler,
                    controller: _drawerController,
                    dockLayout: dockLayout,
                  ),
                ),
              ],
            ),
          ),
          AppShellCompactLauncherDock(
            selectedDestination: widget.selectedDestination,
            controller: _drawerController,
            dockLayout: dockLayout,
          ),
        ],
      ),
    );
  }
}
