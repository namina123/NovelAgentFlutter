import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../../application/services/workbench_agent_panel_view_data_service.dart';
import '../../application/services/workbench_side_panel_contract_service.dart';
import '../../application/services/workbench_workspace_shell_view_data_service.dart';
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
  static const WorkbenchAgentPanelViewDataService _agentPanelViewDataService =
      WorkbenchAgentPanelViewDataService();
  static const WorkbenchWorkspaceShellViewDataService _shellViewDataService =
      WorkbenchWorkspaceShellViewDataService();
  static final List<WorkbenchSidePanelContract> _panelContracts =
      _panelContractService.contracts();

  WorkbenchNavigationPanelId _selectedPanelId =
      WorkbenchNavigationPanelId.files;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.resourceListenable,
        widget.canvasListenable,
        widget.conversationListenable,
      ]),
      builder: (context, _) {
        final surface = context.novelThemeSurfaces.sidebar;
        final visual = WorkbenchVisualStyle.of(context);
        final resource = widget.resourceListenable.value;
        final canvas = widget.canvasListenable.value;
        final conversation = widget.conversationListenable.value;
        final shellViewData = _shellViewDataService.build(
          resource: resource,
          canvas: canvas,
          conversation: conversation,
        );
        final agentPanelViewData = _agentPanelViewDataService.build(
          shellViewData: shellViewData,
          conversationViewData: conversation,
        );
        final selectedContract = _panelContractService.contractOf(
          _selectedPanelId,
        );
        return DecoratedBox(
          decoration: BoxDecoration(
            color: surface.backgroundColor,
            border: Border(
              right: BorderSide(
                color: visual.subtleBorder(surface.borderColor),
              ),
            ),
          ),
          child: Padding(
            padding: visual.sidebarPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _WorkbenchObjectHeader(contract: selectedContract),
                SizedBox(height: visual.compactGap),
                WorkbenchActivityRail(
                  panelContracts: _panelContracts,
                  selectedPanelId: _selectedPanelId,
                  onPanelSelected: _handlePanelSelected,
                ),
                SizedBox(height: visual.compactGap),
                Expanded(
                  child: WorkbenchSidePanelHost(
                    selectedPanelId: _selectedPanelId,
                    selectedContract: selectedContract,
                    resourceViewData: resource,
                    agentPanelViewData: agentPanelViewData,
                    shellViewData: shellViewData,
                    resourceHandler: widget.resourceHandler,
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

class _WorkbenchObjectHeader extends StatelessWidget {
  const _WorkbenchObjectHeader({required this.contract});

  final WorkbenchSidePanelContract contract;

  @override
  Widget build(BuildContext context) {
    final surface = context.novelThemeSurfaces.sidebar;
    final visual = WorkbenchVisualStyle.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '工作台对象',
          style: TextStyle(
            fontSize: visual.captionFontSize,
            fontWeight: FontWeight.w700,
            color: surface.mutedForegroundColor,
          ),
        ),
        SizedBox(height: visual.microGap),
        Text(
          contract.objectTitle,
          style: TextStyle(
            fontSize: visual.sectionTitleFontSize,
            height: visual.titleLineHeight,
            fontWeight: FontWeight.w800,
            color: surface.foregroundColor,
          ),
        ),
        SizedBox(height: visual.microGap),
        Text(
          contract.summary,
          style: TextStyle(
            fontSize: visual.metaFontSize,
            height: visual.bodyLineHeight,
            fontWeight: FontWeight.w500,
            color: surface.mutedForegroundColor,
          ),
        ),
      ],
    );
  }
}
