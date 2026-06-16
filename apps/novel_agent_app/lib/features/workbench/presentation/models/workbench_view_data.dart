import 'package:novel_agent_core/novel_agent_core.dart';

import 'conversation_entry_view_data.dart';
import 'conversation_agent_selector_view_data.dart';
import 'conversation_group_selector_view_data.dart';
import 'conversation_input_capability_context.dart';
import 'conversation_opening_state_view_data.dart';
import 'tool_preview_mode.dart';
import 'document_tab_view_data.dart';
import 'opening_panel_view_data.dart';
import 'primary_action_view_data.dart';
import 'project_agent_group_workspace_view_data.dart';
import 'project_long_task_summary_view_data.dart';
import 'project_launcher_view_data.dart';
import 'resource_entry_view_data.dart';
import 'retry_request_view_data.dart';
import 'selector_option_view_data.dart';
import 'session_history_entry_view_data.dart';
import 'conversation_context_projection_view_data.dart';
import 'sub_agent_run_view_data.dart';
import 'user_option_view_data.dart';
import 'workbench_information_view_data.dart';
import 'workspace_command_request_view_data.dart';

export 'document_tab_view_data.dart';
export 'primary_action_view_data.dart';
export 'resource_entry_view_data.dart';
export 'workspace_command_request_view_data.dart';

class WorkbenchViewData {
  const WorkbenchViewData({
    required this.projectName,
    required this.projectSubtitle,
    required this.projectPath,
    this.projectTypeId = '',
    this.projectTypeTransitionAvailability =
        const EntryAvailabilityDecision.hiddenContract(
          entryId: 'workspace.transition_project_type',
        ),
    required this.toolCoreStatus,
    this.toolPreviewMode = ToolPreviewMode.compact,
    required this.projectLongTaskSummary,
    required this.documents,
    required this.resourceEntries,
    required this.informationViewData,
    required this.modelLabel,
    required this.modelOptions,
    required this.groupSelector,
    this.agentSelector = const ConversationAgentSelectorViewData.initial(),
    required this.inputCapabilityContext,
    required this.contextSummary,
    this.conversationContextProjection,
    required this.workflowTitle,
    required this.workflowDescription,
    required this.primaryActions,
    required this.openingPanel,
    this.openingState,
    required this.composerHint,
    required this.activeDocumentTitle,
    required this.activeDocumentPath,
    required this.activeDocumentBody,
    required this.activeDocumentDirty,
    required this.activeDocumentBufferedDraft,
    required this.activeDocumentCanRender,
    required this.isActiveDocumentRendered,
    required this.conversationEntries,
    required this.pendingOptions,
    required this.subAgentRuns,
    required this.retryRequest,
    required this.sessionHistoryEntries,
    required this.activeSessionId,
    required this.showSessionHistory,
    required this.isDocumentsWorkspaceVisible,
    required this.projectLauncher,
    required this.projectAgentGroupWorkspace,
    required this.workspaceCommand,
    required this.generationStatus,
    required this.isGenerating,
  });

  final String projectName;
  final String projectSubtitle;
  final String projectPath;
  final String projectTypeId;
  final EntryAvailabilityDecision projectTypeTransitionAvailability;
  final String toolCoreStatus;
  final String toolPreviewMode;
  final ProjectLongTaskSummaryViewData? projectLongTaskSummary;
  final List<DocumentTabViewData> documents;
  final List<ResourceEntryViewData> resourceEntries;
  final WorkbenchInformationViewData informationViewData;
  final String modelLabel;
  final List<SelectorOptionViewData> modelOptions;
  final ConversationGroupSelectorViewData groupSelector;
  final ConversationAgentSelectorViewData agentSelector;
  final ConversationInputCapabilityContext inputCapabilityContext;
  final String contextSummary;
  final ConversationContextProjectionViewData? conversationContextProjection;
  final String workflowTitle;
  final String workflowDescription;
  final List<PrimaryActionViewData> primaryActions;
  final OpeningPanelViewData? openingPanel;
  final ConversationOpeningStateViewData? openingState;
  final String composerHint;
  final String activeDocumentTitle;
  final String activeDocumentPath;
  final String activeDocumentBody;
  final bool activeDocumentDirty;
  final bool activeDocumentBufferedDraft;
  final bool activeDocumentCanRender;
  final bool isActiveDocumentRendered;
  final List<ConversationEntryViewData> conversationEntries;
  final List<UserOptionViewData> pendingOptions;
  final List<SubAgentRunViewData> subAgentRuns;
  final RetryRequestViewData? retryRequest;
  final List<SessionHistoryEntryViewData> sessionHistoryEntries;
  final String activeSessionId;
  final bool showSessionHistory;
  final bool isDocumentsWorkspaceVisible;
  final ProjectLauncherViewData? projectLauncher;
  final ProjectAgentGroupWorkspaceViewData? projectAgentGroupWorkspace;
  final WorkspaceCommandViewData? workspaceCommand;
  final String generationStatus;
  final bool isGenerating;

  factory WorkbenchViewData.initial() {
    return const WorkbenchViewData(
      projectName: '未打开项目',
      projectSubtitle: '',
      projectPath: '',
      projectTypeId: '',
      projectTypeTransitionAvailability:
          EntryAvailabilityDecision.hiddenContract(
            entryId: 'workspace.transition_project_type',
          ),
      toolCoreStatus: '',
      toolPreviewMode: ToolPreviewMode.compact,
      projectLongTaskSummary: null,
      documents: [],
      resourceEntries: [],
      informationViewData: WorkbenchInformationViewData(),
      modelLabel: '未加载模型',
      modelOptions: [],
      groupSelector: ConversationGroupSelectorViewData.initial(),
      agentSelector: ConversationAgentSelectorViewData.initial(),
      inputCapabilityContext: ConversationInputCapabilityContext.initial(),
      contextSummary: '未开始会话',
      workflowTitle: '开始会话',
      workflowDescription: '先创建或打开项目。',
      primaryActions: [
        PrimaryActionViewData(
          id: 'refresh_project',
          title: '刷新项目',
          description: '重新读取默认项目目录与资源树。',
          commandId: 'refresh_project',
        ),
        PrimaryActionViewData(
          id: 'draft_again',
          title: '继续生成',
          description: '对当前项目再次发起内容生成。',
          commandId: 'draft_again',
        ),
      ],
      openingPanel: null,
      openingState: null,
      composerHint: '输入你的需求。',
      activeDocumentTitle: '',
      activeDocumentPath: '',
      activeDocumentBody: '',
      activeDocumentDirty: false,
      activeDocumentBufferedDraft: false,
      activeDocumentCanRender: false,
      isActiveDocumentRendered: false,
      conversationEntries: [],
      pendingOptions: [],
      subAgentRuns: [],
      retryRequest: null,
      sessionHistoryEntries: [],
      activeSessionId: '',
      showSessionHistory: false,
      isDocumentsWorkspaceVisible: false,
      projectLauncher: null,
      projectAgentGroupWorkspace: null,
      workspaceCommand: null,
      generationStatus: '',
      isGenerating: false,
    );
  }

  factory WorkbenchViewData.demo() {
    return WorkbenchViewData.initial();
  }

  WorkbenchViewData copyWith({
    String? projectName,
    String? projectSubtitle,
    String? projectPath,
    String? projectTypeId,
    Object? projectTypeTransitionAvailability =
        _projectTypeTransitionAvailabilitySentinel,
    String? toolCoreStatus,
    String? toolPreviewMode,
    Object? projectLongTaskSummary = _projectLongTaskSummarySentinel,
    List<DocumentTabViewData>? documents,
    List<ResourceEntryViewData>? resourceEntries,
    WorkbenchInformationViewData? informationViewData,
    String? modelLabel,
    List<SelectorOptionViewData>? modelOptions,
    ConversationGroupSelectorViewData? groupSelector,
    ConversationAgentSelectorViewData? agentSelector,
    ConversationInputCapabilityContext? inputCapabilityContext,
    String? contextSummary,
    Object? conversationContextProjection =
        _conversationContextProjectionSentinel,
    String? workflowTitle,
    String? workflowDescription,
    List<PrimaryActionViewData>? primaryActions,
    Object? openingPanel = _openingPanelSentinel,
    Object? openingState = _conversationOpeningStateSentinel,
    String? composerHint,
    String? activeDocumentTitle,
    String? activeDocumentPath,
    String? activeDocumentBody,
    bool? activeDocumentDirty,
    bool? activeDocumentBufferedDraft,
    bool? activeDocumentCanRender,
    bool? isActiveDocumentRendered,
    List<ConversationEntryViewData>? conversationEntries,
    List<UserOptionViewData>? pendingOptions,
    List<SubAgentRunViewData>? subAgentRuns,
    Object? retryRequest = _retryRequestViewSentinel,
    List<SessionHistoryEntryViewData>? sessionHistoryEntries,
    String? activeSessionId,
    bool? showSessionHistory,
    bool? isDocumentsWorkspaceVisible,
    Object? projectLauncher = _projectLauncherSentinel,
    Object? projectAgentGroupWorkspace = _projectAgentGroupWorkspaceSentinel,
    Object? workspaceCommand = _workspaceCommandSentinel,
    String? generationStatus,
    bool? isGenerating,
  }) {
    // 中文注释: 工作台状态通过局部 copy 维护，避免每次异步动作都手写整份视图模型重建。
    return WorkbenchViewData(
      projectName: projectName ?? this.projectName,
      projectSubtitle: projectSubtitle ?? this.projectSubtitle,
      projectPath: projectPath ?? this.projectPath,
      projectTypeId: projectTypeId ?? this.projectTypeId,
      projectTypeTransitionAvailability:
          identical(
            projectTypeTransitionAvailability,
            _projectTypeTransitionAvailabilitySentinel,
          )
          ? this.projectTypeTransitionAvailability
          : projectTypeTransitionAvailability as EntryAvailabilityDecision,
      toolCoreStatus: toolCoreStatus ?? this.toolCoreStatus,
      toolPreviewMode: ToolPreviewMode.normalize(
        toolPreviewMode ?? this.toolPreviewMode,
      ),
      projectLongTaskSummary:
          identical(projectLongTaskSummary, _projectLongTaskSummarySentinel)
          ? this.projectLongTaskSummary
          : projectLongTaskSummary as ProjectLongTaskSummaryViewData?,
      documents: documents ?? this.documents,
      resourceEntries: resourceEntries ?? this.resourceEntries,
      informationViewData: informationViewData ?? this.informationViewData,
      modelLabel: modelLabel ?? this.modelLabel,
      modelOptions: modelOptions ?? this.modelOptions,
      groupSelector: groupSelector ?? this.groupSelector,
      agentSelector: agentSelector ?? this.agentSelector,
      inputCapabilityContext:
          inputCapabilityContext ?? this.inputCapabilityContext,
      contextSummary: contextSummary ?? this.contextSummary,
      conversationContextProjection:
          identical(
            conversationContextProjection,
            _conversationContextProjectionSentinel,
          )
          ? this.conversationContextProjection
          : conversationContextProjection
                as ConversationContextProjectionViewData?,
      workflowTitle: workflowTitle ?? this.workflowTitle,
      workflowDescription: workflowDescription ?? this.workflowDescription,
      primaryActions: primaryActions ?? this.primaryActions,
      openingPanel: identical(openingPanel, _openingPanelSentinel)
          ? this.openingPanel
          : openingPanel as OpeningPanelViewData?,
      openingState: identical(openingState, _conversationOpeningStateSentinel)
          ? this.openingState
          : openingState as ConversationOpeningStateViewData?,
      composerHint: composerHint ?? this.composerHint,
      activeDocumentTitle: activeDocumentTitle ?? this.activeDocumentTitle,
      activeDocumentPath: activeDocumentPath ?? this.activeDocumentPath,
      activeDocumentBody: activeDocumentBody ?? this.activeDocumentBody,
      activeDocumentDirty: activeDocumentDirty ?? this.activeDocumentDirty,
      activeDocumentBufferedDraft:
          activeDocumentBufferedDraft ?? this.activeDocumentBufferedDraft,
      activeDocumentCanRender:
          activeDocumentCanRender ?? this.activeDocumentCanRender,
      isActiveDocumentRendered:
          isActiveDocumentRendered ?? this.isActiveDocumentRendered,
      conversationEntries: conversationEntries ?? this.conversationEntries,
      pendingOptions: pendingOptions ?? this.pendingOptions,
      subAgentRuns: subAgentRuns ?? this.subAgentRuns,
      retryRequest: identical(retryRequest, _retryRequestViewSentinel)
          ? this.retryRequest
          : retryRequest as RetryRequestViewData?,
      sessionHistoryEntries:
          sessionHistoryEntries ?? this.sessionHistoryEntries,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      showSessionHistory: showSessionHistory ?? this.showSessionHistory,
      isDocumentsWorkspaceVisible:
          isDocumentsWorkspaceVisible ?? this.isDocumentsWorkspaceVisible,
      projectLauncher: identical(projectLauncher, _projectLauncherSentinel)
          ? this.projectLauncher
          : projectLauncher as ProjectLauncherViewData?,
      projectAgentGroupWorkspace:
          identical(
            projectAgentGroupWorkspace,
            _projectAgentGroupWorkspaceSentinel,
          )
          ? this.projectAgentGroupWorkspace
          : projectAgentGroupWorkspace as ProjectAgentGroupWorkspaceViewData?,
      workspaceCommand: identical(workspaceCommand, _workspaceCommandSentinel)
          ? this.workspaceCommand
          : workspaceCommand as WorkspaceCommandViewData?,
      generationStatus: generationStatus ?? this.generationStatus,
      isGenerating: isGenerating ?? this.isGenerating,
    );
  }
}

const Object _projectLauncherSentinel = Object();
const Object _projectAgentGroupWorkspaceSentinel = Object();
const Object _workspaceCommandSentinel = Object();
const Object _retryRequestViewSentinel = Object();
const Object _projectLongTaskSummarySentinel = Object();
const Object _projectTypeTransitionAvailabilitySentinel = Object();
const Object _conversationContextProjectionSentinel = Object();
const Object _openingPanelSentinel = Object();
const Object _conversationOpeningStateSentinel = Object();
