import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../models/workbench_navigation_panel_id.dart';
import '../models/workbench_side_panel_contract.dart';
import 'workbench_visual_style.dart';

class WorkbenchActivityRail extends StatelessWidget {
  const WorkbenchActivityRail({
    super.key,
    required this.panelContracts,
    required this.selectedPanelId,
    required this.onPanelSelected,
  });

  final List<WorkbenchSidePanelContract> panelContracts;
  final WorkbenchNavigationPanelId selectedPanelId;
  final ValueChanged<WorkbenchNavigationPanelId> onPanelSelected;

  @override
  Widget build(BuildContext context) {
    final visual = WorkbenchVisualStyle.of(context);
    final surface = context.novelThemeSurfaces.sidebar;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: surface.backgroundColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(visual.sectionRadius + 1),
        border: Border(
          top: BorderSide(color: surface.borderColor.withValues(alpha: 0.18)),
        ),
      ),
      child: Row(
        children: panelContracts
            .map(
              (contract) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: contract == panelContracts.last ? 0 : 3,
                  ),
                  child: _WorkbenchActivityRailButton(
                    item: _WorkbenchActivityRailItem(
                      panelId: contract.panelId,
                      label: contract.label,
                      tooltip: contract.tooltip,
                      icon: _iconOf(contract.panelId),
                    ),
                    isSelected: contract.panelId == selectedPanelId,
                    onPressed: () => onPanelSelected(contract.panelId),
                  ),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _WorkbenchActivityRailButton extends StatelessWidget {
  const _WorkbenchActivityRailButton({
    required this.item,
    required this.isSelected,
    required this.onPressed,
  });

  final _WorkbenchActivityRailItem item;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final visual = WorkbenchVisualStyle.of(context);
    final optionSurface = context.novelThemeSurfaces.optionTile;
    final sidebarSurface = context.novelThemeSurfaces.sidebar;
    final foreground = isSelected
        ? optionSurface.highlightForegroundColor
        : sidebarSurface.mutedForegroundColor;
    final iconForeground = isSelected
        ? optionSurface.highlightForegroundColor
        : sidebarSurface.foregroundColor.withValues(alpha: 0.82);
    return Tooltip(
      message: item.tooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(visual.sectionRadius),
        child: Container(
          constraints: const BoxConstraints(minHeight: 34),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected
                ? optionSurface.highlightBackgroundColor.withValues(alpha: 0.54)
                : sidebarSurface.backgroundColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(visual.sectionRadius),
            border: Border(
              top: BorderSide(
                color: isSelected
                    ? optionSurface.highlightBorderColor.withValues(alpha: 0.58)
                    : sidebarSurface.borderColor.withValues(alpha: 0.14),
                width: optionSurface.borderWidth,
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, size: 13, color: iconForeground),
              SizedBox(height: visual.microGap),
              Text(
                item.label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: visual.compactLabelFontSize - 0.4,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
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

class _WorkbenchActivityRailItem {
  const _WorkbenchActivityRailItem({
    required this.panelId,
    required this.label,
    required this.tooltip,
    required this.icon,
  });

  final WorkbenchNavigationPanelId panelId;
  final String label;
  final String tooltip;
  final IconData icon;
}

IconData _iconOf(WorkbenchNavigationPanelId panelId) {
  return switch (panelId) {
    WorkbenchNavigationPanelId.files => Icons.folder_outlined,
    WorkbenchNavigationPanelId.project => Icons.inventory_2_outlined,
    WorkbenchNavigationPanelId.agent => Icons.smart_toy_outlined,
  };
}
