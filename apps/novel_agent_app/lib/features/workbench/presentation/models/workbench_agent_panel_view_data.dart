import 'project_agent_group_panel_view_data.dart';
import 'workbench_project_panel_action_view_data.dart';

class WorkbenchAgentPanelViewData {
  const WorkbenchAgentPanelViewData({
    required this.projectName,
    required this.hasActiveProject,
    required this.currentAgentLabel,
    required this.currentAgentDescription,
    required this.currentAgentOptionCount,
    required this.canSwitchAgent,
    required this.currentGroupLabel,
    required this.primaryAgentLabel,
    required this.projectAgentGroupPanel,
    required this.agentWorkspaceActions,
  });

  final String projectName;
  final bool hasActiveProject;
  final String currentAgentLabel;
  final String currentAgentDescription;
  final int currentAgentOptionCount;
  final bool canSwitchAgent;
  final String currentGroupLabel;
  final String primaryAgentLabel;
  final ProjectAgentGroupPanelViewData projectAgentGroupPanel;
  final List<WorkbenchProjectPanelActionViewData> agentWorkspaceActions;
}
