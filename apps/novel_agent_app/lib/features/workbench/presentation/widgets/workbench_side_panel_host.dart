import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../application/services/workbench_agent_panel_view_data_service.dart';
import '../../application/services/workbench_project_panel_view_data_service.dart';
import '../contracts/resource_manager_action_handler.dart';
import '../models/workbench_conversation_view_data.dart';
import '../models/workbench_navigation_panel_id.dart';
import '../models/workbench_resource_view_data.dart';
import '../models/workbench_side_panel_contract.dart';
import 'resource_manager_panel.dart';
import 'workbench_agent_panel.dart';
import 'workbench_object_panel_body.dart';
import 'workbench_project_panel.dart';

class WorkbenchSidePanelHost extends StatelessWidget {
  const WorkbenchSidePanelHost({
    super.key,
    required this.selectedPanelId,
    required this.selectedContract,
    required this.resourceListenable,
    required this.conversationListenable,
    required this.resourceHandler,
  });

  final WorkbenchNavigationPanelId selectedPanelId;
  final WorkbenchSidePanelContract selectedContract;
  final ValueListenable<WorkbenchResourceViewData> resourceListenable;
  final ValueListenable<WorkbenchConversationViewData> conversationListenable;
  final ResourceManagerActionHandler resourceHandler;

  static const WorkbenchProjectPanelViewDataService
  _projectPanelViewDataService = WorkbenchProjectPanelViewDataService();
  static const WorkbenchAgentPanelViewDataService _agentPanelViewDataService =
      WorkbenchAgentPanelViewDataService();

  @override
  Widget build(BuildContext context) {
    return WorkbenchObjectPanelBody(
      semanticsLabel: '${selectedContract.objectTitle}对象面板',
      child: KeyedSubtree(
        key: ValueKey(selectedContract.panelId),
        child: switch (selectedPanelId) {
          WorkbenchNavigationPanelId.files =>
            ValueListenableBuilder<WorkbenchResourceViewData>(
              valueListenable: resourceListenable,
              builder: (context, resourceViewData, _) => ResourceManagerPanel(
                viewData: resourceViewData,
                actionHandler: resourceHandler,
              ),
            ),
          WorkbenchNavigationPanelId.project => AnimatedBuilder(
            animation: Listenable.merge([
              resourceListenable,
              conversationListenable,
            ]),
            builder: (context, _) {
              final resourceViewData = resourceListenable.value;
              final conversationViewData = conversationListenable.value;
              return WorkbenchProjectPanel(
                viewData: _projectPanelViewDataService.build(
                  resourceViewData: resourceViewData,
                  conversationViewData: conversationViewData,
                ),
                resourceHandler: resourceHandler,
              );
            },
          ),
          WorkbenchNavigationPanelId.agent => AnimatedBuilder(
            animation: Listenable.merge([
              resourceListenable,
              conversationListenable,
            ]),
            builder: (context, _) {
              final resourceViewData = resourceListenable.value;
              final conversationViewData = conversationListenable.value;
              return WorkbenchAgentPanel(
                viewData: _agentPanelViewDataService.build(
                  resourceViewData: resourceViewData,
                  conversationViewData: conversationViewData,
                ),
                resourceHandler: resourceHandler,
              );
            },
          ),
        },
      ),
    );
  }
}
