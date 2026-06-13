import 'project_long_task_summary_view_data.dart';
import 'project_agent_group_panel_view_data.dart';
import 'workbench_project_panel_action_view_data.dart';

class WorkbenchProjectPanelViewData {
  const WorkbenchProjectPanelViewData({
    required this.projectName,
    required this.projectSubtitle,
    required this.workflowTitle,
    required this.workflowDescription,
    required this.modelLabel,
    required this.agentGroupLabel,
    required this.primaryAgentLabel,
    required this.projectAgentGroupPanel,
    required this.hasActiveProject,
    required this.primaryActions,
    required this.assetActions,
    this.projectLongTaskSummary,
  });

  final String projectName;
  final String projectSubtitle;
  final String workflowTitle;
  final String workflowDescription;
  final String modelLabel;
  final String agentGroupLabel;
  final String primaryAgentLabel;
  final ProjectAgentGroupPanelViewData projectAgentGroupPanel;
  final bool hasActiveProject;
  final List<WorkbenchProjectPanelActionViewData> primaryActions;
  final List<WorkbenchProjectPanelActionViewData> assetActions;
  final ProjectLongTaskSummaryViewData? projectLongTaskSummary;
}
