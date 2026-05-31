import '../../presentation/models/workbench_agent_panel_view_data.dart';
import '../../presentation/models/workbench_conversation_view_data.dart';
import '../../presentation/models/workbench_workspace_shell_view_data.dart';
import 'workbench_agent_panel_action_policy_service.dart';

class WorkbenchAgentPanelViewDataService {
  const WorkbenchAgentPanelViewDataService({
    WorkbenchAgentPanelActionPolicyService? actionPolicyService,
  }) : _actionPolicyService =
           actionPolicyService ??
           const WorkbenchAgentPanelActionPolicyService();

  final WorkbenchAgentPanelActionPolicyService _actionPolicyService;

  WorkbenchAgentPanelViewData build({
    required WorkbenchWorkspaceShellViewData shellViewData,
    required WorkbenchConversationViewData conversationViewData,
  }) {
    final agentSelector = conversationViewData.agentSelector;
    return WorkbenchAgentPanelViewData(
      projectName: shellViewData.projectName,
      hasActiveProject: conversationViewData.hasActiveProject,
      currentAgentLabel: agentSelector.currentAgentLabel,
      currentAgentDescription: agentSelector.currentAgentDescription,
      currentAgentOptionCount: agentSelector.agentOptions.length,
      canSwitchAgent: agentSelector.canSwitchAgent,
      currentGroupLabel: shellViewData.agentGroupLabel,
      primaryAgentLabel: shellViewData.primaryAgentLabel,
      projectAgentGroupPanel: shellViewData.projectAgentGroupPanel,
      agentWorkspaceActions: _actionPolicyService.workspaceActions(
        hasActiveProject: conversationViewData.hasActiveProject,
      ),
    );
  }
}
