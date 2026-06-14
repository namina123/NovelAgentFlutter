import '../../presentation/models/workbench_canvas_view_data.dart';
import '../../presentation/models/workbench_conversation_view_data.dart';
import '../../presentation/models/workbench_resource_view_data.dart';
import '../../presentation/models/workbench_workspace_shell_view_data.dart';
import 'project_agent_group_panel_view_data_service.dart';

class WorkbenchWorkspaceShellViewDataService {
  const WorkbenchWorkspaceShellViewDataService({
    ProjectAgentGroupPanelViewDataService?
    projectAgentGroupPanelViewDataService,
  }) : _projectAgentGroupPanelViewDataService =
           projectAgentGroupPanelViewDataService ??
           const ProjectAgentGroupPanelViewDataService();

  final ProjectAgentGroupPanelViewDataService
  _projectAgentGroupPanelViewDataService;

  WorkbenchWorkspaceShellViewData build({
    required WorkbenchResourceViewData resource,
    required WorkbenchCanvasViewData canvas,
    required WorkbenchConversationViewData conversation,
  }) {
    return WorkbenchWorkspaceShellViewData(
      projectName: resource.projectName,
      projectSubtitle: resource.projectSubtitle,
      projectTypeId: resource.projectTypeId,
      resourceCount: resource.resourceEntries.length,
      activeDocumentTitle: canvas.activeDocumentTitle,
      activeDocumentPath: canvas.activeDocumentPath,
      activeDocumentBody: canvas.activeDocumentBody,
      activeDocumentDirty: canvas.activeDocumentDirty,
      activeDocumentCanRender: canvas.activeDocumentCanRender,
      generationStatus: canvas.generationStatus,
      contextSummary: conversation.contextSummary,
      workflowTitle: conversation.workflowTitle,
      workflowDescription: conversation.workflowDescription,
      modelLabel: conversation.modelLabel,
      agentGroupLabel: conversation.groupSelector.currentGroupLabel,
      primaryAgentLabel: conversation.groupSelector.primaryAgentLabel,
      toolCoreStatus: conversation.toolCoreStatus,
      pendingOptionCount: conversation.pendingOptions.length,
      subAgentRunCount: conversation.subAgentRuns.length,
      isGenerating: conversation.isGenerating,
      projectAgentGroupPanel: _projectAgentGroupPanelViewDataService.build(
        hasActiveProject: conversation.hasActiveProject,
        currentGroupLabel: conversation.groupSelector.currentGroupLabel,
        primaryAgentLabel: conversation.groupSelector.primaryAgentLabel,
      ),
      projectLongTaskSummary: resource.projectLongTaskSummary,
    );
  }
}
