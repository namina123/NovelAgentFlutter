import 'conversation_transcript_block_projection_service.dart';
import '../../presentation/models/workbench_canvas_view_data.dart';
import '../../presentation/models/workbench_conversation_view_data.dart';
import '../../presentation/models/workbench_overlay_view_data.dart';
import '../../presentation/models/workbench_resource_view_data.dart';
import '../../presentation/models/workbench_view_data.dart';
import '../../presentation/services/conversation_transcript_lane_projection_service.dart';

class WorkbenchPaneViewDataMapperService {
  const WorkbenchPaneViewDataMapperService({
    ConversationTranscriptBlockProjectionService?
    transcriptBlockProjectionService,
    ConversationTranscriptLaneProjectionService?
    transcriptLaneProjectionService,
  }) : _transcriptBlockProjectionService =
           transcriptBlockProjectionService ??
           const ConversationTranscriptBlockProjectionService(),
       _transcriptLaneProjectionService =
           transcriptLaneProjectionService ??
           const ConversationTranscriptLaneProjectionService();

  final ConversationTranscriptBlockProjectionService
  _transcriptBlockProjectionService;
  final ConversationTranscriptLaneProjectionService
  _transcriptLaneProjectionService;

  WorkbenchResourceViewData toResourceViewData(WorkbenchViewData source) {
    // 中文注释: 资源区只消费项目摘要与资源树，不再承担长任务入口或摘要语义。
    return WorkbenchResourceViewData(
      projectName: source.projectName,
      projectSubtitle: source.projectSubtitle,
      resourceEntries: source.resourceEntries,
      informationViewData: source.informationViewData,
      projectLongTaskSummary: source.projectLongTaskSummary,
    );
  }

  WorkbenchCanvasViewData toCanvasViewData(WorkbenchViewData source) {
    // 中文注释: 主画布只消费文档与显示模式相关字段，避免会话流式状态拖着正文区重建。
    return WorkbenchCanvasViewData(
      documents: source.documents,
      activeDocumentTitle: source.activeDocumentTitle,
      activeDocumentPath: source.activeDocumentPath,
      activeDocumentBody: source.activeDocumentBody,
      activeDocumentDirty: source.activeDocumentDirty,
      activeDocumentCanRender: source.activeDocumentCanRender,
      isActiveDocumentRendered: source.isActiveDocumentRendered,
      isDocumentsWorkspaceVisible: source.isDocumentsWorkspaceVisible,
      generationStatus: source.generationStatus,
    );
  }

  WorkbenchConversationViewData toConversationViewData(
    WorkbenchViewData source,
  ) {
    // 中文注释: 会话区单独承接模型、上下文、时间线与输入状态，避免资源树和正文区共享同一批刷新字段。
    final transcriptBlocks = _transcriptBlockProjectionService.build(
      entries: source.conversationEntries,
      isGenerating: source.isGenerating,
      pendingOptions: source.pendingOptions,
      subAgentRuns: source.subAgentRuns,
      retryRequest: source.retryRequest,
    );
    return WorkbenchConversationViewData(
      hasActiveProject: source.projectPath.trim().isNotEmpty,
      toolCoreStatus: source.toolCoreStatus,
      toolPreviewMode: source.toolPreviewMode,
      modelLabel: source.modelLabel,
      modelOptions: source.modelOptions,
      groupSelector: source.groupSelector,
      agentSelector: source.agentSelector,
      inputCapabilityContext: source.inputCapabilityContext.copyWith(
        isGenerating: source.isGenerating,
        hasActiveProject: source.projectPath.trim().isNotEmpty,
      ),
      contextSummary: source.contextSummary,
      workflowTitle: source.workflowTitle,
      workflowDescription: source.workflowDescription,
      primaryActions: source.primaryActions,
      openingPanel: source.openingPanel,
      openingState: source.openingState,
      composerHint: source.composerHint,
      conversationEntries: source.conversationEntries,
      transcriptBlocks: transcriptBlocks,
      transcriptLanes: _transcriptLaneProjectionService.build(
        transcriptBlocks,
        isGenerating: source.isGenerating,
      ),
      pendingOptions: source.pendingOptions,
      subAgentRuns: source.subAgentRuns,
      retryRequest: source.retryRequest,
      sessionHistoryEntries: source.sessionHistoryEntries,
      activeSessionId: source.activeSessionId,
      showSessionHistory: source.showSessionHistory,
      generationStatus: source.generationStatus,
      isGenerating: source.isGenerating,
    );
  }

  WorkbenchOverlayViewData toOverlayViewData(WorkbenchViewData source) {
    // 中文注释: 浮层状态独立映射，确保 project launcher 和 workspace command 不再依附整页刷新。
    return WorkbenchOverlayViewData(
      projectLauncher: source.projectLauncher,
      projectAgentGroupWorkspace: source.projectAgentGroupWorkspace,
      workspaceCommand: source.workspaceCommand,
    );
  }
}
