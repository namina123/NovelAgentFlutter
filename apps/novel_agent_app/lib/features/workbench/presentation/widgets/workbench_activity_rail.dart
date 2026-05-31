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
    return Wrap(
      spacing: visual.compactGap,
      runSpacing: visual.compactGap,
      children: panelContracts
          .map(
            (contract) => _WorkbenchActivityRailButton(
              item: _WorkbenchActivityRailItem(
                panelId: contract.panelId,
                label: contract.label,
                tooltip: contract.tooltip,
                icon: _iconOf(contract.panelId),
              ),
              isSelected: contract.panelId == selectedPanelId,
              onPressed: () => onPanelSelected(contract.panelId),
            ),
          )
          .toList(growable: false),
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
    final optionSurface = context.novelThemeSurfaces.optionTile;
    final visual = WorkbenchVisualStyle.of(context);
    final foreground = isSelected
        ? optionSurface.highlightForegroundColor
        : optionSurface.foregroundColor;
    return Tooltip(
      message: item.tooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(optionSurface.radius),
        child: Container(
          constraints: BoxConstraints(
            minHeight: context.novelChipChrome.minHeight,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: visual.optionBackground(optionSurface, selected: isSelected),
            borderRadius: BorderRadius.circular(optionSurface.radius),
            border: Border.all(
              color: isSelected
                  ? optionSurface.highlightBorderColor
                  : optionSurface.borderColor,
              width: optionSurface.borderWidth,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 14, color: foreground),
              SizedBox(width: visual.compactGap),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: visual.compactLabelFontSize,
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
    WorkbenchNavigationPanelId.files => Icons.folder_copy_outlined,
    WorkbenchNavigationPanelId.project => Icons.inventory_2_outlined,
    WorkbenchNavigationPanelId.agent => Icons.smart_toy_outlined,
  };
}
