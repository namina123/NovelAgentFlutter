import 'package:flutter/material.dart';

import '../../app/navigation/app_shell_navigation_action_handler.dart';
import '../../app/navigation/app_shell_navigation_catalog.dart';
import '../../app/navigation/app_shell_navigation_item.dart';
import '../../app/navigation/app_shell_navigation_section.dart';
import '../../app/routing/app_destination.dart';
import '../theme/novel_theme_context.dart';

class AppShellActivityRail extends StatelessWidget {
  const AppShellActivityRail({
    super.key,
    required this.selectedDestination,
    required this.actionHandler,
  });

  final AppDestination selectedDestination;
  final AppShellNavigationActionHandler actionHandler;

  @override
  Widget build(BuildContext context) {
    final sidebarSurface = context.novelThemeSurfaces.sidebar;
    final sections = AppShellNavigationCatalog.sections();
    return Container(
      width: 88,
      decoration: BoxDecoration(
        color: sidebarSurface.backgroundColor,
        border: Border(right: BorderSide(color: sidebarSurface.borderColor)),
      ),
      child: ListView.separated(
        primary: false,
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
        itemCount: sections.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final section = sections[index];
          return _SectionBlock(
            section: section,
            selectedDestination: selectedDestination,
            actionHandler: actionHandler,
          );
        },
      ),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({
    required this.section,
    required this.selectedDestination,
    required this.actionHandler,
  });

  final AppShellNavigationSection section;
  final AppDestination selectedDestination;
  final AppShellNavigationActionHandler actionHandler;

  @override
  Widget build(BuildContext context) {
    final sidebarSurface = context.novelThemeSurfaces.sidebar;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            section.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: sidebarSurface.mutedForegroundColor,
            ),
          ),
        ),
        ...section.items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _NavigationButton(
              item: item,
              isSelected: item.destination == selectedDestination,
              onPressed: () {
                actionHandler.onAppShellDestinationRequested(item.destination);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _NavigationButton extends StatelessWidget {
  const _NavigationButton({
    required this.item,
    required this.isSelected,
    required this.onPressed,
  });

  final AppShellNavigationItem item;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final sidebarSurface = context.novelThemeSurfaces.sidebar;
    final selectedColor = sidebarSurface.highlightBackgroundColor;
    final selectedBorder = sidebarSurface.highlightBorderColor;
    final idleBorder = sidebarSurface.borderColor;
    final foreground = isSelected
        ? sidebarSurface.highlightForegroundColor
        : sidebarSurface.mutedForegroundColor;
    return Tooltip(
      message: item.tooltip,
      waitDuration: const Duration(milliseconds: 350),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.zero,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? selectedColor : Colors.transparent,
            border: Border.all(color: isSelected ? selectedBorder : idleBorder),
          ),
          child: Column(
            children: [
              Icon(item.icon, size: 18, color: foreground),
              const SizedBox(height: 4),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
