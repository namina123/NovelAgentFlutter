import 'package:flutter/material.dart';

import '../../app/navigation/app_shell_navigation_catalog.dart';
import '../../app/routing/app_destination.dart';
import '../theme/novel_theme_context.dart';
import 'toolbar_icon_button.dart';

class AppShellCompactBar extends StatelessWidget {
  const AppShellCompactBar({
    super.key,
    required this.selectedDestination,
    required this.onMenuRequested,
  });

  final AppDestination selectedDestination;
  final VoidCallback onMenuRequested;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 紧凑顶部条只保留当前页识别和菜单入口，避免横向导航在窄屏中挤压主视图。
    final sidebarSurface = context.novelThemeSurfaces.sidebar;
    final item = AppShellNavigationCatalog.findItem(selectedDestination);
    final section = AppShellNavigationCatalog.findSection(selectedDestination);
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
          if (item != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: sidebarSurface.highlightBackgroundColor,
                border: Border.all(color: sidebarSurface.highlightBorderColor),
                borderRadius: BorderRadius.circular(sidebarSurface.radius),
              ),
              child: Icon(
                item.icon,
                size: 16,
                color: sidebarSurface.highlightForegroundColor,
              ),
            ),
        ],
      ),
    );
  }
}
