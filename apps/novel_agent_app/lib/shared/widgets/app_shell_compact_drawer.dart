import 'package:flutter/material.dart';

import '../../app/navigation/app_shell_navigation_action_handler.dart';
import '../../app/navigation/app_shell_navigation_catalog.dart';
import '../../app/navigation/app_shell_navigation_item.dart';
import '../../app/navigation/app_shell_navigation_section.dart';
import '../../app/routing/app_destination.dart';
import '../theme/novel_theme_context.dart';
import 'app_shell_compact_dock_layout.dart';
import 'app_shell_compact_drawer_controller.dart';

class AppShellCompactDrawer extends StatelessWidget {
  const AppShellCompactDrawer({
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
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppShellCompactDockLayout.screenEdgePadding,
                  AppShellCompactDockLayout.screenEdgePadding,
                  AppShellCompactDockLayout.screenEdgePadding,
                  dockLayout.launcherBottomInset,
                ),
            child: _CompactDrawerDock(
                  isOpen: isOpen,
                  selectedDestination: selectedDestination,
                  actionHandler: actionHandler,
                  dockLayout: dockLayout,
                  onToggleRequested: controller.toggle,
                  onDismissRequested: controller.close,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CompactDrawerDock extends StatelessWidget {
  const _CompactDrawerDock({
    required this.isOpen,
    required this.selectedDestination,
    required this.actionHandler,
    required this.dockLayout,
    required this.onToggleRequested,
    required this.onDismissRequested,
  });

  final bool isOpen;
  final AppDestination selectedDestination;
  final AppShellNavigationActionHandler actionHandler;
  final AppShellCompactDockLayout dockLayout;
  final VoidCallback onToggleRequested;
  final VoidCallback onDismissRequested;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isOpen)
          Padding(
            key: const ValueKey('compact-drawer-panel'),
            padding: const EdgeInsets.only(bottom: 10),
              child: AppShellCompactDrawerPanel(
              width: dockLayout.panelWidth,
              selectedDestination: selectedDestination,
              actionHandler: actionHandler,
              onDismissRequested: onDismissRequested,
            ),
          ),
        AppShellCompactDrawerLauncher(
          selectedDestination: selectedDestination,
          isOpen: isOpen,
          onPressed: onToggleRequested,
        ),
      ],
    );
  }
}

class AppShellCompactDrawerPanel extends StatelessWidget {
  const AppShellCompactDrawerPanel({
    super.key,
    required this.width,
    required this.selectedDestination,
    required this.actionHandler,
    required this.onDismissRequested,
  });

  final double width;
  final AppDestination selectedDestination;
  final AppShellNavigationActionHandler actionHandler;
  final VoidCallback onDismissRequested;

  @override
  Widget build(BuildContext context) {
    final sidebarSurface = context.novelThemeSurfaces.sidebar;
    final sections = AppShellNavigationCatalog.sections();
    return Material(
      color: Colors.transparent,
      child: Container(
        width: width,
        constraints: const BoxConstraints(maxHeight: 420),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        decoration: BoxDecoration(
          color: sidebarSurface.backgroundColor,
          border: Border.all(color: sidebarSurface.borderColor),
          borderRadius: BorderRadius.circular(sidebarSurface.radius),
          boxShadow: [
            BoxShadow(
              blurRadius: 22,
              offset: const Offset(0, 10),
              color: Colors.black.withValues(alpha: 0.08),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CompactDrawerHeader(onDismissRequested: onDismissRequested),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.separated(
                primary: false,
                shrinkWrap: true,
                itemCount: sections.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return _CompactDrawerSection(
                    section: sections[index],
                    selectedDestination: selectedDestination,
                    onSelected: (destination) async {
                      await actionHandler.onAppShellDestinationRequested(
                        destination,
                      );
                      onDismissRequested();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactDrawerHeader extends StatelessWidget {
  const _CompactDrawerHeader({required this.onDismissRequested});

  final VoidCallback onDismissRequested;

  @override
  Widget build(BuildContext context) {
    final sidebarSurface = context.novelThemeSurfaces.sidebar;
    return Row(
      children: [
        Expanded(
          child: Text(
            '功能入口',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: sidebarSurface.foregroundColor,
            ),
          ),
        ),
        IconButton(
          tooltip: '收起导航',
          visualDensity: VisualDensity.compact,
          onPressed: onDismissRequested,
          icon: Icon(
            Icons.close_rounded,
            size: 18,
            color: sidebarSurface.mutedForegroundColor,
          ),
        ),
      ],
    );
  }
}

class _CompactDrawerSection extends StatelessWidget {
  const _CompactDrawerSection({
    required this.section,
    required this.selectedDestination,
    required this.onSelected,
  });

  final AppShellNavigationSection section;
  final AppDestination selectedDestination;
  final Future<void> Function(AppDestination destination) onSelected;

  @override
  Widget build(BuildContext context) {
    final sidebarSurface = context.novelThemeSurfaces.sidebar;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            section.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: sidebarSurface.mutedForegroundColor,
            ),
          ),
        ),
        ...section.items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _CompactDrawerEntry(
              item: item,
              isSelected: item.destination == selectedDestination,
              onPressed: () => onSelected(item.destination),
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactDrawerEntry extends StatelessWidget {
  const _CompactDrawerEntry({
    required this.item,
    required this.isSelected,
    required this.onPressed,
  });

  final AppShellNavigationItem item;
  final bool isSelected;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final sidebarSurface = context.novelThemeSurfaces.sidebar;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(sidebarSurface.radius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? sidebarSurface.highlightBackgroundColor
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? sidebarSurface.highlightBorderColor
                : sidebarSurface.borderColor,
          ),
          borderRadius: BorderRadius.circular(sidebarSurface.radius),
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 18,
              color: isSelected
                  ? sidebarSurface.highlightForegroundColor
                  : sidebarSurface.foregroundColor,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected
                      ? sidebarSurface.highlightForegroundColor
                      : sidebarSurface.foregroundColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppShellCompactDrawerLauncher extends StatelessWidget {
  const AppShellCompactDrawerLauncher({
    super.key,
    required this.selectedDestination,
    required this.isOpen,
    required this.onPressed,
  });

  final AppDestination selectedDestination;
  final bool isOpen;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final sidebarSurface = context.novelThemeSurfaces.sidebar;
    final item = AppShellNavigationCatalog.findItem(selectedDestination);
    final label = item?.label ?? '菜单';
    final icon = isOpen ? Icons.close_rounded : Icons.menu_rounded;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(sidebarSurface.radius),
        child: Container(
          key: const ValueKey('app-shell-compact-launcher'),
          constraints: const BoxConstraints(minWidth: 120, maxWidth: 220),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: sidebarSurface.backgroundColor,
            border: Border.all(
              color: isOpen
                  ? sidebarSurface.highlightBorderColor
                  : sidebarSurface.borderColor,
            ),
            borderRadius: BorderRadius.circular(sidebarSurface.radius),
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                offset: const Offset(0, 8),
                color: Colors.black.withValues(alpha: 0.06),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isOpen
                    ? sidebarSurface.highlightForegroundColor
                    : sidebarSurface.foregroundColor,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isOpen
                        ? sidebarSurface.highlightForegroundColor
                        : sidebarSurface.foregroundColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
