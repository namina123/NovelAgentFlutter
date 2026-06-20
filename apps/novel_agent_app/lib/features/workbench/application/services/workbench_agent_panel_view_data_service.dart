import '../../presentation/models/workbench_agent_panel_view_data.dart';
import '../../presentation/models/workbench_conversation_view_data.dart';
import '../../presentation/models/workbench_resource_view_data.dart';
import 'workbench_agent_panel_action_policy_service.dart';
import 'project_agent_group_panel_view_data_service.dart';

class WorkbenchAgentPanelViewDataService {
  const WorkbenchAgentPanelViewDataService({
    WorkbenchAgentPanelActionPolicyService? actionPolicyService,
    ProjectAgentGroupPanelViewDataService?
    projectAgentGroupPanelViewDataService,
  }) : _actionPolicyService =
           actionPolicyService ??
           const WorkbenchAgentPanelActionPolicyService(),
       _projectAgentGroupPanelViewDataService =
           projectAgentGroupPanelViewDataService ??
           const ProjectAgentGroupPanelViewDataService();

  final WorkbenchAgentPanelActionPolicyService _actionPolicyService;
  final ProjectAgentGroupPanelViewDataService
  _projectAgentGroupPanelViewDataService;

  WorkbenchAgentPanelViewData build({
    required WorkbenchResourceViewData resourceViewData,
    required WorkbenchConversationViewData conversationViewData,
  }) {
    final agentSelector = conversationViewData.agentSelector;
    return WorkbenchAgentPanelViewData(
      projectName: resourceViewData.projectName,
      hasActiveProject: conversationViewData.hasActiveProject,
      currentAgentLabel: agentSelector.currentAgentLabel,
      currentAgentDescription: agentSelector.currentAgentDescription,
      currentAgentOptionCount: agentSelector.agentOptions.length,
      canSwitchAgent: agentSelector.canSwitchAgent,
      currentGroupLabel: conversationViewData.groupSelector.currentGroupLabel,
      primaryAgentLabel: conversationViewData.groupSelector.primaryAgentLabel,
      projectAgentGroupPanel: _projectAgentGroupPanelViewDataService.build(
        hasActiveProject: conversationViewData.hasActiveProject,
        currentGroupLabel: conversationViewData.groupSelector.currentGroupLabel,
        primaryAgentLabel: conversationViewData.groupSelector.primaryAgentLabel,
      ),
      agentWorkspaceActions: _actionPolicyService.workspaceActions(
        hasActiveProject: conversationViewData.hasActiveProject,
      ),
    );
  }
}
