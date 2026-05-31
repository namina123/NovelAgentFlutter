import '../../presentation/models/workbench_project_panel_view_data.dart';
import '../../presentation/models/workbench_workspace_shell_view_data.dart';
import 'workbench_project_panel_action_policy_service.dart';

class WorkbenchProjectPanelViewDataService {
  const WorkbenchProjectPanelViewDataService({
    WorkbenchProjectPanelActionPolicyService? actionPolicyService,
  }) : _actionPolicyService =
           actionPolicyService ?? const WorkbenchProjectPanelActionPolicyService();

  final WorkbenchProjectPanelActionPolicyService _actionPolicyService;

  WorkbenchProjectPanelViewData build(
    WorkbenchWorkspaceShellViewData source,
  ) {
    final hasActiveProject = source.projectName.trim().isNotEmpty;
    return WorkbenchProjectPanelViewData(
      projectName: source.projectName,
      projectSubtitle: source.projectSubtitle,
      workflowTitle: source.workflowTitle,
      workflowDescription: source.workflowDescription,
      modelLabel: source.modelLabel,
      agentGroupLabel: source.agentGroupLabel,
      primaryAgentLabel: source.primaryAgentLabel,
      projectAgentGroupPanel: source.projectAgentGroupPanel,
      hasActiveProject: hasActiveProject,
      primaryActions: _actionPolicyService.primaryActions(
        hasActiveProject: hasActiveProject,
      ),
      assetActions: _actionPolicyService.assetActions(
        hasActiveProject: hasActiveProject,
      ),
    );
  }
}
