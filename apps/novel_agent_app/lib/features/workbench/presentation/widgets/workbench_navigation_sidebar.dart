import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../../application/services/workbench_side_panel_contract_service.dart';
import '../contracts/resource_manager_action_handler.dart';
import '../models/workbench_canvas_view_data.dart';
import '../models/workbench_conversation_view_data.dart';
import '../models/workbench_navigation_panel_id.dart';
import '../models/workbench_resource_view_data.dart';
import '../models/workbench_side_panel_contract.dart';
import 'workbench_activity_rail.dart';
import 'workbench_side_panel_host.dart';
import 'workbench_visual_style.dart';

class WorkbenchNavigationSidebar extends StatefulWidget {
  const WorkbenchNavigationSidebar({
    super.key,
    required this.resourceListenable,
    required this.canvasListenable,
    required this.conversationListenable,
    required this.resourceHandler,
  });

  final ValueListenable<WorkbenchResourceViewData> resourceListenable;
  final ValueListenable<WorkbenchCanvasViewData> canvasListenable;
  final ValueListenable<WorkbenchConversationViewData> conversationListenable;
  final ResourceManagerActionHandler resourceHandler;

  @override
  State<WorkbenchNavigationSidebar> createState() =>
      _WorkbenchNavigationSidebarState();
}

class _WorkbenchNavigationSidebarState
    extends State<WorkbenchNavigationSidebar> {
  static const WorkbenchSidePanelContractService _panelContractService =
      WorkbenchSidePanelContractService();
  static final List<WorkbenchSidePanelContract> _panelContracts =
      _panelContractService.contracts();

  WorkbenchNavigationPanelId _selectedPanelId =
      WorkbenchNavigationPanelId.files;

  @override
  Widget build(BuildContext context) {
    final surface = context.novelThemeSurfaces.sidebar;
    final visual = WorkbenchVisualStyle.of(context);
    final selectedContract = _panelContractService.contractOf(_selectedPanelId);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface.backgroundColor,
        border: Border(
          right: BorderSide(color: visual.subtleBorder(surface.borderColor)),
        ),
      ),
      child: Padding(
        padding: visual.sidebarPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WorkbenchSidebarHeader(
              contract: selectedContract,
              panelContracts: _panelContracts,
              selectedPanelId: _selectedPanelId,
              onPanelSelected: _handlePanelSelected,
            ),
            SizedBox(height: visual.sectionGap),
            Expanded(
              child: WorkbenchSidePanelHost(
                selectedPanelId: _selectedPanelId,
                selectedContract: selectedContract,
                resourceListenable: widget.resourceListenable,
                conversationListenable: widget.conversationListenable,
                resourceHandler: widget.resourceHandler,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePanelSelected(WorkbenchNavigationPanelId panelId) {
    if (_selectedPanelId == panelId) {
      return;
    }
    setState(() {
      _selectedPanelId = panelId;
    });
  }
}

class _WorkbenchSidebarHeader extends StatelessWidget {
  const _WorkbenchSidebarHeader({
    required this.contract,
    required this.panelContracts,
    required this.selectedPanelId,
    required this.onPanelSelected,
  });

  final WorkbenchSidePanelContract contract;
  final List<WorkbenchSidePanelContract> panelContracts;
  final WorkbenchNavigationPanelId selectedPanelId;
  final ValueChanged<WorkbenchNavigationPanelId> onPanelSelected;

  @override
  Widget build(BuildContext context) {
    final surface = context.novelThemeSurfaces.sidebar;
    final visual = WorkbenchVisualStyle.of(context);
    final activeLabel = contract.label;
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 3, 4, 4),
      decoration: BoxDecoration(
        color: surface.backgroundColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(visual.surfaceRadius - 1),
        border: Border.all(
          color: surface.borderColor.withValues(alpha: 0.12),
          width: surface.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: surface.highlightBackgroundColor.withValues(
                    alpha: 0.14,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  _panelHeaderIcon(contract.panelId),
                  size: 11,
                  color: surface.highlightForegroundColor,
                ),
              ),
              SizedBox(width: visual.compactGap + 1),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: visual.compactLabelFontSize + 0.1,
                        fontWeight: FontWeight.w800,
                        color: surface.foregroundColor,
                      ),
                    ),
                    Text(
                      contract.objectTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: visual.metaFontSize,
                        fontWeight: FontWeight.w600,
                        color: surface.mutedForegroundColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: surface.backgroundColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${panelContracts.length} 视图',
                  style: TextStyle(
                    fontSize: visual.metaFontSize - 0.2,
                    fontWeight: FontWeight.w700,
                    color: surface.mutedForegroundColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: visual.compactGap + 1),
          WorkbenchActivityRail(
            panelContracts: panelContracts,
            selectedPanelId: selectedPanelId,
            onPanelSelected: onPanelSelected,
          ),
        ],
      ),
    );
  }
}

IconData _panelHeaderIcon(WorkbenchNavigationPanelId panelId) {
  return switch (panelId) {
    WorkbenchNavigationPanelId.files => Icons.folder_copy_outlined,
    WorkbenchNavigationPanelId.project => Icons.inventory_2_outlined,
    WorkbenchNavigationPanelId.agent => Icons.smart_toy_outlined,
  };
}
