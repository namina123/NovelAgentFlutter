import 'package:flutter/foundation.dart';

import '../../app/routing/app_destination.dart';
import '../../features/agent_ecosystem/presentation/models/agent_ecosystem_view_data.dart';
import '../../features/prompt_templates/presentation/models/prompt_templates_view_data.dart';
import '../../features/project_collection/presentation/models/project_collection_view_data.dart';
import '../../features/project_open/presentation/models/project_open_view_data.dart';
import '../../features/review_center/presentation/models/review_center_view_data.dart';
import '../../features/settings/presentation/models/settings_view_data.dart';
import '../../features/task_center/presentation/models/task_center_view_data.dart';
import '../../features/workbench/application/services/workbench_pane_view_data_mapper_service.dart';
import '../../features/workbench/presentation/models/workbench_canvas_view_data.dart';
import '../../features/workbench/presentation/models/workbench_conversation_view_data.dart';
import '../../features/workbench/presentation/models/conversation_transcript_lane_view_data.dart';
import '../../features/workbench/presentation/models/workbench_overlay_view_data.dart';
import '../../features/workbench/presentation/models/workbench_resource_view_data.dart';
import '../../features/workbench/presentation/models/workbench_view_data.dart';
import '../../shared/view_models/app_shell_view_model.dart';

class AppShellListenableState {
  AppShellListenableState({
    required AppShellViewModel viewModel,
    required String activeThemeId,
    WorkbenchPaneViewDataMapperService? paneViewDataMapperService,
  }) : _destination = ValueNotifier<AppDestination>(viewModel.destination),
       _activeThemeId = ValueNotifier<String>(activeThemeId),
       _paneViewDataMapperService =
           paneViewDataMapperService ??
           const WorkbenchPaneViewDataMapperService(),
       _workbench = ValueNotifier<WorkbenchViewData>(viewModel.workbench),
       _workbenchResource = ValueNotifier<WorkbenchResourceViewData>(
         (paneViewDataMapperService ??
                 const WorkbenchPaneViewDataMapperService())
             .toResourceViewData(viewModel.workbench),
       ),
       _workbenchCanvas = ValueNotifier<WorkbenchCanvasViewData>(
         (paneViewDataMapperService ??
                 const WorkbenchPaneViewDataMapperService())
             .toCanvasViewData(viewModel.workbench),
       ),
       _workbenchConversation = ValueNotifier<WorkbenchConversationViewData>(
         _safeConversationViewData(
           paneViewDataMapperService ??
               const WorkbenchPaneViewDataMapperService(),
           viewModel.workbench,
         ),
       ),
       _workbenchOverlay = ValueNotifier<WorkbenchOverlayViewData>(
         (paneViewDataMapperService ??
                 const WorkbenchPaneViewDataMapperService())
             .toOverlayViewData(viewModel.workbench),
       ),
       _settings = ValueNotifier<SettingsViewData>(viewModel.settings),
       _agentEcosystem = ValueNotifier<AgentEcosystemViewData>(
         viewModel.agentEcosystem,
       ),
       _projectOpen = ValueNotifier<ProjectOpenViewData>(viewModel.projectOpen),
       _projectCollection = ValueNotifier<ProjectCollectionViewData>(
         viewModel.projectCollection,
       ),
       _taskCenter = ValueNotifier<TaskCenterViewData>(viewModel.taskCenter),
       _reviewCenter = ValueNotifier<ReviewCenterViewData>(
         viewModel.reviewCenter,
       ),
       _promptTemplates = ValueNotifier<PromptTemplatesViewData>(
         viewModel.promptTemplates,
       );

  final ValueNotifier<AppDestination> _destination;
  final ValueNotifier<String> _activeThemeId;
  final WorkbenchPaneViewDataMapperService _paneViewDataMapperService;
  final ValueNotifier<WorkbenchViewData> _workbench;
  final ValueNotifier<WorkbenchResourceViewData> _workbenchResource;
  final ValueNotifier<WorkbenchCanvasViewData> _workbenchCanvas;
  final ValueNotifier<WorkbenchConversationViewData> _workbenchConversation;
  final ValueNotifier<WorkbenchOverlayViewData> _workbenchOverlay;
  final ValueNotifier<SettingsViewData> _settings;
  final ValueNotifier<AgentEcosystemViewData> _agentEcosystem;
  final ValueNotifier<ProjectOpenViewData> _projectOpen;
  final ValueNotifier<ProjectCollectionViewData> _projectCollection;
  final ValueNotifier<TaskCenterViewData> _taskCenter;
  final ValueNotifier<ReviewCenterViewData> _reviewCenter;
  final ValueNotifier<PromptTemplatesViewData> _promptTemplates;

  ValueListenable<AppDestination> get destinationListenable => _destination;
  ValueListenable<String> get activeThemeIdListenable => _activeThemeId;
  ValueListenable<WorkbenchViewData> get workbenchListenable => _workbench;
  ValueListenable<WorkbenchResourceViewData> get workbenchResourceListenable =>
      _workbenchResource;
  ValueListenable<WorkbenchCanvasViewData> get workbenchCanvasListenable =>
      _workbenchCanvas;
  ValueListenable<WorkbenchConversationViewData>
  get workbenchConversationListenable => _workbenchConversation;
  ValueListenable<WorkbenchOverlayViewData> get workbenchOverlayListenable =>
      _workbenchOverlay;
  ValueListenable<SettingsViewData> get settingsListenable => _settings;
  ValueListenable<AgentEcosystemViewData> get agentEcosystemListenable =>
      _agentEcosystem;
  ValueListenable<ProjectOpenViewData> get projectOpenListenable =>
      _projectOpen;
  ValueListenable<ProjectCollectionViewData> get projectCollectionListenable =>
      _projectCollection;
  ValueListenable<TaskCenterViewData> get taskCenterListenable => _taskCenter;
  ValueListenable<ReviewCenterViewData> get reviewCenterListenable =>
      _reviewCenter;
  ValueListenable<PromptTemplatesViewData> get promptTemplatesListenable =>
      _promptTemplates;

  void syncFrom({
    required AppShellViewModel viewModel,
    required String activeThemeId,
  }) {
    // 中文注释: 壳层细粒度监听值统一在这里同步，避免 AppShellController 到处散落 ValueNotifier 赋值逻辑。
    _destination.value = viewModel.destination;
    _activeThemeId.value = activeThemeId;
    _workbench.value = viewModel.workbench;
    _workbenchResource.value = _paneViewDataMapperService.toResourceViewData(
      viewModel.workbench,
    );
    _workbenchCanvas.value = _paneViewDataMapperService.toCanvasViewData(
      viewModel.workbench,
    );
    _workbenchConversation.value = _safeConversationViewData(
      _paneViewDataMapperService,
      viewModel.workbench,
    );
    _workbenchOverlay.value = _paneViewDataMapperService.toOverlayViewData(
      viewModel.workbench,
    );
    _settings.value = viewModel.settings;
    _agentEcosystem.value = viewModel.agentEcosystem;
    _projectOpen.value = viewModel.projectOpen;
    _projectCollection.value = viewModel.projectCollection;
    _taskCenter.value = viewModel.taskCenter;
    _reviewCenter.value = viewModel.reviewCenter;
    _promptTemplates.value = viewModel.promptTemplates;
  }

  void dispose() {
    // 中文注释: 这些监听器由壳层状态专属持有，控制器销毁时需要一起释放，避免页面级 builder 悬挂。
    _destination.dispose();
    _activeThemeId.dispose();
    _workbench.dispose();
    _workbenchResource.dispose();
    _workbenchCanvas.dispose();
    _workbenchConversation.dispose();
    _workbenchOverlay.dispose();
    _settings.dispose();
    _agentEcosystem.dispose();
    _projectOpen.dispose();
    _projectCollection.dispose();
    _taskCenter.dispose();
    _reviewCenter.dispose();
    _promptTemplates.dispose();
  }

  static WorkbenchConversationViewData _safeConversationViewData(
    WorkbenchPaneViewDataMapperService mapper,
    WorkbenchViewData workbench,
  ) {
    try {
      return mapper.toConversationViewData(workbench);
    } catch (error) {
      return WorkbenchConversationViewData(
        hasActiveProject: workbench.projectPath.trim().isNotEmpty,
        toolCoreStatus: workbench.toolCoreStatus,
        toolPreviewMode: workbench.toolPreviewMode,
        modelLabel: workbench.modelLabel,
        modelOptions: workbench.modelOptions,
        groupSelector: workbench.groupSelector,
        agentSelector: workbench.agentSelector,
        inputCapabilityContext: workbench.inputCapabilityContext.copyWith(
          isGenerating: workbench.isGenerating,
          hasActiveProject: workbench.projectPath.trim().isNotEmpty,
        ),
        contextSummary: '会话面板初始化失败，已切换为安全视图。',
        conversationContextProjection: null,
        workflowTitle: workbench.workflowTitle,
        workflowDescription: '会话投影恢复失败，请重新开始新会话或稍后再试。',
        primaryActions: workbench.primaryActions,
        openingPanel: null,
        openingState: null,
        composerHint: workbench.composerHint,
        conversationEntries: const [],
        transcriptBlocks: const [],
        transcriptLanes: const ConversationTranscriptLaneViewData(
          stableHistoryBlocks: [],
          currentRoundToolBlocks: [],
          streamingAppendixBlocks: [],
          footerBlocks: [],
        ),
        pendingOptions: const [],
        subAgentRuns: const [],
        retryRequest: null,
        sessionHistoryEntries: const [],
        activeSessionId: '',
        showSessionHistory: false,
        sessionRestoreResult: null,
        generationStatus: _fallbackConversationStatus(
          workbench.generationStatus,
          error,
        ),
        isGenerating: false,
      );
    }
  }

  static String _fallbackConversationStatus(String original, Object error) {
    final prefix = original.trim();
    final warning = '会话面板初始化失败，已降级显示：$error';
    if (prefix.isEmpty) {
      return warning;
    }
    return '$prefix\n$warning';
  }
}
