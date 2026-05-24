import 'conversation_entry_view_data.dart';
import 'document_tab_view_data.dart';
import 'primary_action_view_data.dart';
import 'project_launcher_view_data.dart';
import 'resource_entry_view_data.dart';
import 'session_history_entry_view_data.dart';
import 'sub_agent_run_view_data.dart';
import 'user_option_view_data.dart';
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
    required this.toolCoreStatus,
    required this.documents,
    required this.resourceEntries,
    required this.modelLabel,
    required this.agentLabel,
    required this.contextSummary,
    required this.workflowTitle,
    required this.workflowDescription,
    required this.primaryActions,
    required this.composerHint,
    required this.activeDocumentTitle,
    required this.activeDocumentPath,
    required this.activeDocumentBody,
    required this.activeDocumentDirty,
    required this.conversationEntries,
    required this.pendingOptions,
    required this.subAgentRuns,
    required this.sessionHistoryEntries,
    required this.activeSessionId,
    required this.showSessionHistory,
    required this.isDocumentsWorkspaceVisible,
    required this.projectLauncher,
    required this.workspaceCommand,
    required this.generationStatus,
    required this.isGenerating,
  });

  final String projectName;
  final String projectSubtitle;
  final String projectPath;
  final String toolCoreStatus;
  final List<DocumentTabViewData> documents;
  final List<ResourceEntryViewData> resourceEntries;
  final String modelLabel;
  final String agentLabel;
  final String contextSummary;
  final String workflowTitle;
  final String workflowDescription;
  final List<PrimaryActionViewData> primaryActions;
  final String composerHint;
  final String activeDocumentTitle;
  final String activeDocumentPath;
  final String activeDocumentBody;
  final bool activeDocumentDirty;
  final List<ConversationEntryViewData> conversationEntries;
  final List<UserOptionViewData> pendingOptions;
  final List<SubAgentRunViewData> subAgentRuns;
  final List<SessionHistoryEntryViewData> sessionHistoryEntries;
  final String activeSessionId;
  final bool showSessionHistory;
  final bool isDocumentsWorkspaceVisible;
  final ProjectLauncherViewData? projectLauncher;
  final WorkspaceCommandViewData? workspaceCommand;
  final String generationStatus;
  final bool isGenerating;

  factory WorkbenchViewData.initial() {
    return const WorkbenchViewData(
      projectName: '未打开项目',
      projectSubtitle: '',
      projectPath: '',
      toolCoreStatus: '',
      documents: [],
      resourceEntries: [],
      modelLabel: '未加载模型',
      agentLabel: '综合创作智能体',
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
          description: '对当前项目再次发起草稿生成。',
          commandId: 'draft_again',
        ),
      ],
      composerHint: '输入你的需求。',
      activeDocumentTitle: '',
      activeDocumentPath: '',
      activeDocumentBody: '',
      activeDocumentDirty: false,
      conversationEntries: [],
      pendingOptions: [],
      subAgentRuns: [],
      sessionHistoryEntries: [],
      activeSessionId: '',
      showSessionHistory: false,
      isDocumentsWorkspaceVisible: false,
      projectLauncher: null,
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
    String? toolCoreStatus,
    List<DocumentTabViewData>? documents,
    List<ResourceEntryViewData>? resourceEntries,
    String? modelLabel,
    String? agentLabel,
    String? contextSummary,
    String? workflowTitle,
    String? workflowDescription,
    List<PrimaryActionViewData>? primaryActions,
    String? composerHint,
    String? activeDocumentTitle,
    String? activeDocumentPath,
    String? activeDocumentBody,
    bool? activeDocumentDirty,
    List<ConversationEntryViewData>? conversationEntries,
    List<UserOptionViewData>? pendingOptions,
    List<SubAgentRunViewData>? subAgentRuns,
    List<SessionHistoryEntryViewData>? sessionHistoryEntries,
    String? activeSessionId,
    bool? showSessionHistory,
    bool? isDocumentsWorkspaceVisible,
    Object? projectLauncher = _projectLauncherSentinel,
    Object? workspaceCommand = _workspaceCommandSentinel,
    String? generationStatus,
    bool? isGenerating,
  }) {
    // 中文注释: 工作台状态通过局部 copy 维护，避免每次异步动作都手写整份视图模型重建。
    return WorkbenchViewData(
      projectName: projectName ?? this.projectName,
      projectSubtitle: projectSubtitle ?? this.projectSubtitle,
      projectPath: projectPath ?? this.projectPath,
      toolCoreStatus: toolCoreStatus ?? this.toolCoreStatus,
      documents: documents ?? this.documents,
      resourceEntries: resourceEntries ?? this.resourceEntries,
      modelLabel: modelLabel ?? this.modelLabel,
      agentLabel: agentLabel ?? this.agentLabel,
      contextSummary: contextSummary ?? this.contextSummary,
      workflowTitle: workflowTitle ?? this.workflowTitle,
      workflowDescription: workflowDescription ?? this.workflowDescription,
      primaryActions: primaryActions ?? this.primaryActions,
      composerHint: composerHint ?? this.composerHint,
      activeDocumentTitle: activeDocumentTitle ?? this.activeDocumentTitle,
      activeDocumentPath: activeDocumentPath ?? this.activeDocumentPath,
      activeDocumentBody: activeDocumentBody ?? this.activeDocumentBody,
      activeDocumentDirty: activeDocumentDirty ?? this.activeDocumentDirty,
      conversationEntries: conversationEntries ?? this.conversationEntries,
      pendingOptions: pendingOptions ?? this.pendingOptions,
      subAgentRuns: subAgentRuns ?? this.subAgentRuns,
      sessionHistoryEntries:
          sessionHistoryEntries ?? this.sessionHistoryEntries,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      showSessionHistory: showSessionHistory ?? this.showSessionHistory,
      isDocumentsWorkspaceVisible:
          isDocumentsWorkspaceVisible ?? this.isDocumentsWorkspaceVisible,
      projectLauncher: identical(projectLauncher, _projectLauncherSentinel)
          ? this.projectLauncher
          : projectLauncher as ProjectLauncherViewData?,
      workspaceCommand: identical(workspaceCommand, _workspaceCommandSentinel)
          ? this.workspaceCommand
          : workspaceCommand as WorkspaceCommandViewData?,
      generationStatus: generationStatus ?? this.generationStatus,
      isGenerating: isGenerating ?? this.isGenerating,
    );
  }
}

const Object _projectLauncherSentinel = Object();
const Object _workspaceCommandSentinel = Object();
