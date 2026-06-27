import 'dart:async';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../../app/theme/theme_preference_resolver.dart';
import '../../../../shared/services/user_facing_error_humanizer.dart';
import '../../presentation/contracts/conversation_action_handler.dart';
import '../../presentation/models/conversation_agent_selector_view_data.dart';
import '../../presentation/models/conversation_context_projection_view_data.dart';
import '../../presentation/models/conversation_entry_view_data.dart';
import '../../presentation/models/retry_request_view_data.dart';
import '../../presentation/models/user_option_view_data.dart';
import '../../presentation/models/workbench_view_data.dart';
import '../models/conversation_request_handle.dart';
import '../models/conversation_request_agent_resolution.dart';
import '../models/conversation_retry_request.dart';
import '../models/conversation_attachment_draft.dart';
import '../models/conversation_session_state.dart';
import '../models/workbench_conversation_runtime_state.dart';
import '../models/workbench_primary_action_plan.dart';
import '../models/opening_agent_member_summary.dart';
import '../services/conversation_attachment_draft_service.dart';
import '../services/conversation_attachment_picker_service.dart';
import '../services/conversation_input_capability_service.dart';
import '../services/conversation_agent_selector_view_data_service.dart';
import '../services/conversation_request_agent_resolver_service.dart';
import '../services/desktop_conversation_attachment_picker_service.dart';
import '../services/gui_conversation_command_backend.dart';
import 'generate_draft_use_case_factory.dart';
import '../../presentation/models/conversation_group_selector_view_data.dart';
import '../services/conversation_guide_view_data_service.dart';
import '../services/conversation_group_selector_view_data_service.dart';
import '../services/conversation_opening_panel_view_data_service.dart';
import '../services/conversation_draft_autosave_policy_service.dart';
import '../services/conversation_session_context_projection_service.dart';
import '../services/project_opening_maturity_assessment_service.dart';
import '../services/project_opening_session_projection_service.dart';
import '../services/project_opening_agent_group_binding_service.dart';
import '../services/ordinary_conversation_task_profile_service.dart';
import '../services/conversation_session_preflight_service.dart';
import '../services/conversation_request_runtime_service.dart';
import '../services/conversation_session_state_service.dart';
import '../services/conversation_streaming_state_service.dart';
import '../services/conversation_tool_payload_compaction_service.dart';
import '../services/conversation_user_visible_text_service.dart';
import '../services/workbench_primary_action_service.dart';
import '../services/workbench_opening_launch_bridge_service.dart';
import 'workbench_workspace_controller.dart';
import '../models/opening_agent_group_summary.dart';
import '../models/opening_session_projection.dart';
import '../models/ordinary_conversation_task_profile.dart';

part 'conversation_attachment_facade.dart';
part 'conversation_workflow_launch_bridge.dart';
part 'conversation_opening_flow_controller.dart';

class WorkbenchConversationController implements ConversationActionHandler {
  WorkbenchConversationController({
    required SaveDraftUseCase saveDraftUseCase,
    required GenerateDraftUseCaseFactory generateDraftUseCaseFactory,
    HostAwareGenerateDraftUseCaseFactory? hostAwareGenerateDraftUseCaseFactory,
    required ModelExecutionProfileService modelExecutionProfileService,
    required ConversationSessionStateService conversationSessionStateService,
    required ProjectSessionWorkspaceService projectSessionWorkspaceService,
    required ConversationStreamingStateService
    conversationStreamingStateService,
    required ConversationGuideViewDataService conversationGuideViewDataService,
    required ConversationOpeningPanelViewDataService
    conversationOpeningPanelViewDataService,
    ProjectOpeningMaturityAssessmentService?
    projectOpeningMaturityAssessmentService,
    OrdinaryConversationTaskProfileService?
    ordinaryConversationTaskProfileService,
    required ProjectOpeningSessionProjectionService
    openingSessionProjectionService,
    required ProjectOpeningAgentGroupBindingService
    projectOpeningAgentGroupBindingService,
    required ConversationUserVisibleTextService
    conversationUserVisibleTextService,
    required WorkbenchPrimaryActionService workbenchPrimaryActionService,
    ProjectConversationDraftRuntimeService? conversationDraftRuntimeService,
    ProjectDraftExecutionConstraintRuntimeService?
    draftExecutionConstraintRuntimeService,
    ConversationRequestRuntimeService? conversationRequestRuntimeService,
    ConversationDraftAutosavePolicyService? draftAutosavePolicyService,
    ConversationAttachmentPickerService? conversationAttachmentPickerService,
    ConversationAttachmentDraftService? conversationAttachmentDraftService,
    ConversationSessionPreflightService? conversationSessionPreflightService,
    ConversationSessionContextProjectionService?
    conversationSessionContextProjectionService,
    required UserOptionPromptBuilderService userOptionPromptBuilderService,
    required LoadModeGuidanceStateUseCase loadModeGuidanceStateUseCase,
    required AnswerModeGuidanceStageUseCase answerModeGuidanceStageUseCase,
    required ModeGuidanceTransitionService modeGuidanceTransitionService,
    required WorkbenchOpeningLaunchBridgeService openingLaunchBridgeService,
    required WorkbenchWorkspaceController workspaceController,
    required WorkbenchConversationRuntimeState Function() readRuntimeState,
    required void Function(WorkbenchConversationRuntimeState state)
    writeRuntimeState,
    required WorkbenchViewData Function() readWorkbench,
    required void Function(
      WorkbenchViewData Function(WorkbenchViewData current),
    )
    mutateWorkbench,
    required AppSettings? Function() readSettings,
    required Future<void> Function(
      AppSettings nextSettings, {
      required String successMessage,
      String? selectedProviderId,
    })
    persistSettings,
    required Future<void> Function(AppSettings nextSettings)
    saveSettingsSilently,
    required void Function() refreshSettingsViewData,
    required String Function() readThemeId,
    required void Function() notifyShell,
    required Future<void> Function() showSettings,
    required JsonMap Function(AppSettings settings) contextStrategySettingsOf,
    required ProviderEndpointSettings? Function(AppSettings settings)
    selectedModelProvider,
    ProjectInformationPermissionSettingsResolverService?
    informationPermissionSettingsResolverService,
    ProjectToolPermissionSettingsResolverService?
    toolPermissionSettingsResolverService,
    required ProjectToolPermissionApprovalRecordService
    toolPermissionApprovalRecordService,
    ConversationToolPayloadCompactionService? toolPayloadCompactionService,
    ConversationAgentSelectorViewDataService?
    conversationAgentSelectorViewDataService,
    ConversationRequestAgentResolverService?
    conversationRequestAgentResolverService,
    ConversationGroupSelectorViewDataService?
    conversationGroupSelectorViewDataService,
    required void Function(String message) announce,
  }) : _generateDraftUseCaseFactory = generateDraftUseCaseFactory,
       _hostAwareGenerateDraftUseCaseFactory =
           hostAwareGenerateDraftUseCaseFactory,
       _modelExecutionProfileService = modelExecutionProfileService,
       _conversationSessionStateService = conversationSessionStateService,
       _projectSessionWorkspaceService = projectSessionWorkspaceService,
       _conversationStreamingStateService = conversationStreamingStateService,
       _conversationGuideViewDataService = conversationGuideViewDataService,
       _conversationOpeningPanelViewDataService =
           conversationOpeningPanelViewDataService,
       _projectOpeningMaturityAssessmentService =
           projectOpeningMaturityAssessmentService ??
           const ProjectOpeningMaturityAssessmentService(),
       _ordinaryConversationTaskProfileService =
           ordinaryConversationTaskProfileService ??
           const OrdinaryConversationTaskProfileService(),
       _openingSessionProjectionService = openingSessionProjectionService,
       _projectOpeningAgentGroupBindingService =
           projectOpeningAgentGroupBindingService,
       _conversationUserVisibleTextService = conversationUserVisibleTextService,
       _workbenchPrimaryActionService = workbenchPrimaryActionService,
       _conversationDraftRuntimeService = conversationDraftRuntimeService,
       _draftExecutionConstraintRuntimeService =
           draftExecutionConstraintRuntimeService,
       _conversationRequestRuntimeService =
           conversationRequestRuntimeService ??
           ConversationRequestRuntimeService(),
       _draftAutosavePolicyService =
           draftAutosavePolicyService ??
           const ConversationDraftAutosavePolicyService(),
       _conversationAttachmentPickerService =
           conversationAttachmentPickerService ??
           const DesktopConversationAttachmentPickerService(),
       _conversationAttachmentDraftService =
           conversationAttachmentDraftService ??
           const ConversationAttachmentDraftService(),
       _conversationSessionPreflightService =
           conversationSessionPreflightService ??
           ConversationSessionPreflightService(
             sessionStateService: conversationSessionStateService,
           ),
       _conversationSessionContextProjectionService =
           conversationSessionContextProjectionService ??
           ConversationSessionContextProjectionService(),
       _userOptionPromptBuilderService = userOptionPromptBuilderService,
       _loadModeGuidanceStateUseCase = loadModeGuidanceStateUseCase,
       _answerModeGuidanceStageUseCase = answerModeGuidanceStageUseCase,
       _modeGuidanceTransitionService = modeGuidanceTransitionService,
       _openingLaunchBridgeService = openingLaunchBridgeService,
       _workspaceController = workspaceController,
       _readRuntimeState = readRuntimeState,
       _writeRuntimeState = writeRuntimeState,
       _readWorkbench = readWorkbench,
       _mutateWorkbench = mutateWorkbench,
       _readSettings = readSettings,
       _persistSettings = persistSettings,
       _saveSettingsSilently = saveSettingsSilently,
       _refreshSettingsViewData = refreshSettingsViewData,
       _readThemeId = readThemeId,
       _notifyShell = notifyShell,
       _showSettings = showSettings,
       _contextStrategySettingsOf = contextStrategySettingsOf,
       _selectedModelProvider = selectedModelProvider,
       _informationPermissionSettingsResolverService =
           informationPermissionSettingsResolverService ??
           const ProjectInformationPermissionSettingsResolverService(),
       _toolPermissionSettingsResolverService =
           toolPermissionSettingsResolverService ??
           const ProjectToolPermissionSettingsResolverService(),
       _toolPermissionApprovalRecordService =
           toolPermissionApprovalRecordService,
       _toolPayloadCompactionService =
           toolPayloadCompactionService ??
           const ConversationToolPayloadCompactionService(),
       _conversationAgentSelectorViewDataService =
           conversationAgentSelectorViewDataService ??
           const ConversationAgentSelectorViewDataService(),
       _conversationRequestAgentResolverService =
           conversationRequestAgentResolverService ??
           const ConversationRequestAgentResolverService(),
       _conversationGroupSelectorViewDataService =
           conversationGroupSelectorViewDataService ??
           const ConversationGroupSelectorViewDataService(),
       _announce = announce {
    _openingFlowController = ConversationOpeningFlowController(this);
    _attachmentFacade = ConversationAttachmentFacade(this);
  }

  final GenerateDraftUseCaseFactory _generateDraftUseCaseFactory;
  final HostAwareGenerateDraftUseCaseFactory?
  _hostAwareGenerateDraftUseCaseFactory;
  final ModelExecutionProfileService _modelExecutionProfileService;
  final ConversationSessionStateService _conversationSessionStateService;
  final ProjectSessionWorkspaceService _projectSessionWorkspaceService;
  final ConversationStreamingStateService _conversationStreamingStateService;
  final ConversationGuideViewDataService _conversationGuideViewDataService;
  final ConversationOpeningPanelViewDataService
  _conversationOpeningPanelViewDataService;
  final ProjectOpeningMaturityAssessmentService
  _projectOpeningMaturityAssessmentService;
  final OrdinaryConversationTaskProfileService
  _ordinaryConversationTaskProfileService;
  final ProjectOpeningSessionProjectionService _openingSessionProjectionService;
  final ProjectOpeningAgentGroupBindingService
  _projectOpeningAgentGroupBindingService;
  final ConversationUserVisibleTextService _conversationUserVisibleTextService;
  final WorkbenchPrimaryActionService _workbenchPrimaryActionService;
  final ProjectConversationDraftRuntimeService?
  _conversationDraftRuntimeService;
  final ProjectDraftExecutionConstraintRuntimeService?
  _draftExecutionConstraintRuntimeService;
  final ConversationRequestRuntimeService _conversationRequestRuntimeService;
  final ConversationDraftAutosavePolicyService _draftAutosavePolicyService;
  final ConversationAttachmentPickerService
  _conversationAttachmentPickerService;
  final ConversationAttachmentDraftService _conversationAttachmentDraftService;
  final ConversationSessionPreflightService
  _conversationSessionPreflightService;
  final ConversationSessionContextProjectionService
  _conversationSessionContextProjectionService;
  final UserOptionPromptBuilderService _userOptionPromptBuilderService;
  final LoadModeGuidanceStateUseCase _loadModeGuidanceStateUseCase;
  final AnswerModeGuidanceStageUseCase _answerModeGuidanceStageUseCase;
  final ModeGuidanceTransitionService _modeGuidanceTransitionService;
  final WorkbenchOpeningLaunchBridgeService _openingLaunchBridgeService;
  final WorkbenchWorkspaceController _workspaceController;
  final WorkbenchConversationRuntimeState Function() _readRuntimeState;
  final void Function(WorkbenchConversationRuntimeState state)
  _writeRuntimeState;
  final WorkbenchViewData Function() _readWorkbench;
  final void Function(WorkbenchViewData Function(WorkbenchViewData current))
  _mutateWorkbench;
  final AppSettings? Function() _readSettings;
  final Future<void> Function(
    AppSettings nextSettings, {
    required String successMessage,
    String? selectedProviderId,
  })
  _persistSettings;
  final Future<void> Function(AppSettings nextSettings) _saveSettingsSilently;
  final void Function() _refreshSettingsViewData;
  final String Function() _readThemeId;
  final void Function() _notifyShell;
  final Future<void> Function() _showSettings;
  final JsonMap Function(AppSettings settings) _contextStrategySettingsOf;
  final ProviderEndpointSettings? Function(AppSettings settings)
  _selectedModelProvider;
  final ProjectInformationPermissionSettingsResolverService
  _informationPermissionSettingsResolverService;
  final ProjectToolPermissionSettingsResolverService
  _toolPermissionSettingsResolverService;
  final ProjectToolPermissionApprovalRecordService
  _toolPermissionApprovalRecordService;
  final ConversationToolPayloadCompactionService _toolPayloadCompactionService;
  final ConversationAgentSelectorViewDataService
  _conversationAgentSelectorViewDataService;
  final ConversationRequestAgentResolverService
  _conversationRequestAgentResolverService;
  final ConversationGroupSelectorViewDataService
  _conversationGroupSelectorViewDataService;
  final void Function(String message) _announce;
  final ThemePreferenceResolver _themePreferenceResolver =
      ThemePreferenceResolver();
  late final ConversationOpeningFlowController _openingFlowController;
  late final ConversationAttachmentFacade _attachmentFacade;
  ConversationRequestHandle? _activeRequestHandle;
  Future<void> _sessionPersistenceChain = Future<void>.value();

  void resetRuntimeState() {
    // 中文注释: 切换项目时会话运行时状态必须整体重置，避免旧项目会话残留继续投影到新工作区。
    _activeRequestHandle?.requestCancellation();
    _activeRequestHandle = null;
    _writeRuntimeState(const WorkbenchConversationRuntimeState());
  }

  Future<void> restoreProjectSessions(ProjectDescriptor project) async {
    // 中文注释: 项目重载时优先恢复已持久化的会话骨架，让历史列表和当前活动会话都来自项目真实记录。
    final snapshot = await _projectSessionWorkspaceService.loadSessions(
      project,
    );
    final pendingApprovalRecords = await _toolPermissionApprovalRecordService
        .listPending(
          project,
          scopeType: ProjectToolPermissionApprovalScopes.ordinaryConversation,
        );
    final pendingOptionsBySessionId = <String, List<UserOptionViewData>>{};
    for (final record in pendingApprovalRecords) {
      final sessionId = _stringValue(record['session_id']);
      if (sessionId.isEmpty) {
        continue;
      }
      final recordOptions = _conversationSessionStateService
          .pendingOptionsFromRecords(
            _toolPermissionApprovalRecordService.pendingOptionsForRecords(
              <JsonMap>[record],
            ),
          );
      pendingOptionsBySessionId
          .putIfAbsent(sessionId, () => <UserOptionViewData>[])
          .addAll(recordOptions);
    }
    final restoredSessions = snapshot.sessionRecords
        .map((record) {
          final restored = _conversationSessionStateService.restoreSession(
            record,
          );
          final pendingOptions =
              pendingOptionsBySessionId[_sessionIdOf(restored)];
          if (pendingOptions == null || pendingOptions.isEmpty) {
            return restored;
          }
          return restored.copyWith(pendingOptions: pendingOptions);
        })
        .toList(growable: false);
    final restoreResult = _conversationSessionStateService.restoreResult(
      sessions: restoredSessions,
      activeSessionId: snapshot.activeSessionId,
      showSessionHistory: restoredSessions.length > 1,
      defaultScrollTarget: restoredSessions.length > 1
          ? SessionRestoreScrollTarget.latest
          : SessionRestoreScrollTarget.latest,
    );
    _writeRuntimeState(
      _readRuntimeState().copyWith(
        sessions: restoredSessions,
        activeSessionId: snapshot.activeSessionId,
        showSessionHistory: restoreResult.showSessionHistory,
        sessionRestoreResult: restoreResult,
        guideScope: '',
      ),
    );
  }

  WorkbenchViewData applyConversationState(
    WorkbenchViewData base, {
    String? contextSummaryOverride,
  }) {
    // 中文注释: 会话视图投影统一在这里完成，避免壳层和工作区各自手拼右栏状态。
    final runtimeState = _readRuntimeState();
    final activeState = _activeConversationState();
    final runtimeProfile = _conversationRuntimeProfileFor();
    final conversationContextProjection = _exposedConversationContextProjection(
      activeState,
      runtimeProfile: runtimeProfile,
    );
    _scheduleOpeningProjectionRefresh(
      runtimeState: runtimeState,
      activeState: activeState,
    );
    final openingMaturity = _projectOpeningMaturityAssessmentService.build(
      projectType: _workspaceController.currentProject?.projectType ?? 'novel',
      resourceEntries: base.resourceEntries,
      resourceSnapshotEntries: _workspaceController
          .currentProjectRuntimeState
          .resourceSnapshotEntries,
      openingProjection: runtimeState.openingProjection,
    );
    final guide = _conversationGuideViewDataService.build(
      projectType: _workspaceController.currentProject?.projectType ?? 'novel',
      projectBranchId:
          _workspaceController.currentProject?.projectBranchId ?? '',
      needsGoalSelection: _needsGoalSelection(activeState),
      isGenerating: base.isGenerating,
      openingMaturity: openingMaturity,
      guideScope: runtimeState.guideScope,
      modeGuidanceState: runtimeState.activeModeGuidanceState,
      openingProjection: runtimeState.openingProjection,
    );
    final groupSelector = _groupSelectorViewData(
      openingProjection: runtimeState.openingProjection,
      fallback: base.groupSelector,
    );
    final agentSelector = _agentSelectorViewData(
      openingProjection: runtimeState.openingProjection,
      fallback: base.agentSelector,
    );
    return base.copyWith(
      groupSelector: groupSelector,
      agentSelector: agentSelector,
      workflowTitle: guide.workflowTitle,
      workflowDescription: guide.workflowDescription,
      composerHint: guide.composerHint,
      primaryActions: guide.primaryActions,
      openingPanel: _conversationOpeningPanelViewDataService.build(
        runtimeState.openingProjection,
        openingMaturity,
      ),
      openingState: guide.openingState,
      conversationEntries: activeState?.entries ?? const [],
      pendingOptions: activeState?.pendingOptions ?? const [],
      subAgentRuns: activeState?.subAgentRuns ?? const [],
      retryRequest: _retryRequestViewData(activeState?.retryRequest),
      sessionHistoryEntries: _conversationSessionStateService.historyEntries(
        runtimeState.sessions,
        runtimeState.activeSessionId,
      ),
      activeSessionId: runtimeState.activeSessionId,
      showSessionHistory: runtimeState.showSessionHistory,
      sessionRestoreResult: runtimeState.sessionRestoreResult,
      conversationContextProjection: conversationContextProjection,
      contextSummary:
          contextSummaryOverride ??
          _conversationSummary(activeState, fallback: base.contextSummary),
    );
  }

  WorkbenchViewData applyStreamingConversationState(
    WorkbenchViewData base, {
    required ConversationSessionState activeState,
    required String contextSummary,
    required String generationStatus,
    required String toolCoreStatus,
  }) {
    // 中文注释: 流式阶段只刷新会话相关字段，避免每个分片都重算引导、历史和其他工作台投影。
    final conversationContextProjection = _exposedConversationContextProjection(
      activeState,
      runtimeProfile: _conversationRuntimeProfileFor(),
    );
    return base.copyWith(
      conversationEntries: activeState.entries,
      pendingOptions: activeState.pendingOptions,
      subAgentRuns: activeState.subAgentRuns,
      retryRequest: _retryRequestViewData(activeState.retryRequest),
      contextSummary: contextSummary,
      conversationContextProjection: conversationContextProjection,
      generationStatus: generationStatus,
      toolCoreStatus: toolCoreStatus,
      isGenerating: true,
    );
  }

  void _scheduleOpeningProjectionRefresh({
    required WorkbenchConversationRuntimeState runtimeState,
    required ConversationSessionState? activeState,
  }) {
    // 中文注释: opening projection 缺失时异步补齐，避免同步视图投影阶段直接触发慢加载。
    if (runtimeState.isOpeningProjectionRefreshing ||
        runtimeState.openingProjection != null ||
        _workspaceController.currentProject == null) {
      return;
    }
    unawaited(
      _refreshOpeningProjection(
        activeState: activeState,
        forceReloadModeGuidance: false,
      ),
    );
  }

  Future<void> _refreshOpeningProjection({
    ConversationSessionState? activeState,
    required bool forceReloadModeGuidance,
  }) async {
    // 中文注释: 当前项目的 group 可用性与 opening 状态都统一从这里刷新，不让多个动作各自拼接局部判断。
    final project = _workspaceController.currentProject;
    if (project == null) {
      _writeRuntimeState(
        _readRuntimeState().copyWith(
          openingProjection: null,
          isOpeningProjectionRefreshing: false,
        ),
      );
      return;
    }
    final runtimeState = _readRuntimeState();
    if (runtimeState.isOpeningProjectionRefreshing) {
      return;
    }
    _writeRuntimeState(
      runtimeState.copyWith(isOpeningProjectionRefreshing: true),
    );
    try {
      // 中文注释: 开局投影决定给用户看哪些主动作（如 continue_writing），必须以磁盘
      // runtime_profile.json 为准——重读刷新缓存后再用，避免外部改动文件后投影仍按陈旧
      // baseline 演算、UI 动作与实际运行漂移（与 P0-5 创建长任务重读同一思路）。
      await _workspaceController.reloadCurrentRuntimeProfile();
      final modeGuidanceState = await _resolveOpeningModeGuidanceState(
        project,
        currentState: runtimeState.activeModeGuidanceState,
        forceReload: forceReloadModeGuidance,
      );
      final projection = await _openingSessionProjectionService.build(
        project: project,
        runtimeProfile: _workspaceController.currentProjectRuntimeProfile,
        modeGuidanceState: modeGuidanceState,
        sessionGoalModeId: _sessionGoalModeIdOf(activeState),
        freeTextIntent: _freeTextIntentOf(activeState),
      );
      _writeRuntimeState(
        _readRuntimeState().copyWith(
          activeModeGuidanceState: modeGuidanceState,
          openingProjection: projection,
          isOpeningProjectionRefreshing: false,
        ),
      );
      _mutateWorkbench((current) => applyConversationState(current));
    } catch (_) {
      _writeRuntimeState(
        _readRuntimeState().copyWith(isOpeningProjectionRefreshing: false),
      );
    }
  }

  Future<ModeGuidanceState?> _resolveOpeningModeGuidanceState(
    ProjectDescriptor project, {
    required ModeGuidanceState? currentState,
    required bool forceReload,
  }) async {
    // 中文注释: 默认开局只尝试恢复最可能的 mode guidance 状态，不在这里替代正式模式选择器。
    if (!forceReload && currentState != null) {
      return currentState;
    }
    final modeId = _likelyOpeningModeId(project);
    if (modeId.isEmpty) {
      return currentState;
    }
    final loadedState = await _loadModeGuidanceStateUseCase.execute(
      project,
      modeId: modeId,
    );
    return loadedState;
  }

  String _likelyOpeningModeId(ProjectDescriptor project) {
    final runtimeBaselineId = _workspaceController
        .currentProjectRuntimeProfile
        ?.runtimeBaselineId
        .trim();
    final effectiveRuntimeBaselineId =
        runtimeBaselineId != null && runtimeBaselineId.isNotEmpty
        ? runtimeBaselineId
        : project.runtimeBaselineId.trim();
    switch (effectiveRuntimeBaselineId) {
      case 'continuous_autonomous':
        return 'seed_autopilot_novel';
      case 'chapter_collaboration_autorun':
        return 'full_outline_consensus';
      default:
        return '';
    }
  }

  @override
  void onModelSelected(String modelId) {
    _openingFlowController.onModelSelected(modelId);
  }

  @override
  void onAgentGroupSelected(String groupId) {
    _openingFlowController.onAgentGroupSelected(groupId);
  }

  @override
  void onConversationAgentSelected(String agentId) {
    _openingFlowController.onConversationAgentSelected(agentId);
  }

  Future<void> selectProjectAgentGroup(String groupId) async {
    await _openingFlowController.selectProjectAgentGroup(groupId);
  }

  @override
  void onQuickThemeRequested() async {
    _openingFlowController.onQuickThemeRequested();
  }

  ConversationGroupSelectorViewData _groupSelectorViewData({
    required OpeningSessionProjection? openingProjection,
    required ConversationGroupSelectorViewData fallback,
  }) {
    // 中文注释: 会话栏的 group-first 选择合同统一在这里投影，避免 header、strip 和 opening 面板各自拼默认值。
    return _conversationGroupSelectorViewDataService.build(
      openingProjection: openingProjection,
      fallbackPrimaryAgentLabel: fallback.primaryAgentLabel,
    );
  }

  ConversationAgentSelectorViewData _agentSelectorViewData({
    required OpeningSessionProjection? openingProjection,
    required ConversationAgentSelectorViewData fallback,
  }) {
    // 中文注释: 当前会话智能体选择合同单独投影，避免继续借用项目级 groupSelector 承担会话级角色。
    return _conversationAgentSelectorViewDataService.build(
      openingProjection: openingProjection,
      preferredAgentId: fallback.currentAgentId,
      fallback: fallback,
    );
  }

  ConversationRequestAgentResolution _resolveRequestAgent() {
    final currentSelector = _readWorkbench().agentSelector;
    return _conversationRequestAgentResolverService.resolve(
      openingProjection: _readRuntimeState().openingProjection,
      preferredAgentId: currentSelector.currentAgentId,
      fallbackSelector: currentSelector,
    );
  }

  @override
  void onScreenModeRequested() {
    _openingFlowController.onScreenModeRequested();
  }

  @override
  void onDocumentsWorkspaceRequested() {
    _openingFlowController.onDocumentsWorkspaceRequested();
  }

  @override
  void onDocumentsWorkspaceDismissRequested() {
    _openingFlowController.onDocumentsWorkspaceDismissRequested();
  }

  @override
  void onHistoryRequested() {
    _openingFlowController.onHistoryRequested();
  }

  @override
  void onNewSessionRequested() {
    _openingFlowController.onNewSessionRequested();
  }

  @override
  void onSessionHistorySelected(String sessionId) {
    _openingFlowController.onSessionHistorySelected(sessionId);
  }

  @override
  Future<void> onUserOptionSelected(UserOptionViewData option) async {
    // 中文注释: 选项点击统一转成补充提示，再复用同一条发送链继续推进。
    HostToolPermissionContext? hostToolPermissionContextOverride;
    final project = _workspaceController.currentProject;
    if (project != null &&
        option.permissionApprovalId.trim().isNotEmpty &&
        option.permissionApprovalOptionId.trim().isNotEmpty) {
      final resolved = await _toolPermissionApprovalRecordService
          .resolveSelection(
            project,
            approvalId: option.permissionApprovalId,
            optionId: option.permissionApprovalOptionId,
          );
      if (!ValueReaders.boolValue(resolved['ok'])) {
        _announce(_stringValue(resolved['error'], '当前权限确认无法继续处理。'));
        return;
      }
      final consumed = await _toolPermissionApprovalRecordService
          .consumeResolvedOverrideContext(
            project,
            approvalId: option.permissionApprovalId,
          );
      final contextJson = ValueReaders.mapValue(
        consumed['host_tool_permission_context'],
      );
      if (contextJson.isNotEmpty) {
        hostToolPermissionContextOverride = HostToolPermissionContext.fromJson(
          contextJson,
        );
      }
    }
    final prompt = _userOptionPromptBuilderService.build(<String, Object?>{
      'label': option.label,
      'description': option.description,
      'prompt': option.prompt,
      '_source_question': option.sourceQuestion,
      '_all_options': option.allOptions,
    });
    await _sendPrompt(
      prompt,
      visibleText: _conversationUserVisibleTextService.textForUserOption(
        option,
      ),
      hostToolPermissionContextOverride: hostToolPermissionContextOverride,
    );
  }

  @override
  void onConversationSettingsRequested() {
    _openingFlowController.onConversationSettingsRequested();
  }

  @override
  Future<void> onPrimaryActionRequested(String actionId) async {
    await _openingFlowController.onPrimaryActionRequested(actionId);
  }

  Future<bool> _handleDeterministicLongTaskPrimaryAction(
    PrimaryActionViewData action,
  ) async {
    switch (action.commandId.trim()) {
      case 'long_task.run_next':
        _announce('当前长任务运行入口已收口到共享桥，请通过 opening.launch_long_task 进入。');
        return true;
      case 'long_task.run_controlled':
        _announce('当前长任务运行入口已收口到共享桥，请通过 opening.launch_long_task 进入。');
        return true;
      case 'long_task.open_detail':
        _workspaceController.onLongTaskStationRequested();
        return true;
      default:
        return false;
    }
  }

  @override
  Future<void> onRetryLastFailedRequested() async {
    // TODO: route through runtime controller in next slice.
    final retryRequest = _activeConversationState()?.retryRequest;
    if (retryRequest == null) {
      _announce('当前没有可重试的失败请求。');
      return;
    }
    await _sendPrompt(
      retryRequest.prompt,
      visibleText: retryRequest.visibleText,
      retryLastFailure: true,
    );
  }

  @override
  void onOptimizeRequested() {
    // 中文注释: 提示词优化尚未独立成链，这里只给出明确的当前能力引导，不制造空按钮。
    _announce('直接发送自然语言需求即可；需要优化时可以在当前会话里继续调整。');
  }

  @override
  Future<void> onToolOptionsRequested() async {
    // 中文注释: 工具选项当前复用设置页入口，后续独立工具面板再接到同一壳层导航。
    await _showSettings();
    _announce('已打开设置页，可继续调整工具策略与权限。');
  }

  @override
  void onReasoningToggleChanged(bool enabled) {
    // 中文注释: 会话区 reasoning 开关直接写回共享模型设置，保证设置页、工作台和后续 CLI 看到的是同一事实源。
    final settings = _readSettings();
    if (settings == null) {
      return;
    }
    final updated = settings.copyWith(
      extraSettings: <String, Object?>{
        ...settings.extraSettings,
        'model_settings': <String, Object?>{
          ..._modelSettingsOf(settings),
          'thinking_enabled': enabled,
        },
      },
    );
    _persistSettings(
      updated,
      successMessage: enabled ? '已开启深度思考。' : '已关闭深度思考。',
    );
  }

  @override
  void onStopRequested() {
    // 中文注释: 当前轮只记录停止意图并挂到正式句柄上，真实中断留给后续链路接通。
    final requestHandle = _activeRequestHandle;
    if (!_readWorkbench().isGenerating || requestHandle == null) {
      _announce('当前没有正在生成的请求。');
      return;
    }
    final didRequestCancellation = requestHandle.requestCancellation();
    if (!didRequestCancellation) {
      _announce('当前请求已经进入收尾阶段。');
      return;
    }
    _mutateWorkbench(
      (current) => applyConversationState(
        current.copyWith(
          generationStatus: '正在停止当前生成...',
          toolCoreStatus: '正在等待当前流式步骤结束。',
        ),
      ),
    );
    _announce('已记录停止请求，正在等待当前步骤结束。');
  }

  @override
  void onAttachmentRequested() async {
    await _attachmentFacade.onAttachmentRequested();
  }

  @override
  Future<void> onSendRequested(String text) async {
    // 中文注释: 斜杠指令优先拦截并交由 core 命令分发器处理；普通文本才走正式发送链。
    final trimmed = text.trim();
    if (trimmed.startsWith('/')) {
      await _handleConversationCommand(trimmed);
      return;
    }
    await _sendPrompt(text);
  }

  late final GuiConversationCommandBackend _guiConversationBackend =
      GuiConversationCommandBackend();

  late final ConversationCommandDispatcher _conversationCommandDispatcher =
      _buildConversationDispatcher();

  ConversationCommandDispatcher _buildConversationDispatcher() {
    // 中文注释: GUI 只注册用户第一期选定的内置指令（不含 /exit）；contextFactory 闭包每次调用
    // 读取当前 project 与活跃会话记录，保证多轮对话中读到最新状态。
    final registry = ConversationCommandRegistry();
    registerBuiltinConversationCommands(registry);
    return ConversationCommandDispatcher(
      registry: registry,
      contextFactory: (rawArgs) => ConversationCommandContext(
        project:
            _workspaceController.currentProject ??
            const ProjectDescriptor(id: '', name: '', rootPath: ''),
        sessionRecord:
            _activeConversationState()?.sessionRecord ??
            const <String, Object?>{},
        rawArgs: rawArgs,
        backend: _guiConversationBackend,
      ),
    );
  }

  Future<void> _handleConversationCommand(String input) async {
    // 中文注释: 命令结果只回写会话状态并 announce；不进入模型生成链。passThrough 兜底走发送。
    final project = _workspaceController.currentProject;
    final activeState = _activeConversationState();
    if (project == null || activeState == null) {
      _announce('请先开始会话后再使用指令。');
      return;
    }
    final result = await _conversationCommandDispatcher.dispatch(input);
    if (result.kind == ConversationCommandOutcomeKind.passThrough) {
      await _sendPrompt(input);
      return;
    }
    if (result.shouldRender) {
      _announce(result.message);
    }
    if (result.updatedSessionRecord != null) {
      final nextState = activeState.copyWith(
        sessionRecord: result.updatedSessionRecord!,
      );
      _replaceConversationSession(
        nextState,
        activate: true,
        persist: result.persist,
      );
    }
  }

  Future<void> _sendPrompt(
    String text, {
    String visibleText = '',
    bool retryLastFailure = false,
    HostToolPermissionContext? hostToolPermissionContextOverride,
  }) async {
    // 中文注释: 真实发送链在这里收口，统一处理会话状态、上下文渲染、生成和结果回放。
    final cleanText = text.trim();
    if (cleanText.isEmpty) {
      _announce('请输入创作需求后再发送。');
      return;
    }
    final runtimeState = _readRuntimeState();
    if (runtimeState.guideScope == 'mode_guidance' &&
        runtimeState.activeModeGuidanceState != null &&
        !runtimeState.activeModeGuidanceState!.isReady) {
      final question = _modeGuidanceTransitionService.buildQuestion(
        runtimeState.activeModeGuidanceState!,
      );
      if (!question.allowFreeText) {
        _announce('当前阶段请先从下方选项里选择一个方向。');
        return;
      }
      await _answerModeGuidanceWithFreeText(
        text: cleanText,
        visibleText: visibleText,
        question: question,
      );
      return;
    }
    final settings = _readSettings();
    final project = _workspaceController.currentProject;
    if (settings == null || project == null) {
      _announce('默认项目尚未加载完成，请稍后再试。');
      return;
    }
    final provider = _selectedModelProvider(settings);
    if (provider == null) {
      _announce('当前没有可用 provider 配置。');
      return;
    }
    final requestAgent = _resolveRequestAgent();
    final executionProfile = _modelExecutionProfileService.resolve(
      settings: settings,
      provider: provider,
      agent: requestAgent.agent,
    );
    final runtimeProfile = _mapValue(executionProfile['runtime_profile']);
    final contextStrategySettings = _contextStrategySettingsOf(settings);
    final resolvedModelId = _stringValue(
      executionProfile['resolved_model_id'],
      settings.defaultModelId,
    );
    if (provider.baseUrl.trim().isEmpty || resolvedModelId.trim().isEmpty) {
      _announce('请先在 novel_agent_settings.json 或环境变量里配置真实的模型接口地址和模型名。');
      return;
    }
    final title = _titleFromPrompt(cleanText);
    final wasModeGuidanceActive =
        _readRuntimeState().activeModeGuidanceState != null;
    final activeState = _ensureConversationSession();
    final userPromptState = retryLastFailure
        ? _conversationSessionStateService.stateAfterRetryCleanup(activeState)
        : _conversationSessionStateService.stateWithUserPrompt(
            activeState,
            cleanText,
            displayContent: visibleText,
            strategySettings: contextStrategySettings,
            modelProfile: runtimeProfile,
          );
    final preflight = _conversationSessionPreflightService.prepareForSend(
      state: userPromptState,
      runtimeProfile: runtimeProfile,
      excludeLatestUserContent: cleanText,
      retryLastFailure: retryLastFailure,
    );
    _replaceConversationSession(preflight.sessionState, activate: true);
    unawaited(
      _refreshOpeningProjection(
        activeState: preflight.sessionState,
        forceReloadModeGuidance: false,
      ),
    );
    _writeRuntimeState(
      _readRuntimeState().copyWith(showSessionHistory: false, guideScope: ''),
    );
    _mutateWorkbench(
      (current) => applyConversationState(
        current.copyWith(
          isGenerating: true,
          generationStatus: '正在请求 ${provider.title} 生成内容...',
          toolCoreStatus: '',
        ),
        contextSummaryOverride: _conversationSummary(
          preflight.sessionState,
          fallback: '正在整理会话与项目上下文',
        ),
      ),
    );
    final sessionPromptContext = preflight.sessionPromptContext;
    final streamingContextSummary = _conversationSummary(
      preflight.sessionState,
      fallback: '正在接收模型输出',
    );
    var streamingBaseState = preflight.sessionState;
    ProjectConversationDraftRuntimePreparation? conversationDraftRuntime;
    final taskProfile = _ordinaryConversationTaskProfile(
      agent: requestAgent.agent,
      userPrompt: cleanText,
    );
    late final ConversationRequestHandle requestHandle;
    try {
      requestHandle = _conversationRequestRuntimeService.start(
        onProgress: (progress) {
          if (!_isActiveRequestHandle(requestHandle)) {
            return;
          }
          final uiProgress = _toolPayloadCompactionService.compactProgress(
            progress,
          );
          final streamingState = _conversationStreamingStateService
              .stateWithProgress(streamingBaseState, uiProgress);
          streamingBaseState = streamingState;
          _replaceConversationSession(
            streamingState,
            activate: true,
            persist: false,
          );
          _mutateWorkbench(
            (current) => applyStreamingConversationState(
              current,
              activeState: streamingState,
              contextSummary: streamingContextSummary,
              generationStatus: _streamingGenerationStatus(
                provider,
                uiProgress,
              ),
              toolCoreStatus: _streamingToolStatus(uiProgress),
            ),
          );
        },
        execute: ({required onProgress, required cancellationToken}) async {
          final coreCancellationToken = DraftGenerationCancellationToken();
          void syncCancellation() {
            coreCancellationToken.cancel();
          }

          cancellationToken.addListener(syncCancellation);
          final selectedCollaborationGroup =
              _selectedCollaborationGroupForRuntime(
                _readRuntimeState().openingProjection,
              );
          conversationDraftRuntime = await _prepareConversationDraftRuntime(
            project: project,
            agent: requestAgent.agent,
            taskProfile: taskProfile,
            chapterLabelHint: cleanText,
            selectedCollaborationGroup: selectedCollaborationGroup,
          );
          final executionConstraints = conversationDraftRuntime != null
              ? conversationDraftRuntime!.executionConstraints
              : await _resolveExecutionConstraintsFallback(
                  project: project,
                  agent: requestAgent.agent,
                  taskProfile: taskProfile,
                );
          final hostInformationPermissionContext =
              _hostInformationPermissionContext(settings);
          final hostToolPermissionContext =
              hostToolPermissionContextOverride ??
              _hostToolPermissionContext(settings);
          final useCase =
              _hostAwareGenerateDraftUseCaseFactory?.call(
                provider,
                settings.networkSettings,
                hostInformationPermissionContext:
                    hostInformationPermissionContext,
                hostToolPermissionContext: hostToolPermissionContext,
              ) ??
              _generateDraftUseCaseFactory(provider, settings.networkSettings);
          try {
            final mergedSessionPromptContext = sessionPromptContext.copyWith(
              contextMarkdown: _mergeSessionContext(
                sessionPromptContext.contextMarkdown,
                conversationDraftRuntime?.sessionContextMarkdown ?? '',
              ),
            );
            return useCase.execute(
              project: project,
              userPrompt: cleanText,
              modelId: resolvedModelId,
              title: title,
              intent: taskProfile.intent,
              conversationGoal: _stringValue(
                preflight.sessionState.sessionRecord[SessionRecordConstants.conversationGoalField],
              ),
              agent: requestAgent.agent,
              selectedCollaborationGroup: selectedCollaborationGroup,
              sessionContext: mergedSessionPromptContext.contextMarkdown,
              sessionPromptContext: mergedSessionPromptContext,
              requestOptions: _mapValue(executionProfile['request_options']),
              contextSettings: contextStrategySettings,
              modelProfile: runtimeProfile,
              exposedToolIds:
                  conversationDraftRuntime?.exposedToolIds ?? const <String>[],
              expressionConstraintProfiles: ValueReaders.objectList(
                executionConstraints['expression_constraint_profiles'],
              ),
              projectExpressionConstraintBindings: ValueReaders.objectList(
                executionConstraints['project_expression_constraint_bindings'],
              ),
              writingExecutionConstraints: executionConstraints,
              activeDocumentPath: _workspaceController.activeDocumentPath,
              activeDocumentBody: _workspaceController.activeDocumentBody,
              cancellationToken: coreCancellationToken,
              onProgress: onProgress,
            );
          } finally {
            cancellationToken.removeListener(syncCancellation);
          }
        },
      );
      _activeRequestHandle = requestHandle;
      final result = await requestHandle.completion;
      if (!_isActiveRequestHandle(requestHandle)) {
        return;
      }
      await _applyRequestSuccess(
        handle: requestHandle,
        result: result,
        project: project,
        settings: settings,
        title: title,
        wasModeGuidanceActive: wasModeGuidanceActive,
        streamingBaseState: streamingBaseState,
        contextStrategySettings: contextStrategySettings,
        runtimeProfile: runtimeProfile,
        providerTitle: provider.title,
        conversationDraftRuntime: conversationDraftRuntime,
      );
    } catch (error) {
      if (!_isActiveRequestHandle(requestHandle)) {
        return;
      }
      _applyRequestFailure(
        error: error,
        userPromptState: preflight.sessionState,
        cleanText: cleanText,
        visibleText: visibleText,
        contextStrategySettings: contextStrategySettings,
        runtimeProfile: runtimeProfile,
      );
    } finally {
      if (identical(_activeRequestHandle, requestHandle)) {
        _activeRequestHandle = null;
      }
    }
  }

  Future<JsonMap> _resolveExecutionConstraintsFallback({
    required ProjectDescriptor project,
    required JsonMap agent,
    required OrdinaryConversationTaskProfile taskProfile,
  }) async {
    if (_draftExecutionConstraintRuntimeService == null) {
      return const <String, Object?>{};
    }
    return _draftExecutionConstraintRuntimeService.resolve(
      project,
      appliesTo: switch (taskProfile.taskType) {
        'revision' => ConstraintBindingAppliesTo.repair,
        'review' => ConstraintBindingAppliesTo.review,
        'planning' => ConstraintBindingAppliesTo.explanation,
        _ => ConstraintBindingAppliesTo.writing,
      },
      agentId: ValueReaders.stringValue(agent['id']),
      stageId: switch (taskProfile.taskType) {
        'revision' => 'revision',
        'review' => 'review',
        'planning' => 'planning',
        _ => 'draft',
      },
      intent: switch (taskProfile.taskType) {
        'revision' => 'revision',
        'review' => 'review',
        'planning' => 'planning',
        _ => 'draft',
      },
      taskType: taskProfile.taskType,
    );
  }

  Future<ProjectConversationDraftRuntimePreparation?>
  _prepareConversationDraftRuntime({
    required ProjectDescriptor project,
    required JsonMap agent,
    required OrdinaryConversationTaskProfile taskProfile,
    required String chapterLabelHint,
    required JsonMap selectedCollaborationGroup,
  }) async {
    if (_conversationDraftRuntimeService == null) {
      return null;
    }
    return _conversationDraftRuntimeService.prepareDraftRun(
      project,
      taskType: taskProfile.taskType,
      chapterLabelHint: chapterLabelHint,
      activeDocumentPath: _workspaceController.activeDocumentPath,
      agentId: ValueReaders.stringValue(agent['id']),
      selectedCollaborationGroup: selectedCollaborationGroup,
      pinnedRelativePaths:
          _workspaceController.activeDocumentPath.trim().isEmpty
          ? const <String>[]
          : <String>[_workspaceController.activeDocumentPath],
    );
  }

  Future<ProjectConversationDraftRuntimeArtifacts>
  _finalizeConversationDraftRuntime({
    required ProjectDescriptor project,
    required DraftGenerationResult result,
    required String title,
    required String savedPath,
    required ProjectConversationDraftRuntimePreparation? preparation,
  }) async {
    if (_conversationDraftRuntimeService == null || preparation == null) {
      return const ProjectConversationDraftRuntimeArtifacts();
    }
    return _conversationDraftRuntimeService.finalizeDraftRun(
      project: project,
      preparation: preparation,
      result: result,
      title: title,
      fallbackSavedPath: savedPath,
    );
  }

  String _mergeSessionContext(String base, String extra) {
    final parts = <String>[];
    final cleanBase = base.trim();
    final cleanExtra = extra.trim();
    if (cleanBase.isNotEmpty) {
      parts.add(cleanBase);
    }
    if (cleanExtra.isNotEmpty) {
      parts.add(cleanExtra);
    }
    return parts.join('\n\n');
  }

  HostInformationPermissionContext _hostInformationPermissionContext(
    AppSettings settings,
  ) {
    return _informationPermissionSettingsResolverService.resolveFromAppSettings(
      settings,
      source: 'workbench_conversation_controller',
    );
  }

  HostToolPermissionContext _hostToolPermissionContext(AppSettings settings) {
    return _toolPermissionSettingsResolverService.resolveFromAppSettings(
      settings,
      source: 'workbench_conversation_controller',
    );
  }

  OrdinaryConversationTaskProfile _ordinaryConversationTaskProfile({
    required JsonMap agent,
    required String userPrompt,
  }) {
    final openingMaturity = _projectOpeningMaturityAssessmentService.build(
      projectType: _workspaceController.currentProject?.projectType ?? 'novel',
      resourceEntries: _readWorkbench().resourceEntries,
      resourceSnapshotEntries: _workspaceController
          .currentProjectRuntimeState
          .resourceSnapshotEntries,
      openingProjection: _readRuntimeState().openingProjection,
    );
    return _ordinaryConversationTaskProfileService.resolve(
      agent: agent,
      openingMaturity: openingMaturity,
      userPrompt: userPrompt,
      activeDocumentPath: _workspaceController.activeDocumentPath,
    );
  }

  Future<bool> _handleGuideNavigationAction(
    PrimaryActionViewData action,
  ) async {
    // 中文注释: 工作流细分页导航只切换引导状态，不直接触发模型调用。
    final runtimeState = _readRuntimeState();
    switch (action.commandId.trim()) {
      case 'opening.launch_long_task':
        final project = _workspaceController.currentProject;
        if (project == null) {
          _announce('请先创建或打开长篇项目。');
          return true;
        }
        final projection = runtimeState.openingProjection;
        final projectType = projection?.projectTypeId.trim().isNotEmpty == true
            ? projection!.projectTypeId.trim()
            : project.projectType.trim();
        if (projectType != 'long_novel') {
          _announce('只有长任务相关项目才会显示这个入口。');
          return true;
        }
        // 中文注释: 先消费开局投影里由正式开局合同派生的建议动作；能委派就委派
        // （就绪 -> start_long_task_run，未就绪 -> choose_long_task_mode），
        // 只有在没有可委派建议时才落到 agent-led 启动提示词，避免开局已就绪却只发一句话。
        final suggestedAction = _openingLaunchBridgeService
            .resolveLongTaskLaunchTarget(projection);
        if (suggestedAction != null &&
            suggestedAction.commandId.trim() != 'opening.launch_long_task') {
          final delegated = await _handleGuideNavigationAction(suggestedAction);
          if (delegated) {
            return true;
          }
        }
        final prompt = _openingLaunchBridgeService.buildLongTaskEntryPrompt(
          project: project,
          projection: projection,
          activeDocumentPath: _workspaceController.activeDocumentPath,
          activeDocumentExcerpt: _workspaceController.activeDocumentBody,
        );
        await _sendPrompt(prompt, visibleText: '启动长任务');
        return true;
      case 'guide.open_long_task_modes':
        _writeRuntimeState(
          runtimeState.copyWith(
            guideScope: 'long_task_modes',
            activeModeGuidanceState: null,
            showSessionHistory: false,
          ),
        );
        _mutateWorkbench((current) => applyConversationState(current));
        unawaited(
          _refreshOpeningProjection(
            activeState: _activeConversationState(),
            forceReloadModeGuidance: false,
          ),
        );
        return true;
      case 'workspace.open_import_command':
      case 'guide.open_book_deconstruction_workbench':
        _workspaceController.onImportRequested();
        return true;
      case 'guide.open_book_deconstruction_analysis':
        _workspaceController.onProjectAssetsRequested();
        return true;
      case 'guide.open_project_assets_rag':
        _workspaceController.onProjectAssetsRequested();
        return true;
      case 'guide.open_mode_guidance':
      case 'opening.open_mode_guidance':
      case 'opening.continue_mode_guidance':
        final project = _workspaceController.currentProject;
        if (project == null) {
          _announce('请先创建或打开长篇项目。');
          return true;
        }
        final modeId = _stringValue(
          action.payload['mode'] ?? action.payload['mode_id'],
          'seed_autopilot_novel',
        );
        final state = await _loadModeGuidanceStateUseCase.execute(
          project,
          modeId: modeId,
        );
        _writeRuntimeState(
          runtimeState.copyWith(
            guideScope: 'mode_guidance',
            activeModeGuidanceState: state,
            showSessionHistory: false,
          ),
        );
        _mutateWorkbench((current) => applyConversationState(current));
        unawaited(
          _refreshOpeningProjection(
            activeState: _activeConversationState(),
            forceReloadModeGuidance: false,
          ),
        );
        return true;
      case 'guide.answer_mode_guidance':
        final project = _workspaceController.currentProject;
        if (project == null) {
          _announce('请先创建或打开长篇项目。');
          return true;
        }
        final modeId = _stringValue(
          action.payload['mode'],
          'seed_autopilot_novel',
        );
        final stageId = _stringValue(action.payload['stage_id']);
        final fieldKey = _stringValue(action.payload['field_key']);
        final value = _stringValue(action.payload['value']);
        if (stageId.isEmpty || fieldKey.isEmpty || value.isEmpty) {
          _announce('当前引导动作缺少必要参数。');
          return true;
        }
        final state = await _answerModeGuidanceStageUseCase.execute(
          project,
          modeId: modeId,
          stageId: stageId,
          fieldKey: fieldKey,
          value: value,
          label: _stringValue(action.payload['label']),
          source: _stringValue(action.payload['source'], 'option'),
        );
        _writeRuntimeState(
          runtimeState.copyWith(
            guideScope: 'mode_guidance',
            activeModeGuidanceState: state,
            showSessionHistory: false,
          ),
        );
        _mutateWorkbench((current) => applyConversationState(current));
        unawaited(
          _refreshOpeningProjection(
            activeState: _activeConversationState(),
            forceReloadModeGuidance: false,
          ),
        );
        return true;
      case 'guide.create_workflow_from_mode_guidance':
      case 'opening.start_long_task_run':
        final project = _workspaceController.currentProject;
        if (project == null) {
          _announce('请先创建或打开长篇项目。');
          return true;
        }
        if (action.commandId.trim() == 'opening.start_long_task_run') {
          await _startLongTaskRunFromOpening(action);
          return true;
        }
        final modeId = _stringValue(
          action.payload['mode'],
          'seed_autopilot_novel',
        );
        final result = await _openingLaunchBridgeService
            .createWorkflowFromModeGuidance(project, modeId: modeId);
        _announce(_resultMessage(result, success: '长任务队列已根据模式引导生成。'));
        return true;
      case 'opening.choose_long_task_mode':
        _writeRuntimeState(
          runtimeState.copyWith(
            guideScope: 'long_task_modes',
            showSessionHistory: false,
          ),
        );
        _mutateWorkbench((current) => applyConversationState(current));
        return true;
      case 'opening.choose_agent_group':
        _announce('请先在开局面板里选择当前项目要使用的智能体组。');
        return true;
      case 'opening.choose_runtime_baseline':
        _announce('当前项目还没有确定运行基准，请先回到项目创建或运行配置入口补齐。');
        return true;
      case 'opening.start_interactive_session':
        _announce('当前信息已足够，直接在输入框里继续描述需求即可。');
        return true;
      case 'opening.choose_session_goal':
        _announce('先从下面的普通协作入口里选一个目标，或直接输入一句你当前想做什么。');
        return true;
      case 'opening.provide_free_text_intent':
        _announce('直接在输入框里说明这次想让智能体做什么即可。');
        return true;
      case 'guide.back.default':
        _writeRuntimeState(
          runtimeState.copyWith(guideScope: '', showSessionHistory: false),
        );
        _mutateWorkbench((current) => applyConversationState(current));
        unawaited(
          _refreshOpeningProjection(
            activeState: _activeConversationState(),
            forceReloadModeGuidance: false,
          ),
        );
        return true;
      default:
        return false;
    }
  }

  Future<void> _answerModeGuidanceWithFreeText({
    required String text,
    required String visibleText,
    required ModeGuidanceQuestion question,
  }) async {
    // 中文注释: 模式引导自由输入只回写当前阶段答案，不额外走模型。
    final project = _workspaceController.currentProject;
    if (project == null) {
      _announce('请先创建或打开长篇项目。');
      return;
    }
    final state = await _answerModeGuidanceStageUseCase.execute(
      project,
      modeId: question.modeId,
      stageId: question.stageId,
      fieldKey: question.fieldKey,
      value: text,
      label: visibleText.trim(),
      source: 'free_text',
    );
    _writeRuntimeState(
      _readRuntimeState().copyWith(
        guideScope: 'mode_guidance',
        activeModeGuidanceState: state,
        showSessionHistory: false,
      ),
    );
    _mutateWorkbench((current) => applyConversationState(current));
    await _refreshOpeningProjection(
      activeState: _activeConversationState(),
      forceReloadModeGuidance: false,
    );
  }

  Future<void> _startLongTaskRunFromOpening(
    PrimaryActionViewData action,
  ) async {
    // 中文注释: opening 阶段的正式启动动作统一交给共享桥，这里只负责触发和投影刷新。
    final project = _workspaceController.currentProject;
    if (project == null) {
      _announce('请先创建或打开长篇项目。');
      return;
    }
    _mutateWorkbench(
      (current) => applyConversationState(
        current.copyWith(
          generationStatus: '正在根据当前开局状态启动长任务...',
          toolCoreStatus: '',
        ),
      ),
    );
    try {
      final settings = _readSettings();
      if (settings == null) {
        _announce('尚未读取到应用设置，无法启动长任务。');
        return;
      }
      // 中文注释: opening 正式启动走"先确保 workflow 就位再统一进入受控队列运行"的桥入口，
      // 这样开局即进入真正的队列执行，而不是只生成任务链就停下。
      final result = await _openingLaunchBridgeService.startLongTaskRun(
        project,
        settings,
        arguments: ValueReaders.deepCopyMap(action.payload),
      );
      if (!ValueReaders.boolValue(result['ok'], true)) {
        _announce(_resultMessage(result, success: '启动长任务失败。'));
        return;
      }
      _workspaceController.onRefreshFilesRequested();
      await _workspaceController.refreshProjectLongTaskSummary();
      _announce(_resultMessage(result, success: '已生成长任务链。'));
    } catch (error) {
      _announce('启动长任务失败：$error');
    } finally {
      await _refreshOpeningProjection(
        activeState: _activeConversationState(),
        forceReloadModeGuidance: false,
      );
      _mutateWorkbench((current) => applyConversationState(current));
    }
  }

  Future<void> _selectOpeningAgentGroup(String groupId) async {
    // 中文注释: 组切换后需要立刻持久化并刷新 opening projection，这样空态提示和后续动作会一起收束到新组。
    final project = _workspaceController.currentProject;
    final projection = _readRuntimeState().openingProjection;
    final cleanGroupId = groupId.trim();
    if (project == null || projection == null || cleanGroupId.isEmpty) {
      return;
    }
    var selectedSummary = projection.supportedGroups.isEmpty
        ? null
        : projection.supportedGroups.first;
    for (final summary in projection.supportedGroups) {
      if (summary.groupId == cleanGroupId) {
        selectedSummary = summary;
        break;
      }
    }
    if (selectedSummary?.groupId != cleanGroupId) {
      selectedSummary = null;
    }
    if (selectedSummary == null) {
      _announce('当前项目暂不支持所选智能体组。');
      return;
    }
    await _projectOpeningAgentGroupBindingService.selectProjectDefaultGroup(
      project: project,
      groupId: selectedSummary.groupId,
      displayName: selectedSummary.displayName,
    );
    await _refreshOpeningProjection(
      activeState: _activeConversationState(),
      forceReloadModeGuidance: false,
    );
    _mutateWorkbench((current) => applyConversationState(current));
    _announce('已切换项目智能体组：${selectedSummary.displayName}');
  }

  Future<void> _startPrimaryActionPrompt(
    WorkbenchPrimaryActionPlan plan, {
    String userVisibleText = '',
  }) async {
    // 中文注释: 主动作若要发起真实提示词链，会先写入目标模式，再复用统一发送入口。
    final activeState = _ensureConversationSession();
    if (plan.sessionMode.trim().isNotEmpty) {
      final nextState = _conversationSessionStateService.stateWithGoalSelection(
        activeState,
        plan.sessionMode,
      );
      _replaceConversationSession(nextState, activate: true);
      unawaited(
        _refreshOpeningProjection(
          activeState: nextState,
          forceReloadModeGuidance: false,
        ),
      );
    }
    if (plan.message.trim().isNotEmpty) {
      _mutateWorkbench(
        (current) => applyConversationState(
          current.copyWith(generationStatus: plan.message),
        ),
      );
    }
    await _sendPrompt(plan.prompt, visibleText: userVisibleText);
  }

  ConversationSessionState _createConversationSession() {
    return _conversationSessionStateService.createSession(
      sessionId: 'session_${DateTime.now().microsecondsSinceEpoch}',
    );
  }

  ConversationSessionState _ensureConversationSession() {
    final activeState = _activeConversationState();
    if (activeState != null) {
      return activeState;
    }
    final session = _createConversationSession();
    _replaceConversationSession(session, activate: true);
    return session;
  }

  ConversationSessionState? _activeConversationState() {
    final runtimeState = _readRuntimeState();
    for (final state in runtimeState.sessions) {
      if (_sessionIdOf(state) == runtimeState.activeSessionId) {
        return state;
      }
    }
    return runtimeState.sessions.isEmpty ? null : runtimeState.sessions.last;
  }

  void _replaceConversationSession(
    ConversationSessionState state, {
    bool activate = false,
    bool persist = true,
  }) {
    final runtimeState = _readRuntimeState();
    final sessionId = _sessionIdOf(state);
    final next = <ConversationSessionState>[];
    var replaced = false;
    for (final current in runtimeState.sessions) {
      if (_sessionIdOf(current) == sessionId) {
        next.add(state);
        replaced = true;
      } else {
        next.add(current);
      }
    }
    if (!replaced) {
      next.add(state);
    }
    _writeRuntimeState(
      runtimeState.copyWith(
        sessions: next,
        activeSessionId: activate || runtimeState.activeSessionId.trim().isEmpty
            ? sessionId
            : runtimeState.activeSessionId,
      ),
    );
    if (persist) {
      _scheduleSessionPersistence();
    }
  }

  String _sessionIdOf(ConversationSessionState state) {
    final id = _stringValue(state.sessionRecord['session_id']).trim();
    if (id.isNotEmpty) {
      return id;
    }
    return _stringValue(state.sessionRecord['id']);
  }

  void _scheduleSessionPersistence() {
    final project = _workspaceController.currentProject;
    if (project == null) {
      return;
    }
    final runtimeState = _readRuntimeState();
    final sessionRecords = runtimeState.sessions
        .map((state) => ValueReaders.deepCopyMap(state.sessionRecord))
        .toList(growable: false);
    final activeSessionId = runtimeState.activeSessionId.trim();
    _sessionPersistenceChain = _sessionPersistenceChain
        .catchError((_) {})
        .then(
          (_) => _projectSessionWorkspaceService.saveSessions(
            project,
            sessionRecords: sessionRecords,
            activeSessionId: activeSessionId,
          ),
        )
        .catchError((error, _) {
          _announce('会话历史保存失败：$error');
        });
  }

  JsonMap _selectedCollaborationGroupForRuntime(
    OpeningSessionProjection? projection,
  ) {
    // 中文注释: 会话运行只消费 application service 投影出的当前组快照，不在 widget 或底层工具里重新猜组。
    if (projection == null) {
      return const <String, Object?>{};
    }
    for (final summary in projection.supportedGroups) {
      if (summary.groupId != projection.currentGroupId.trim()) {
        continue;
      }
      return _openingGroupSummaryToDocument(
        projection,
        summary: summary,
        fallbackPrimaryAgentId: projection.currentPrimaryAgentSummary?.agentId,
      );
    }
    final fallbackAgentId =
        projection.currentPrimaryAgentSummary?.agentId ?? '';
    if (projection.currentGroupId.trim().isEmpty || fallbackAgentId.isEmpty) {
      return const <String, Object?>{};
    }
    return <String, Object?>{
      'id': projection.currentGroupId.trim(),
      'name': projection.currentGroupDisplayName.trim().isNotEmpty
          ? projection.currentGroupDisplayName.trim()
          : projection.currentGroupId.trim(),
      'description': projection.derivedFromAgentBinding
          ? '由项目当前主智能体自动包装得到的单成员协作组。'
          : '',
      'orchestration': 'main_with_children',
      'source': projection.derivedFromAgentBinding
          ? 'derived_single_agent_group'
          : 'opening_projection',
      'enabled': true,
      'agents': <String>[fallbackAgentId],
      'primary_agent_id': fallbackAgentId,
      'metadata': <String, Object?>{
        'derived_from_agent_binding': projection.derivedFromAgentBinding,
      },
    };
  }

  JsonMap _openingGroupSummaryToDocument(
    OpeningSessionProjection projection, {
    required OpeningAgentGroupSummary summary,
    required String? fallbackPrimaryAgentId,
  }) {
    final sourceMembers = summary.members.isNotEmpty
        ? summary.members
        : (summary.groupId == projection.currentGroupId.trim()
              ? projection.availableAgentSummaries
              : const <OpeningAgentMemberSummary>[]);
    final memberIds = sourceMembers
        .map((member) => member.agentId.trim())
        .where((agentId) => agentId.isNotEmpty)
        .toList(growable: false);
    final primaryAgentId = sourceMembers
        .where((member) => member.isPrimary)
        .map((member) => member.agentId.trim())
        .firstWhere(
          (agentId) => agentId.isNotEmpty,
          orElse: () => fallbackPrimaryAgentId?.trim() ?? '',
        );
    return <String, Object?>{
      'id': summary.groupId,
      'name': summary.displayName,
      'description': summary.description,
      'orchestration': 'main_with_children',
      'source': projection.derivedFromAgentBinding
          ? 'derived_single_agent_group'
          : 'opening_projection',
      'enabled': summary.isSupported,
      'agents': memberIds,
      if (primaryAgentId.isNotEmpty) 'primary_agent_id': primaryAgentId,
      'metadata': <String, Object?>{
        'is_current_group': summary.isCurrent,
        'is_degraded': summary.isDegraded,
        'is_starter_group': summary.isStarterGroup,
        'derived_from_agent_binding': projection.derivedFromAgentBinding,
      },
    };
  }

  String _conversationSummary(
    ConversationSessionState? state, {
    required String fallback,
  }) {
    if (state == null || state.entries.isEmpty) {
      return fallback;
    }
    final summary = _conversationSessionStateService
        .publicSummary(state)
        .trim();
    return summary.isEmpty ? fallback : summary;
  }

  JsonMap _conversationRuntimeProfileFor() {
    // 中文注释: 上下文压力投影尽量复用当前模型执行 profile，但在 settings 或 provider 尚未就绪时允许退回空配置。
    final settings = _readSettings();
    if (settings == null || _workspaceController.currentProject == null) {
      return const <String, Object?>{};
    }
    final provider = _selectedModelProvider(settings);
    if (provider == null) {
      return const <String, Object?>{};
    }
    final requestAgent = _resolveRequestAgent();
    final executionProfile = _modelExecutionProfileService.resolve(
      settings: settings,
      provider: provider,
      agent: requestAgent.agent,
    );
    return _mapValue(executionProfile['runtime_profile']);
  }

  ConversationContextProjectionViewData? _exposedConversationContextProjection(
    ConversationSessionState? state, {
    required JsonMap runtimeProfile,
  }) {
    // 中文注释: 只在会话确实有可展示的压力、完整历史或归档时才把投影抬到 GUI，避免空会话也出现噪音徽标。
    if (state == null) {
      return null;
    }
    final projection = _conversationSessionContextProjectionService.build(
      state: state,
      runtimeProfile: runtimeProfile,
    );
    if (projection.transcriptMessageCount <= 0 &&
        projection.workingContextMessageCount <= 0 &&
        !projection.hasArchive) {
      return null;
    }
    return projection;
  }

  bool _isActiveRequestHandle(ConversationRequestHandle handle) {
    return identical(_activeRequestHandle, handle);
  }

  String _attachmentSelectionMessage(
    List<ConversationAttachmentDraft> incomingDrafts,
    List<ConversationAttachmentDraft> mergedDrafts,
  ) {
    final readyCount = incomingDrafts.where((draft) => draft.isReady).length;
    final failedCount = incomingDrafts.length - readyCount;
    if (failedCount <= 0) {
      return '已暂存 $readyCount 个会话附件。当前共 ${mergedDrafts.length} 个。';
    }
    return '已暂存 $readyCount 个会话附件，另有 $failedCount 个不可用。当前共 ${mergedDrafts.length} 个。';
  }

  Future<void> _applyRequestSuccess({
    required ConversationRequestHandle handle,
    required DraftGenerationResult result,
    required ProjectDescriptor project,
    required AppSettings settings,
    required String title,
    required bool wasModeGuidanceActive,
    required ConversationSessionState streamingBaseState,
    required JsonMap contextStrategySettings,
    required JsonMap runtimeProfile,
    required String providerTitle,
    ProjectConversationDraftRuntimePreparation? conversationDraftRuntime,
  }) async {
    // 中文注释: 成功后的文档落盘、资源刷新和右栏回写统一收口，避免再次散回发送主流程。
    final activeSessionId = _sessionIdOf(streamingBaseState);
    _updateTransientGenerationStatus(
      generationStatus: '正在整理工具结果...',
      toolCoreStatus: '正在收口工具返回与待确认状态',
    );
    await _yieldToUi();
    final persistedApprovals = await _toolPermissionApprovalRecordService
        .persistPendingApprovalsForExecutedTools(
          project,
          scopeType: ProjectToolPermissionApprovalScopes.ordinaryConversation,
          executedTools: result.executedTools,
          sessionId: activeSessionId,
        );
    final effectiveResult = _resultWithExecutedTools(
      result,
      executedTools: ValueReaders.objectList(
        persistedApprovals['executed_tools'],
      ),
    );
    final uiResult = _toolPayloadCompactionService.compactResult(
      effectiveResult,
    );
    _updateTransientGenerationStatus(
      generationStatus: '正在回写会话状态...',
      toolCoreStatus: '工具结果已返回，正在整理展示',
    );
    await _yieldToUi();
    final assistantState = _conversationSessionStateService
        .stateWithAssistantResult(
          streamingBaseState,
          uiResult,
          strategySettings: contextStrategySettings,
          modelProfile: runtimeProfile,
        );
    _replaceConversationSession(assistantState, activate: true);
    var savedPath = effectiveResult.writtenPaths.isEmpty
        ? ''
        : effectiveResult.writtenPaths.first;
    final activeDocumentPath = _workspaceController.activeDocumentPath;
    var stagedAutosaveFallback = false;
    final shouldAutoSaveFallback =
        savedPath.isEmpty &&
        !effectiveResult.cancelledByUser &&
        settings.draftFallbackProtectionEnabled &&
        _draftAutosavePolicyService.shouldAutoSave(
          result: effectiveResult,
          activeDocumentPath: activeDocumentPath,
          wasModeGuidanceActive: wasModeGuidanceActive,
        );
    if (shouldAutoSaveFallback) {
      stagedAutosaveFallback = _workspaceController
          .stageGeneratedDraftOnActiveDocument(effectiveResult.draftMarkdown);
    }
    _updateTransientGenerationStatus(
      generationStatus: '正在回写项目状态...',
      toolCoreStatus: '正在同步正文与资料变更',
    );
    await _yieldToUi();
    final runtimeArtifacts = await _finalizeConversationDraftRuntime(
      project: project,
      result: effectiveResult,
      title: title,
      savedPath: savedPath,
      preparation: conversationDraftRuntime,
    );
    savedPath = _resolvedPersistedOutputPath(
      result: effectiveResult,
      savedPath: savedPath,
      runtimeArtifacts: runtimeArtifacts,
    );
    if (!_isActiveRequestHandle(handle)) {
      return;
    }
    final selectedResourcePath = savedPath.isEmpty
        ? _workspaceController.activeDocumentPath
        : savedPath;
    final shouldReloadResources =
        savedPath.isNotEmpty ||
        effectiveResult.writtenPaths.isNotEmpty ||
        effectiveResult.changedPaths.isNotEmpty ||
        runtimeArtifacts.changedPaths.isNotEmpty;
    _updateTransientGenerationStatus(
      generationStatus: shouldReloadResources ? '正在刷新资源与文档...' : '正在整理最终结果...',
      toolCoreStatus: shouldReloadResources ? '正在同步工作区视图' : '正在完成本轮会话',
    );
    await _yieldToUi();
    final resourceEntries = shouldReloadResources
        ? await _workspaceController.reloadResourceEntries(
            selectedId: selectedResourcePath,
          )
        : _workspaceController
              .applyWorkbenchState(_readWorkbench())
              .resourceEntries;
    if (!_isActiveRequestHandle(handle)) {
      return;
    }
    final shouldOpenDocument =
        savedPath.isNotEmpty ||
        effectiveResult.writtenPaths.isNotEmpty ||
        runtimeArtifacts.outputPath.trim().isNotEmpty;
    final resolvedBody = shouldOpenDocument
        ? await _workspaceController.resolvedDocumentBody(
            project: project,
            generatedMarkdown: effectiveResult.draftMarkdown,
            relativePath: savedPath,
          )
        : '';
    if (shouldOpenDocument && resolvedBody.trim().isNotEmpty) {
      _workspaceController.openOrActivateDocument(
        relativePath: savedPath,
        title: title.isEmpty ? '新正文' : title,
        content: resolvedBody,
      );
    }
    if (!_isActiveRequestHandle(handle)) {
      return;
    }
    _mutateWorkbench((current) {
      final contextSummary = _resultContextSummary(
        effectiveResult,
        assistantState,
        runtimeArtifacts,
      );
      return applyConversationState(
        _workspaceController.applyWorkbenchState(
          current.copyWith(
            resourceEntries: resourceEntries,
            modelLabel: '$providerTitle · ${effectiveResult.modelId}',
            contextSummary: contextSummary,
            generationStatus: _generationStatusFor(
              effectiveResult,
              savedPath,
              runtimeArtifacts,
              stagedAutosaveFallback: stagedAutosaveFallback,
            ),
            toolCoreStatus: _toolCoreStatusFor(
              effectiveResult,
              runtimeArtifacts,
            ),
            isGenerating: false,
          ),
        ),
        contextSummaryOverride: contextSummary,
      );
    });
  }

  void _applyRequestFailure({
    required Object error,
    required ConversationSessionState userPromptState,
    required String cleanText,
    required String visibleText,
    required JsonMap contextStrategySettings,
    required JsonMap runtimeProfile,
  }) {
    // 中文注释: 失败提示走人话化，不把底层异常（含 Dart 类型名/堆栈相邻文本）直接抛给用户。
    final humanMessage = UserFacingErrorHumanizer.humanize(error, action: '生成');
    final failedState = _conversationSessionStateService
        .stateWithAssistantFailure(
          userPromptState,
          humanMessage,
          retryRequest: ConversationRetryRequest(
            prompt: cleanText,
            visibleText: visibleText,
            errorMessage: humanMessage,
          ),
          strategySettings: contextStrategySettings,
          modelProfile: runtimeProfile,
        );
    _replaceConversationSession(failedState, activate: true);
    _mutateWorkbench(
      (current) => applyConversationState(
        current.copyWith(
          generationStatus: humanMessage,
          toolCoreStatus: '',
          isGenerating: false,
        ),
      ),
    );
  }

  bool _needsGoalSelection(ConversationSessionState? state) {
    return state == null
        ? true
        : _boolValue(state.sessionRecord['needs_goal_selection']);
  }

  String _sessionGoalModeIdOf(ConversationSessionState? state) {
    final modeId = _stringValue(state?.sessionRecord['mode']);
    return modeId == SessionRecordConstants.modeUnselected ? '' : modeId;
  }

  String _freeTextIntentOf(ConversationSessionState? state) {
    if (state == null || state.entries.isEmpty) {
      return '';
    }
    for (final entry in state.entries.reversed) {
      if (entry.kind != ConversationEntryKind.user) {
        continue;
      }
      final text = entry.body.trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }

  RetryRequestViewData? _retryRequestViewData(
    ConversationRetryRequest? retryRequest,
  ) {
    if (retryRequest == null) {
      return null;
    }
    return RetryRequestViewData(
      label: retryRequest.label,
      errorMessage: retryRequest.errorMessage,
    );
  }

  String _resultContextSummary(
    DraftGenerationResult result,
    ConversationSessionState assistantState,
    ProjectConversationDraftRuntimeArtifacts runtimeArtifacts,
  ) {
    final sessionSummary = _conversationSummary(
      assistantState,
      fallback: '会话已更新',
    );
    final contextPackSummary = _stringValue(
      result.contextPack['summary'],
      '上下文已更新',
    );
    final infoSummary = runtimeArtifacts.informationSummary.trim();
    final infoPart = infoSummary.isEmpty ? '' : ' · $infoSummary';
    return '$sessionSummary · $contextPackSummary · 读取 ${result.selectedPaths.length} 个文件 · 工具 ${result.executedTools.length} 次$infoPart';
  }

  String _generationStatusFor(
    DraftGenerationResult result,
    String savedPath,
    ProjectConversationDraftRuntimeArtifacts runtimeArtifacts, {
    bool stagedAutosaveFallback = false,
  }) {
    final infoSummary = runtimeArtifacts.informationSummary.trim();
    String withInformation(String base) {
      if (infoSummary.isEmpty) {
        return base;
      }
      return '$base 信息状态：$infoSummary';
    }

    if (result.cancelledByUser) {
      if (result.partialContentAccepted) {
        return withInformation('已停止当前生成，并保留已完成的阶段结果。');
      }
      return withInformation('已停止当前生成。');
    }
    if (result.stoppedByToolError && savedPath.isNotEmpty) {
      final errorSummary = result.toolErrorSummary.trim();
      final suffix = errorSummary.isEmpty ? '' : '，但部分工具失败：$errorSummary';
      return withInformation('内容生成完成，并已保存到 $savedPath$suffix');
    }
    if (result.stoppedByToolError) {
      final errorSummary = result.toolErrorSummary.trim();
      return withInformation(
        errorSummary.isEmpty ? '工具执行失败。' : '工具执行失败：$errorSummary',
      );
    }
    if (result.waitingForUserChoice) {
      return withInformation('智能体需要你先确认下一步选项。');
    }
    if (savedPath.isNotEmpty) {
      return withInformation('内容生成完成，并已保存到 $savedPath');
    }
    if (stagedAutosaveFallback) {
      return withInformation('内容生成完成，已暂存到当前文档草稿，尚未正式保存。');
    }
    if (result.draftMarkdown.trim().isNotEmpty) {
      return withInformation('内容生成完成，尚未保存到项目目录。');
    }
    if (result.writtenPaths.isNotEmpty || result.changedPaths.isNotEmpty) {
      return withInformation('处理完成，项目文件已更新。');
    }
    return withInformation('本轮处理完成。');
  }

  DraftGenerationResult _resultWithExecutedTools(
    DraftGenerationResult source, {
    required List<Object?> executedTools,
  }) {
    return DraftGenerationResult(
      project: source.project,
      projectInfo: source.projectInfo,
      userPrompt: source.userPrompt,
      prompt: source.prompt,
      modelId: source.modelId,
      draftMarkdown: source.draftMarkdown,
      contextPack: source.contextPack,
      selectedPaths: source.selectedPaths,
      executedTools: List<Object?>.unmodifiable(executedTools),
      writtenPaths: source.writtenPaths,
      changedPaths: source.changedPaths,
      transcriptMessages: source.transcriptMessages,
      waitingForUserChoice: source.waitingForUserChoice,
      reasoningContent: source.reasoningContent,
      stoppedByToolError: source.stoppedByToolError,
      toolErrorSummary: source.toolErrorSummary,
      cancelledByUser: source.cancelledByUser,
      stopPhase: source.stopPhase,
      partialContentAccepted: source.partialContentAccepted,
    );
  }

  Future<void> _yieldToUi() {
    return Future<void>.delayed(Duration.zero);
  }

  void _updateTransientGenerationStatus({
    required String generationStatus,
    required String toolCoreStatus,
  }) {
    _mutateWorkbench(
      (current) => current.copyWith(
        isGenerating: true,
        generationStatus: generationStatus,
        toolCoreStatus: toolCoreStatus,
      ),
    );
  }

  String _resolvedPersistedOutputPath({
    required DraftGenerationResult result,
    required String savedPath,
    required ProjectConversationDraftRuntimeArtifacts runtimeArtifacts,
  }) {
    final explicitSavedPath = savedPath.trim();
    if (explicitSavedPath.isNotEmpty) {
      return explicitSavedPath;
    }
    final runtimeOutputPath = runtimeArtifacts.outputPath.trim();
    if (_hasPersistedPathEvidence(
      runtimeOutputPath,
      result: result,
      runtimeArtifacts: runtimeArtifacts,
    )) {
      return runtimeOutputPath;
    }
    return '';
  }

  bool _hasPersistedPathEvidence(
    String path, {
    required DraftGenerationResult result,
    required ProjectConversationDraftRuntimeArtifacts runtimeArtifacts,
  }) {
    final normalizedPath = path.trim();
    if (normalizedPath.isEmpty) {
      return false;
    }
    if (result.writtenPaths.contains(normalizedPath) ||
        result.changedPaths.contains(normalizedPath) ||
        runtimeArtifacts.changedPaths.contains(normalizedPath)) {
      return true;
    }
    final delivery = runtimeArtifacts.chapterDelivery;
    if (ValueReaders.stringValue(delivery['chapter_path']).trim() !=
        normalizedPath) {
      return false;
    }
    final outcomeStatus = ValueReaders.stringValue(
      delivery['outcome_status'],
    ).trim();
    if (outcomeStatus != 'accepted' &&
        outcomeStatus != 'proposed' &&
        outcomeStatus != 'needs_user_confirmation') {
      return false;
    }
    final stateResult = ValueReaders.mapValue(delivery['state_result']);
    return ValueReaders.boolValue(stateResult['chapter_body_delivered']);
  }

  String _toolCoreStatusFor(
    DraftGenerationResult result,
    ProjectConversationDraftRuntimeArtifacts runtimeArtifacts,
  ) {
    if (result.waitingForUserChoice) {
      return '等待选择';
    }
    final infoSummary = runtimeArtifacts.informationSummary.trim();
    if (infoSummary.isEmpty) {
      return '';
    }
    return switch (runtimeArtifacts.informationStatus.trim()) {
      'waiting_confirmation' => '资料研究待确认：$infoSummary',
      'source_insufficient' => '资料来源不足：$infoSummary',
      'executed_research' => '资料研究已执行：$infoSummary',
      'blocked' => '资料研究受阻：$infoSummary',
      'information_changed' => '资料已更新：$infoSummary',
      'no_information_change' => '无资料变更：$infoSummary',
      _ => infoSummary,
    };
  }

  String _streamingGenerationStatus(
    ProviderEndpointSettings provider,
    DraftGenerationProgress progress,
  ) {
    if (progress.pendingToolCalls.isNotEmpty) {
      return '正在通过 ${provider.title} 组织工具调用...';
    }
    if (progress.executedTools.isNotEmpty &&
        progress.draftMarkdown.trim().isEmpty) {
      return '正在通过 ${provider.title} 处理工具结果...';
    }
    return '正在通过 ${provider.title} 接收流式内容...';
  }

  String _streamingToolStatus(DraftGenerationProgress progress) {
    // 中文注释: 工具进行中的提示放在状态条，避免把短暂执行态挤进正文时间线。
    if (progress.pendingToolCalls.isNotEmpty) {
      final entries = _conversationSessionStateService
          .toolEntriesFromPendingCalls(progress.pendingToolCalls);
      if (entries.isEmpty) {
        return '正在准备工具调用...';
      }
      return entries.last.body;
    }
    if (progress.executedTools.isNotEmpty &&
        progress.draftMarkdown.trim().isEmpty) {
      final entries = _conversationSessionStateService
          .toolEntriesFromExecutedTools(
            progress.executedTools,
            includeDetailBodies: false,
          );
      if (entries.isNotEmpty) {
        return '${entries.last.title} 已返回，正在整理结果';
      }
      return '正在整理工具结果...';
    }
    return '';
  }

  String _titleFromPrompt(String prompt) {
    final lines = prompt
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty);
    if (lines.isEmpty) {
      return '新正文';
    }
    final firstLine = lines.first;
    return firstLine.length <= 24
        ? firstLine
        : '${firstLine.substring(0, 24)}...';
  }

  String _resultMessage(JsonMap result, {required String success}) {
    if (_boolValue(result['ok'])) {
      return _stringValue(result['message'], success);
    }
    return _stringValue(result['message'], '执行失败。');
  }

  JsonMap _modelSettingsOf(AppSettings settings) {
    return _mapValue(settings.extraSettings['model_settings']);
  }

  String _stringValue(Object? value, [String fallback = '']) {
    if (value == null) {
      return fallback;
    }
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  bool _boolValue(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    final normalized = value?.toString().trim().toLowerCase() ?? '';
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }

  JsonMap _mapValue(Object? value) {
    if (value is Map<String, Object?>) {
      return ValueReaders.deepCopyMap(value);
    }
    if (value is Map) {
      final result = <String, Object?>{};
      value.forEach((key, item) {
        result[key.toString()] = item;
      });
      return result;
    }
    return const <String, Object?>{};
  }
}
