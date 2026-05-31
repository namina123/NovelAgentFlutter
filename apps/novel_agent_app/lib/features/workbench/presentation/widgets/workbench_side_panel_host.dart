import 'package:flutter/material.dart';

import '../../application/services/workbench_project_panel_view_data_service.dart';
import '../contracts/resource_manager_action_handler.dart';
import '../models/workbench_agent_panel_view_data.dart';
import '../models/workbench_navigation_panel_id.dart';
import '../models/workbench_resource_view_data.dart';
import '../models/workbench_side_panel_contract.dart';
import '../models/workbench_workspace_shell_view_data.dart';
import 'resource_manager_panel.dart';
import 'workbench_agent_panel.dart';
import 'workbench_object_panel_body.dart';
import 'workbench_project_panel.dart';

class WorkbenchSidePanelHost extends StatelessWidget {
  const WorkbenchSidePanelHost({
    super.key,
    required this.selectedPanelId,
    required this.selectedContract,
    required this.resourceViewData,
    required this.agentPanelViewData,
    required this.shellViewData,
    required this.resourceHandler,
  });

  final WorkbenchNavigationPanelId selectedPanelId;
  final WorkbenchSidePanelContract selectedContract;
  final WorkbenchResourceViewData resourceViewData;
  final WorkbenchAgentPanelViewData agentPanelViewData;
  final WorkbenchWorkspaceShellViewData shellViewData;
  final ResourceManagerActionHandler resourceHandler;

  static const WorkbenchProjectPanelViewDataService
  _projectPanelViewDataService = WorkbenchProjectPanelViewDataService();

  @override
  Widget build(BuildContext context) {
    return WorkbenchObjectPanelBody(
      semanticsLabel: '${selectedContract.objectTitle}对象面板',
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: KeyedSubtree(
          key: ValueKey(selectedContract.panelId),
          child: switch (selectedPanelId) {
            WorkbenchNavigationPanelId.files => ResourceManagerPanel(
              viewData: resourceViewData,
              actionHandler: resourceHandler,
            ),
            WorkbenchNavigationPanelId.project => WorkbenchProjectPanel(
              viewData: _projectPanelViewDataService.build(shellViewData),
              resourceHandler: resourceHandler,
            ),
            WorkbenchNavigationPanelId.agent => WorkbenchAgentPanel(
              viewData: agentPanelViewData,
              resourceHandler: resourceHandler,
            ),
          },
        ),
      ),
    );
  }
}
