import '../../presentation/models/workbench_conversation_view_data.dart';
import '../../presentation/models/workbench_resource_view_data.dart';
import '../../presentation/models/workbench_project_panel_view_data.dart';
import 'workbench_project_panel_action_policy_service.dart';
import 'project_agent_group_panel_view_data_service.dart';

class WorkbenchProjectPanelViewDataService {
  const WorkbenchProjectPanelViewDataService({
    WorkbenchProjectPanelActionPolicyService? actionPolicyService,
    ProjectAgentGroupPanelViewDataService?
    projectAgentGroupPanelViewDataService,
  }) : _actionPolicyService =
           actionPolicyService ??
           const WorkbenchProjectPanelActionPolicyService(),
       _projectAgentGroupPanelViewDataService =
           projectAgentGroupPanelViewDataService ??
           const ProjectAgentGroupPanelViewDataService();

  final WorkbenchProjectPanelActionPolicyService _actionPolicyService;
  final ProjectAgentGroupPanelViewDataService
  _projectAgentGroupPanelViewDataService;

  WorkbenchProjectPanelViewData build({
    required WorkbenchResourceViewData resourceViewData,
    required WorkbenchConversationViewData conversationViewData,
  }) {
    final hasActiveProject = resourceViewData.projectName.trim().isNotEmpty;
    return WorkbenchProjectPanelViewData(
      projectName: resourceViewData.projectName,
      projectSubtitle: resourceViewData.projectSubtitle,
      projectTypeId: resourceViewData.projectTypeId,
      workflowTitle: conversationViewData.workflowTitle,
      workflowDescription: conversationViewData.workflowDescription,
      modelLabel: conversationViewData.modelLabel,
      agentGroupLabel: conversationViewData.groupSelector.currentGroupLabel,
      primaryAgentLabel: conversationViewData.groupSelector.primaryAgentLabel,
      projectAgentGroupPanel: _projectAgentGroupPanelViewDataService.build(
        hasActiveProject: conversationViewData.hasActiveProject,
        currentGroupLabel: conversationViewData.groupSelector.currentGroupLabel,
        primaryAgentLabel: conversationViewData.groupSelector.primaryAgentLabel,
      ),
      hasActiveProject: hasActiveProject,
      primaryActions: _actionPolicyService.primaryActions(
        hasActiveProject: hasActiveProject,
        projectTypeId: resourceViewData.projectTypeId,
        projectTypeTransitionAvailability:
            resourceViewData.projectTypeTransitionAvailability,
      ),
      assetActions: _actionPolicyService.assetActions(
        hasActiveProject: hasActiveProject,
        projectTypeId: resourceViewData.projectTypeId,
      ),
      projectLongTaskSummary: resourceViewData.projectLongTaskSummary,
    );
  }
}
