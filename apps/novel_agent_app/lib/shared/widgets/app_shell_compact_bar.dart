import 'package:flutter/material.dart';

import '../../app/navigation/app_shell_navigation_item.dart';
import '../../app/navigation/app_shell_navigation_section.dart';
import '../../app/routing/app_destination.dart';
import '../theme/novel_theme_context.dart';
import 'toolbar_icon_button.dart';

class AppShellCompactBar extends StatelessWidget {
  const AppShellCompactBar({
    super.key,
    required this.navigationSections,
    required this.selectedDestination,
    required this.onMenuRequested,
    required this.onCommandPaletteRequested,
  });

  final List<AppShellNavigationSection> navigationSections;
  final AppDestination selectedDestination;
  final VoidCallback onMenuRequested;

  /// 命令面板入口。移动端没有 Ctrl+K，因此顶部条放一个常驻放大镜按钮，
  /// 与桌面端全局快捷键对等可达。
  final VoidCallback onCommandPaletteRequested;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 紧凑顶部条只保留当前页识别和菜单入口，避免横向导航在窄屏中挤压主视图。
    final sidebarSurface = context.novelThemeSurfaces.sidebar;
    final item = _findItem(selectedDestination);
    final section = _findSection(selectedDestination);
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: sidebarSurface.backgroundColor,
        border: Border(bottom: BorderSide(color: sidebarSurface.borderColor)),
      ),
      child: Row(
        children: [
          ToolbarIconButton(
            icon: Icons.menu_rounded,
            tooltip: '打开功能栏',
            onPressed: onMenuRequested,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section?.label ?? '工作区',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: sidebarSurface.mutedForegroundColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item?.label ?? '工作台',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: sidebarSurface.foregroundColor,
                  ),
                ),
              ],
            ),
          ),
          ToolbarIconButton(
            icon: Icons.terminal,
            tooltip: '命令面板',
            onPressed: onCommandPaletteRequested,
          ),
          const SizedBox(width: 4),
          if (item != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: sidebarSurface.highlightBackgroundColor,
                border: Border.all(color: sidebarSurface.highlightBorderColor),
                borderRadius: BorderRadius.circular(sidebarSurface.radius),
              ),
              child: item.badgeCount > 0
                  ? Badge.count(
                      count: item.badgeCount,
                      child: Icon(
                        item.icon,
                        size: 16,
                        color: sidebarSurface.highlightForegroundColor,
                      ),
                    )
                  : Icon(
                      item.icon,
                      size: 16,
                      color: sidebarSurface.highlightForegroundColor,
                    ),
            ),
        ],
      ),
    );
  }

  AppShellNavigationItem? _findItem(AppDestination destination) {
    for (final section in navigationSections) {
      for (final item in section.items) {
        if (item.destination == destination) {
          return item;
        }
      }
    }
    return null;
  }

  AppShellNavigationSection? _findSection(AppDestination destination) {
    for (final section in navigationSections) {
      for (final item in section.items) {
        if (item.destination == destination) {
          return section;
        }
      }
    }
    return null;
  }
}
