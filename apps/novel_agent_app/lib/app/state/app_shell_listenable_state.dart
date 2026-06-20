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
    final previousDestination = _destination.value;
    final nextDestination = viewModel.destination;
    final destinationChanged = previousDestination != nextDestination;
    if (destinationChanged) {
      _destination.value = nextDestination;
    }
    if (_activeThemeId.value != activeThemeId) {
      _activeThemeId.value = activeThemeId;
    }

    final previousWorkbench = _workbench.value;
    final nextWorkbench = viewModel.workbench;
    if (!identical(previousWorkbench, nextWorkbench)) {
      _workbench.value = nextWorkbench;
    }

    if (nextDestination == AppDestination.workbench) {
      _syncWorkbenchPanes(
        previousWorkbench: previousWorkbench,
        nextWorkbench: nextWorkbench,
        forceRefreshAll: destinationChanged,
      );
    }

    if (nextDestination == AppDestination.settings &&
        !identical(_settings.value, viewModel.settings)) {
      _settings.value = viewModel.settings;
    }
    if (nextDestination == AppDestination.agentEcosystem &&
        !identical(_agentEcosystem.value, viewModel.agentEcosystem)) {
      _agentEcosystem.value = viewModel.agentEcosystem;
    }
    if (nextDestination == AppDestination.projectOpen &&
        !identical(_projectOpen.value, viewModel.projectOpen)) {
      _projectOpen.value = viewModel.projectOpen;
    }
    if (nextDestination == AppDestination.taskCenter &&
        !identical(_taskCenter.value, viewModel.taskCenter)) {
      _taskCenter.value = viewModel.taskCenter;
    }
  }

  void _syncWorkbenchPanes({
    required WorkbenchViewData previousWorkbench,
    required WorkbenchViewData nextWorkbench,
    required bool forceRefreshAll,
  }) {
    if (forceRefreshAll ||
        _shouldRefreshResourcePane(previousWorkbench, nextWorkbench)) {
      final nextResource = _paneViewDataMapperService.toResourceViewData(
        nextWorkbench,
      );
      if (_workbenchResource.value != nextResource) {
        _workbenchResource.value = nextResource;
      }
    }

    if (forceRefreshAll ||
        _shouldRefreshCanvasPane(previousWorkbench, nextWorkbench)) {
      final nextCanvas = _paneViewDataMapperService.toCanvasViewData(
        nextWorkbench,
      );
      if (_workbenchCanvas.value != nextCanvas) {
        _workbenchCanvas.value = nextCanvas;
      }
    }

    if (forceRefreshAll ||
        _shouldRefreshConversationPane(previousWorkbench, nextWorkbench)) {
      final nextConversation = _safeConversationViewData(
        _paneViewDataMapperService,
        nextWorkbench,
      );
      if (_workbenchConversation.value != nextConversation) {
        _workbenchConversation.value = nextConversation;
      }
    }

    if (forceRefreshAll ||
        _shouldRefreshOverlayPane(previousWorkbench, nextWorkbench)) {
      final nextOverlay = _paneViewDataMapperService.toOverlayViewData(
        nextWorkbench,
      );
      if (_workbenchOverlay.value != nextOverlay) {
        _workbenchOverlay.value = nextOverlay;
      }
    }
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
        workflowDescription: '会话恢复失败，请重新开始新会话或稍后再试。',
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

  static bool _shouldRefreshResourcePane(
    WorkbenchViewData previous,
    WorkbenchViewData next,
  ) {
    return previous.projectName != next.projectName ||
        previous.projectSubtitle != next.projectSubtitle ||
        previous.projectTypeId != next.projectTypeId ||
        previous.projectTypeTransitionAvailability !=
            next.projectTypeTransitionAvailability ||
        !listEquals(previous.resourceEntries, next.resourceEntries) ||
        previous.informationViewData != next.informationViewData ||
        previous.projectLongTaskSummary != next.projectLongTaskSummary;
  }

  static bool _shouldRefreshCanvasPane(
    WorkbenchViewData previous,
    WorkbenchViewData next,
  ) {
    return !listEquals(previous.documents, next.documents) ||
        previous.activeDocumentTitle != next.activeDocumentTitle ||
        previous.activeDocumentPath != next.activeDocumentPath ||
        previous.activeDocumentBody != next.activeDocumentBody ||
        previous.activeDocumentDirty != next.activeDocumentDirty ||
        previous.activeDocumentBufferedDraft !=
            next.activeDocumentBufferedDraft ||
        previous.activeDocumentCanRender != next.activeDocumentCanRender ||
        previous.isActiveDocumentRendered != next.isActiveDocumentRendered ||
        previous.isDocumentsWorkspaceVisible !=
            next.isDocumentsWorkspaceVisible ||
        previous.generationStatus != next.generationStatus;
  }

  static bool _shouldRefreshConversationPane(
    WorkbenchViewData previous,
    WorkbenchViewData next,
  ) {
    return previous.projectPath != next.projectPath ||
        previous.toolCoreStatus != next.toolCoreStatus ||
        previous.toolPreviewMode != next.toolPreviewMode ||
        previous.modelLabel != next.modelLabel ||
        !listEquals(previous.modelOptions, next.modelOptions) ||
        previous.groupSelector != next.groupSelector ||
        previous.agentSelector != next.agentSelector ||
        previous.inputCapabilityContext != next.inputCapabilityContext ||
        previous.contextSummary != next.contextSummary ||
        previous.conversationContextProjection !=
            next.conversationContextProjection ||
        previous.workflowTitle != next.workflowTitle ||
        previous.workflowDescription != next.workflowDescription ||
        !listEquals(previous.primaryActions, next.primaryActions) ||
        previous.openingPanel != next.openingPanel ||
        previous.openingState != next.openingState ||
        previous.composerHint != next.composerHint ||
        !listEquals(previous.conversationEntries, next.conversationEntries) ||
        !listEquals(previous.pendingOptions, next.pendingOptions) ||
        !listEquals(previous.subAgentRuns, next.subAgentRuns) ||
        previous.retryRequest != next.retryRequest ||
        !listEquals(
          previous.sessionHistoryEntries,
          next.sessionHistoryEntries,
        ) ||
        previous.activeSessionId != next.activeSessionId ||
        previous.showSessionHistory != next.showSessionHistory ||
        previous.sessionRestoreResult != next.sessionRestoreResult ||
        previous.generationStatus != next.generationStatus ||
        previous.isGenerating != next.isGenerating;
  }

  static bool _shouldRefreshOverlayPane(
    WorkbenchViewData previous,
    WorkbenchViewData next,
  ) {
    return previous.projectLauncher != next.projectLauncher ||
        previous.projectAgentGroupWorkspace !=
            next.projectAgentGroupWorkspace ||
        previous.workspaceCommand != next.workspaceCommand;
  }
}
