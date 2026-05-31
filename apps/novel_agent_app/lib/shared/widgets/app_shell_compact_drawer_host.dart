import 'package:flutter/material.dart';

import '../../app/navigation/app_shell_navigation_action_handler.dart';
import '../../app/routing/app_destination.dart';
import 'app_shell_compact_dock_layout.dart';
import 'app_shell_compact_drawer.dart';
import 'app_shell_compact_drawer_controller.dart';

class AppShellCompactDrawerHost extends StatelessWidget {
  const AppShellCompactDrawerHost({
    super.key,
    required this.selectedDestination,
    required this.actionHandler,
    required this.controller,
    required this.dockLayout,
  });

  final AppDestination selectedDestination;
  final AppShellNavigationActionHandler actionHandler;
  final AppShellCompactDrawerController controller;
  final AppShellCompactDockLayout dockLayout;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final isOpen = controller.isOpen && dockLayout.allowExpandedPanel;
        return Stack(
          children: [
            if (isOpen)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: controller.close,
                  child: Container(color: Colors.black.withValues(alpha: 0.12)),
                ),
              ),
            if (isOpen)
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppShellCompactDockLayout.screenEdgePadding,
                    AppShellCompactDockLayout.screenEdgePadding,
                    AppShellCompactDockLayout.screenEdgePadding,
                    dockLayout.panelBottomInset,
                  ),
                  child: AppShellCompactDrawerPanel(
                    width: dockLayout.panelWidth,
                    selectedDestination: selectedDestination,
                    actionHandler: actionHandler,
                    onDismissRequested: controller.close,
                  ),
                ),
              ),
            if (dockLayout.keyboardVisible)
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppShellCompactDockLayout.screenEdgePadding,
                    AppShellCompactDockLayout.screenEdgePadding,
                    AppShellCompactDockLayout.screenEdgePadding,
                    dockLayout.launcherBottomInset,
                  ),
                  child: AppShellCompactDrawerLauncher(
                    selectedDestination: selectedDestination,
                    isOpen: false,
                    onPressed: controller.toggle,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class AppShellCompactLauncherDock extends StatelessWidget {
  const AppShellCompactLauncherDock({
    super.key,
    required this.selectedDestination,
    required this.controller,
    required this.dockLayout,
  });

  final AppDestination selectedDestination;
  final AppShellCompactDrawerController controller;
  final AppShellCompactDockLayout dockLayout;

  @override
  Widget build(BuildContext context) {
    if (dockLayout.keyboardVisible) {
      return const SizedBox.shrink();
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            AppShellCompactDockLayout.screenEdgePadding,
            0,
            AppShellCompactDockLayout.screenEdgePadding,
            AppShellCompactDockLayout.baseBottomGap,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AppShellCompactDrawerLauncher(
              selectedDestination: selectedDestination,
              isOpen: controller.isOpen && dockLayout.allowExpandedPanel,
              onPressed: controller.toggle,
            ),
          ),
        );
      },
    );
  }
}
