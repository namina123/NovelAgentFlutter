import 'dart:async';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../../app/theme/theme_preference_resolver.dart';
import '../../presentation/contracts/conversation_action_handler.dart';
import '../../presentation/models/conversation_agent_selector_view_data.dart';
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
import 'generate_draft_use_case_factory.dart';
import '../../presentation/models/conversation_group_selector_view_data.dart';
import '../services/conversation_guide_view_data_service.dart';
import '../services/conversation_group_selector_view_data_service.dart';
import '../services/conversation_opening_panel_view_data_service.dart';
import '../services/conversation_draft_autosave_policy_service.dart';
import '../services/project_opening_maturity_assessment_service.dart';
import '../services/project_opening_session_projection_service.dart';
import '../services/project_opening_agent_group_binding_service.dart';
import '../services/conversation_request_runtime_service.dart';
import '../services/conversation_session_state_service.dart';
import '../services/conversation_streaming_state_service.dart';
import '../services/conversation_user_visible_text_service.dart';
import '../services/workbench_primary_action_service.dart';
import 'workbench_workspace_controller.dart';
import '../models/opening_agent_group_summary.dart';
import '../models/opening_session_projection.dart';

class WorkbenchConversationController implements ConversationActionHandler {
  WorkbenchConversationController({
    required SaveDraftUseCase saveDraftUseCase,
    required GenerateDraftUseCaseFactory generateDraftUseCaseFactory,
    required ModelExecutionProfileService modelExecutionProfileService,
    required ConversationSessionStateService conversationSessionStateService,
    required ConversationStreamingStateService
    conversationStreamingStateService,
    required ConversationGuideViewDataService conversationGuideViewDataService,
    required ConversationOpeningPanelViewDataService
    conversationOpeningPanelViewDataService,
    ProjectOpeningMaturityAssessmentService?
    projectOpeningMaturityAssessmentService,
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
    required UserOptionPromptBuilderService userOptionPromptBuilderService,
    required LoadModeGuidanceStateUseCase loadModeGuidanceStateUseCase,
    required AnswerModeGuidanceStageUseCase answerModeGuidanceStageUseCase,
    required BuildModeGuidancePlanInputUseCase
    buildModeGuidancePlanInputUseCase,
    required ModeGuidanceTransitionService modeGuidanceTransitionService,
    required ProjectWorkflowRuntimeService workflowRuntimeService,
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
    ConversationAgentSelectorViewDataService?
    conversationAgentSelectorViewDataService,
    ConversationRequestAgentResolverService?
    conversationRequestAgentResolverService,
    ConversationGroupSelectorViewDataService?
    conversationGroupSelectorViewDataService,
    required void Function(String message) announce,
  }) : _saveDraftUseCase = saveDraftUseCase,
       _generateDraftUseCaseFactory = generateDraftUseCaseFactory,
       _modelExecutionProfileService = modelExecutionProfileService,
       _conversationSessionStateService = conversationSessionStateService,
       _conversationStreamingStateService = conversationStreamingStateService,
       _conversationGuideViewDataService = conversationGuideViewDataService,
       _conversationOpeningPanelViewDataService =
           conversationOpeningPanelViewDataService,
       _projectOpeningMaturityAssessmentService =
           projectOpeningMaturityAssessmentService ??
           const ProjectOpeningMaturityAssessmentService(),
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
       _userOptionPromptBuilderService = userOptionPromptBuilderService,
       _loadModeGuidanceStateUseCase = loadModeGuidanceStateUseCase,
       _answerModeGuidanceStageUseCase = answerModeGuidanceStageUseCase,
       _buildModeGuidancePlanInputUseCase = buildModeGuidancePlanInputUseCase,
       _modeGuidanceTransitionService = modeGuidanceTransitionService,
       _workflowRuntimeService = workflowRuntimeService,
       _projectLongTaskToolExecutor = ProjectLongTaskToolExecutor(
         loadPlanInput: (project, {required modeId}) =>
             buildModeGuidancePlanInputUseCase.execute(project, modeId: modeId),
         createLongTaskWorkflow:
             (project, runtimeMode, {options = const <String, Object?>{}}) =>
                 workflowRuntimeService.createLongTaskWorkflow(
                   project,
                   runtimeMode,
                   options: options,
                 ),
       ),
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
       _conversationAgentSelectorViewDataService =
           conversationAgentSelectorViewDataService ??
           const ConversationAgentSelectorViewDataService(),
       _conversationRequestAgentResolverService =
           conversationRequestAgentResolverService ??
           const ConversationRequestAgentResolverService(),
       _conversationGroupSelectorViewDataService =
           conversationGroupSelectorViewDataService ??
           const ConversationGroupSelectorViewDataService(),
       _announce = announce;

  final SaveDraftUseCase _saveDraftUseCase;
  final GenerateDraftUseCaseFactory _generateDraftUseCaseFactory;
  final ModelExecutionProfileService _modelExecutionProfileService;
  final ConversationSessionStateService _conversationSessionStateService;
  final ConversationStreamingStateService _conversationStreamingStateService;
  final ConversationGuideViewDataService _conversationGuideViewDataService;
  final ConversationOpeningPanelViewDataService
  _conversationOpeningPanelViewDataService;
  final ProjectOpeningMaturityAssessmentService
  _projectOpeningMaturityAssessmentService;
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
  final UserOptionPromptBuilderService _userOptionPromptBuilderService;
  final LoadModeGuidanceStateUseCase _loadModeGuidanceStateUseCase;
  final AnswerModeGuidanceStageUseCase _answerModeGuidanceStageUseCase;
  final BuildModeGuidancePlanInputUseCase _buildModeGuidancePlanInputUseCase;
  final ModeGuidanceTransitionService _modeGuidanceTransitionService;
  final ProjectWorkflowRuntimeService _workflowRuntimeService;
  final ProjectLongTaskToolExecutor _projectLongTaskToolExecutor;
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
  final ConversationAgentSelectorViewDataService
  _conversationAgentSelectorViewDataService;
  final ConversationRequestAgentResolverService
  _conversationRequestAgentResolverService;
  final ConversationGroupSelectorViewDataService
  _conversationGroupSelectorViewDataService;
  final void Function(String message) _announce;
  final ThemePreferenceResolver _themePreferenceResolver =
      ThemePreferenceResolver();
  ConversationRequestHandle? _activeRequestHandle;

  void resetRuntimeState() {
    // 中文注释: 切换项目时会话运行时状态必须整体重置，避免旧项目会话残留继续投影到新工作区。
    _activeRequestHandle?.requestCancellation();
    _activeRequestHandle = null;
    _writeRuntimeState(const WorkbenchConversationRuntimeState());
  }

  WorkbenchViewData applyConversationState(
    WorkbenchViewData base, {
    String? contextSummaryOverride,
  }) {
    // 中文注释: 会话视图投影统一在这里完成，避免壳层和工作区各自手拼右栏状态。
    final runtimeState = _readRuntimeState();
    final activeState = _activeConversationState();
    _scheduleOpeningProjectionRefresh(
      runtimeState: runtimeState,
      activeState: activeState,
    );
    final openingMaturity = _projectOpeningMaturityAssessmentService.build(
      projectType: _workspaceController.currentProject?.projectType ?? 'novel',
      resourceEntries: base.resourceEntries,
      openingProjection: runtimeState.openingProjection,
    );
    final guide = _conversationGuideViewDataService.build(
      projectType: _workspaceController.currentProject?.projectType ?? 'novel',
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
    return base.copyWith(
      conversationEntries: activeState.entries,
      pendingOptions: activeState.pendingOptions,
      subAgentRuns: activeState.subAgentRuns,
      retryRequest: _retryRequestViewData(activeState.retryRequest),
      contextSummary: contextSummary,
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
    // 中文注释: 顶部模型切换继续写回共享设置，保证 GUI/CLI 默认模型配置一致。
    final settings = _readSettings();
    final cleanModelId = modelId.trim();
    if (settings == null || cleanModelId.isEmpty) {
      return;
    }
    final updated = settings.copyWith(
      defaultModelId: cleanModelId,
      extraSettings: <String, Object?>{
        ...settings.extraSettings,
        'model_settings': <String, Object?>{
          ..._modelSettingsOf(settings),
          'model_id': cleanModelId,
        },
      },
    );
    _persistSettings(updated, successMessage: '已切换模型：$cleanModelId');
  }

  @override
  void onAgentGroupSelected(String groupId) {
    // 中文注释: 会话栏与 opening 面板共用同一条项目默认组切换链，保证 group-first 事实源只有一处。
    unawaited(_selectOpeningAgentGroup(groupId));
  }

  @override
  void onConversationAgentSelected(String agentId) {
    final cleanAgentId = agentId.trim();
    if (cleanAgentId.isEmpty) {
      return;
    }
    _mutateWorkbench(
      (current) => applyConversationState(
        current.copyWith(
          agentSelector: current.agentSelector.copyWith(
            currentAgentId: cleanAgentId,
          ),
        ),
      ),
    );
  }

  Future<void> selectProjectAgentGroup(String groupId) async {
    // 中文注释: 项目级配置入口复用同一条组切换链，避免项目面板和会话栏各自维护绑定写入逻辑。
    await _selectOpeningAgentGroup(groupId);
  }

  @override
  void onQuickThemeRequested() async {
    // 中文注释: 快速主题切换直接复用正式主题偏好写盘链，避免工作台和设置页出现两套主题事实源。
    final settings = _readSettings();
    if (settings == null) {
      return;
    }
    final nextThemeId = _themePreferenceResolver.quickToggleThemeId(
      _readThemeId(),
    );
    final updated = settings.copyWith(
      themeSettings: _themePreferenceResolver.payloadForSelectedTheme(
        selectedThemeId: nextThemeId,
        base: settings.themeSettings,
      ),
    );
    await _saveSettingsSilently(updated);
    _refreshSettingsViewData();
    _notifyShell();
    _announce('已切换主题：${_themePreferenceResolver.labelOf(nextThemeId)}');
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
    // 中文注释: 会话/文档切换只改工作台显示态，不重载项目和文档内容。
    final nextVisible = !_readWorkbench().isDocumentsWorkspaceVisible;
    _mutateWorkbench(
      (current) => applyConversationState(
        current.copyWith(
          isDocumentsWorkspaceVisible: nextVisible,
          generationStatus: nextVisible ? '已切到文档视图。' : '已切回会话视图。',
        ),
      ),
    );
  }

  @override
  void onDocumentsWorkspaceRequested() {
    // 中文注释: 窄屏文档入口只切换显示状态，不自行拼装工作台其他面板。
    _mutateWorkbench(
      (current) => applyConversationState(
        current.copyWith(isDocumentsWorkspaceVisible: true),
      ),
    );
  }

  @override
  void onDocumentsWorkspaceDismissRequested() {
    // 中文注释: 文档工作区关闭只恢复会话视图，不改会话内容和项目状态。
    _mutateWorkbench(
      (current) => applyConversationState(
        current.copyWith(isDocumentsWorkspaceVisible: false),
      ),
    );
  }

  @override
  void onHistoryRequested() {
    // 中文注释: 历史面板切换只改当前会话视图投影，不触碰会话底层记录。
    final runtimeState = _readRuntimeState();
    _writeRuntimeState(
      runtimeState.copyWith(
        showSessionHistory: !runtimeState.showSessionHistory,
      ),
    );
    _mutateWorkbench((current) => applyConversationState(current));
  }

  @override
  void onNewSessionRequested() {
    // 中文注释: 新会话只重置交互链，不影响当前项目工作区和已打开文档。
    final activeState = _activeConversationState();
    if (activeState != null &&
        activeState.entries.isEmpty &&
        _needsGoalSelection(activeState)) {
      _writeRuntimeState(
        _readRuntimeState().copyWith(showSessionHistory: false),
      );
      _mutateWorkbench(
        (current) => applyConversationState(
          current.copyWith(generationStatus: '当前已经是一个待选择目标的新会话。'),
        ),
      );
      unawaited(
        _refreshOpeningProjection(
          activeState: activeState,
          forceReloadModeGuidance: false,
        ),
      );
      return;
    }
    final session = _createConversationSession();
    _replaceConversationSession(session, activate: true);
    _writeRuntimeState(
      _readRuntimeState().copyWith(
        showSessionHistory: false,
        guideScope: '',
        activeModeGuidanceState: null,
      ),
    );
    _mutateWorkbench(
      (current) => applyConversationState(
        current.copyWith(generationStatus: '已创建新会话，请先选择一个入口，或直接输入第一句话。'),
      ),
    );
    unawaited(
      _refreshOpeningProjection(
        activeState: session,
        forceReloadModeGuidance: true,
      ),
    );
  }

  @override
  void onSessionHistorySelected(String sessionId) {
    // 中文注释: 历史切换只改变活动会话指针，不让页面直接操作会话记录结构。
    final runtimeState = _readRuntimeState();
    final exists = runtimeState.sessions.any(
      (state) => _sessionIdOf(state) == sessionId,
    );
    if (!exists) {
      return;
    }
    _writeRuntimeState(
      runtimeState.copyWith(
        activeSessionId: sessionId,
        showSessionHistory: false,
        guideScope: '',
      ),
    );
    _mutateWorkbench(
      (current) => applyConversationState(
        current.copyWith(generationStatus: '已切换到所选历史会话。'),
      ),
    );
    unawaited(
      _refreshOpeningProjection(
        activeState: _activeConversationState(),
        forceReloadModeGuidance: false,
      ),
    );
  }

  @override
  Future<void> onUserOptionSelected(UserOptionViewData option) async {
    // 中文注释: 选项点击统一转成补充提示，再复用同一条发送链继续推进。
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
    );
  }

  @override
  void onConversationSettingsRequested() {
    // 中文注释: 会话栏设置入口直接复用全局设置页，不再长一套局部设置状态。
    _showSettings();
  }

  @override
  Future<void> onPrimaryActionRequested(String actionId) async {
    // 中文注释: 主动作计划在独立服务中解析，控制器只负责执行对应的三类结果。
    PrimaryActionViewData? action;
    for (final item in _readWorkbench().primaryActions) {
      if (item.id == actionId) {
        action = item;
        break;
      }
    }
    if (action == null) {
      _announce('未找到对应的工作流入口。');
      return;
    }
    if (await _handleGuideNavigationAction(action)) {
      return;
    }
    final plan = _workbenchPrimaryActionService.build(
      action: action,
      project: _workspaceController.currentProjectInfo(),
      activeDocumentPath: _workspaceController.activeDocumentPath,
      activeDocumentBody: _workspaceController.activeDocumentBody,
    );
    switch (plan.kind) {
      case WorkbenchPrimaryActionPlanKind.refreshProject:
        _workspaceController.onRefreshFilesRequested();
        return;
      case WorkbenchPrimaryActionPlanKind.announce:
        _announce(plan.message);
        return;
      case WorkbenchPrimaryActionPlanKind.sendPrompt:
        _startPrimaryActionPrompt(
          plan,
          userVisibleText: _conversationUserVisibleTextService
              .textForPrimaryAction(action, plan),
        );
        return;
    }
  }

  @override
  Future<void> onRetryLastFailedRequested() async {
    // 中文注释: 重试只复用上一轮失败请求，不额外插入新的用户消息。
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
    // 中文注释: 提示词优化链路尚未独立落地前，这里只给出明确引导，不制造空按钮。
    _announce('当前先直接发送自然语言需求；提示词优化链路后续会接独立用例。');
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
    // 中文注释: 附件动作只负责编排 picker 和 session 暂存；文件探测与后续发送桥接继续留在独立服务。
    if (_readRuntimeState().activeModeGuidanceState != null) {
      _announce('当前引导阶段暂不接受会话附件。');
      return;
    }
    final capabilities = const ConversationInputCapabilityService().resolve(
      context: _readWorkbench().inputCapabilityContext.copyWith(
        hasActiveProject: _workspaceController.currentProject != null,
        isGenerating: _readWorkbench().isGenerating,
      ),
    );
    if (!capabilities.supportsAttachmentEntry) {
      _announce('当前模型或宿主环境暂不支持会话附件。');
      return;
    }
    if (_readWorkbench().isGenerating) {
      _announce('请等待当前生成结束后再选择附件。');
      return;
    }
    final selectedPaths = await _conversationAttachmentPickerService
        .pickFiles();
    if (selectedPaths.isEmpty) {
      _announce('没有选择任何会话附件。');
      return;
    }
    final activeState = _ensureConversationSession();
    final incomingDrafts = await _conversationAttachmentDraftService
        .createDrafts(selectedPaths);
    final mergedDrafts = _conversationAttachmentDraftService.mergeDrafts(
      currentDrafts: activeState.attachmentDrafts,
      incomingDrafts: incomingDrafts,
    );
    final nextState = _conversationSessionStateService
        .stateWithAttachmentDrafts(activeState, mergedDrafts);
    _replaceConversationSession(nextState, activate: true);
    _mutateWorkbench((current) => applyConversationState(current));
    _announce(_attachmentSelectionMessage(incomingDrafts, mergedDrafts));
  }

  @override
  Future<void> onSendRequested(String text) async {
    // 中文注释: 所有发送动作统一复用同一条请求链，避免按钮发送和选项发送行为分叉。
    await _sendPrompt(text);
  }

  Future<void> _sendPrompt(
    String text, {
    String visibleText = '',
    bool retryLastFailure = false,
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
    _replaceConversationSession(userPromptState, activate: true);
    unawaited(
      _refreshOpeningProjection(
        activeState: userPromptState,
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
          userPromptState,
          fallback: '正在整理会话与项目上下文',
        ),
      ),
    );
    final sessionContext = _conversationSessionStateService
        .sessionContextMarkdown(
          userPromptState,
          excludeLatestUserContent: cleanText,
        );
    final streamingContextSummary = _conversationSummary(
      userPromptState,
      fallback: '正在接收模型输出',
    );
    var streamingBaseState = userPromptState;
    ProjectConversationDraftRuntimePreparation? conversationDraftRuntime;
    late final ConversationRequestHandle requestHandle;
    try {
      requestHandle = _conversationRequestRuntimeService.start(
        onProgress: (progress) {
          if (!_isActiveRequestHandle(requestHandle)) {
            return;
          }
          final streamingState = _conversationStreamingStateService
              .stateWithProgress(streamingBaseState, progress);
          streamingBaseState = streamingState;
          _replaceConversationSession(streamingState, activate: true);
          _mutateWorkbench(
            (current) => applyStreamingConversationState(
              current,
              activeState: streamingState,
              contextSummary: streamingContextSummary,
              generationStatus: _streamingGenerationStatus(provider, progress),
              toolCoreStatus: _streamingToolStatus(progress),
            ),
          );
        },
        execute: ({required onProgress, required cancellationToken}) async {
          final coreCancellationToken = DraftGenerationCancellationToken();
          void syncCancellation() {
            coreCancellationToken.cancel();
          }

          cancellationToken.addListener(syncCancellation);
          final executionConstraints = await _resolveExecutionConstraints(
            project: project,
            agent: requestAgent.agent,
          );
          conversationDraftRuntime = await _prepareConversationDraftRuntime(
            project: project,
            agent: requestAgent.agent,
          );
          final useCase = _generateDraftUseCaseFactory(
            provider,
            settings.networkSettings,
          );
          final selectedCollaborationGroup =
              _selectedCollaborationGroupForRuntime(
                _readRuntimeState().openingProjection,
              );
          try {
            return useCase.execute(
              project: project,
              userPrompt: cleanText,
              modelId: resolvedModelId,
              title: title,
              agent: requestAgent.agent,
              selectedCollaborationGroup: selectedCollaborationGroup,
              sessionContext: _mergeSessionContext(
                _mergeSessionContext(
                  sessionContext,
                  ValueReaders.stringValue(
                    executionConstraints['session_context_markdown'],
                  ),
                ),
                conversationDraftRuntime?.sessionContextMarkdown ?? '',
              ),
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
        userPromptState: userPromptState,
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

  Future<JsonMap> _resolveExecutionConstraints({
    required ProjectDescriptor project,
    required JsonMap agent,
  }) async {
    if (_draftExecutionConstraintRuntimeService == null) {
      return const <String, Object?>{};
    }
    return _draftExecutionConstraintRuntimeService.resolve(
      project,
      appliesTo: ConstraintBindingAppliesTo.writing,
      agentId: ValueReaders.stringValue(agent['id']),
      stageId: 'draft',
      intent: 'draft',
      taskType: _ordinaryConversationTaskType(agent),
    );
  }

  Future<ProjectConversationDraftRuntimePreparation?>
  _prepareConversationDraftRuntime({
    required ProjectDescriptor project,
    required JsonMap agent,
  }) async {
    if (_conversationDraftRuntimeService == null) {
      return null;
    }
    return _conversationDraftRuntimeService.prepareDraftRun(
      project,
      taskType: _ordinaryConversationTaskType(agent),
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

  String _ordinaryConversationTaskType(JsonMap agent) {
    final tokens = <String>[
      ValueReaders.stringValue(agent['id']),
      ValueReaders.stringValue(agent['role']),
      ValueReaders.stringValue(agent['name']),
      ValueReaders.stringValue(agent['display_name']),
      ValueReaders.stringValue(agent['description']),
    ].join(' ').toLowerCase();
    if (tokens.contains('review')) {
      return 'review';
    }
    if (tokens.contains('recover') ||
        tokens.contains('repair') ||
        tokens.contains('修复') ||
        tokens.contains('恢复')) {
      return 'revision';
    }
    if (tokens.contains('profile') ||
        tokens.contains('architect') ||
        tokens.contains('解释器')) {
      return 'planning';
    }
    return 'chapter';
  }

  Future<bool> _handleGuideNavigationAction(
    PrimaryActionViewData action,
  ) async {
    // 中文注释: 工作流细分页导航只切换引导状态，不直接触发模型调用。
    final runtimeState = _readRuntimeState();
    switch (action.commandId.trim()) {
      case 'opening.launch_long_task':
        await _launchLongTaskEntry();
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
        final planInput = await _buildModeGuidancePlanInputUseCase.execute(
          project,
          modeId: modeId,
        );
        if (planInput == null) {
          _announce('当前还没有可用的模式状态，请先完成模式引导。');
          return true;
        }
        if (!planInput.isReady) {
          _announce('当前模式信息尚未收束完成，请先完成当前阶段。');
          return true;
        }
        await _createWorkflowFromModeGuidance(planInput);
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

  Future<void> _createWorkflowFromModeGuidance(
    ModeGuidancePlanInput planInput,
  ) async {
    // 中文注释: 模式引导完成后的队列创建直接走共享 runtime，而不是再让模型猜测结构。
    final project = _workspaceController.currentProject;
    if (project == null) {
      _announce('请先创建或打开长篇项目。');
      return;
    }
    _writeRuntimeState(
      _readRuntimeState().copyWith(
        guideScope: '',
        activeModeGuidanceState: null,
      ),
    );
    _mutateWorkbench(
      (current) => applyConversationState(
        current.copyWith(
          generationStatus: '正在根据模式引导生成长任务队列...',
          toolCoreStatus: '',
        ),
      ),
    );
    try {
      final result = await _workflowRuntimeService.createLongTaskWorkflow(
        project,
        planInput.runtimeMode,
        options: planInput.options,
      );
      _workspaceController.onRefreshFilesRequested();
      await _workspaceController.refreshProjectLongTaskSummary();
      _announce(_resultMessage(result, success: '长任务队列已根据模式引导生成。'));
    } catch (error) {
      _announce('根据模式引导生成长任务队列失败：$error');
    } finally {
      _mutateWorkbench((current) => applyConversationState(current));
    }
  }

  Future<void> _startLongTaskRunFromOpening(
    PrimaryActionViewData action,
  ) async {
    // 中文注释: opening 阶段的正式启动动作复用现有 start_long_task_run 工具链，不再在 app 层另写一套判定。
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
      final result = await _projectLongTaskToolExecutor.startLongTaskRun(
        project,
        action.payload,
      );
      _workspaceController.onRefreshFilesRequested();
      await _workspaceController.refreshProjectLongTaskSummary();
      _announce(_resultMessage(result, success: '已根据当前开局状态启动长任务。'));
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

  Future<void> _launchLongTaskEntry() async {
    final project = _workspaceController.currentProject;
    if (project == null) {
      _announce('请先创建或打开长篇项目。');
      return;
    }
    final runtimeState = _readRuntimeState();
    final projection = runtimeState.openingProjection;
    final projectType = projection?.projectTypeId.trim().isNotEmpty == true
        ? projection!.projectTypeId.trim()
        : project.projectType.trim();
    if (projectType != 'long_novel') {
      _announce('只有长任务相关项目才会显示这个入口。');
      return;
    }
    final targetAction = _resolveLongTaskLaunchTarget(projection);
    if (targetAction != null) {
      await _handleGuideNavigationAction(targetAction);
      return;
    }
    await _handleGuideNavigationAction(
      const PrimaryActionViewData(
        id: 'opening.choose_long_task_mode',
        title: '选择长任务模式',
        description: '先确认当前长任务模式，再继续启动正式任务链。',
        commandId: 'opening.choose_long_task_mode',
      ),
    );
  }

  PrimaryActionViewData? _resolveLongTaskLaunchTarget(
    OpeningSessionProjection? projection,
  ) {
    if (projection == null) {
      return null;
    }
    final suggestedActions = projection.orchestration.suggestedActions;
    if (suggestedActions.isEmpty) {
      return null;
    }
    final action = suggestedActions.first;
    return PrimaryActionViewData(
      id: action.id,
      title: action.title,
      description: action.description,
      commandId: action.commandId,
      payload: action.payload,
    );
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
  }

  String _sessionIdOf(ConversationSessionState state) {
    final id = _stringValue(state.sessionRecord['session_id']).trim();
    if (id.isNotEmpty) {
      return id;
    }
    return _stringValue(state.sessionRecord['id']);
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
    final assistantState = _conversationSessionStateService
        .stateWithAssistantResult(
          streamingBaseState,
          result,
          strategySettings: contextStrategySettings,
          modelProfile: runtimeProfile,
        );
    _replaceConversationSession(assistantState, activate: true);
    var savedPath = result.writtenPaths.isEmpty
        ? ''
        : result.writtenPaths.first;
    final shouldAutoSaveFallback =
        savedPath.isEmpty &&
        !result.cancelledByUser &&
        settings.autoSaveDrafts &&
        _draftAutosavePolicyService.shouldAutoSave(
          result: result,
          activeDocumentPath: _workspaceController.activeDocumentPath,
          wasModeGuidanceActive: wasModeGuidanceActive,
        );
    if (shouldAutoSaveFallback) {
      savedPath = await _saveDraftUseCase.execute(
        project: project,
        content: result.draftMarkdown,
        title: title,
      );
    }
    final runtimeArtifacts = await _finalizeConversationDraftRuntime(
      project: project,
      result: result,
      title: title,
      savedPath: savedPath,
      preparation: conversationDraftRuntime,
    );
    if (savedPath.isEmpty && runtimeArtifacts.outputPath.trim().isNotEmpty) {
      savedPath = runtimeArtifacts.outputPath.trim();
    }
    if (!_isActiveRequestHandle(handle)) {
      return;
    }
    final selectedResourcePath = savedPath.isEmpty
        ? _workspaceController.activeDocumentPath
        : savedPath;
    final shouldReloadResources =
        savedPath.isNotEmpty ||
        result.writtenPaths.isNotEmpty ||
        result.changedPaths.isNotEmpty ||
        runtimeArtifacts.changedPaths.isNotEmpty;
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
        result.writtenPaths.isNotEmpty ||
        runtimeArtifacts.outputPath.trim().isNotEmpty;
    final resolvedBody = shouldOpenDocument
        ? await _workspaceController.resolvedDocumentBody(
            project: project,
            generatedMarkdown: result.draftMarkdown,
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
    _mutateWorkbench(
      (current) => applyConversationState(
        _workspaceController.applyWorkbenchState(
          current.copyWith(
            resourceEntries: resourceEntries,
            modelLabel: '$providerTitle · ${result.modelId}',
            contextSummary: _resultContextSummary(result, assistantState),
            generationStatus: _generationStatusFor(result, savedPath),
            toolCoreStatus: result.waitingForUserChoice ? '等待选择' : '',
            isGenerating: false,
          ),
        ),
      ),
    );
  }

  void _applyRequestFailure({
    required Object error,
    required ConversationSessionState userPromptState,
    required String cleanText,
    required String visibleText,
    required JsonMap contextStrategySettings,
    required JsonMap runtimeProfile,
  }) {
    final failedState = _conversationSessionStateService
        .stateWithAssistantFailure(
          userPromptState,
          '生成失败：$error',
          retryRequest: ConversationRetryRequest(
            prompt: cleanText,
            visibleText: visibleText,
            errorMessage: '生成失败：$error',
          ),
          strategySettings: contextStrategySettings,
          modelProfile: runtimeProfile,
        );
    _replaceConversationSession(failedState, activate: true);
    _mutateWorkbench(
      (current) => applyConversationState(
        current.copyWith(
          generationStatus: '生成失败：$error',
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
  ) {
    final sessionSummary = _conversationSummary(
      assistantState,
      fallback: '会话已更新',
    );
    final contextPackSummary = _stringValue(
      result.contextPack['summary'],
      '上下文已更新',
    );
    return '$sessionSummary · $contextPackSummary · 读取 ${result.selectedPaths.length} 个文件 · 工具 ${result.executedTools.length} 次';
  }

  String _generationStatusFor(DraftGenerationResult result, String savedPath) {
    if (result.cancelledByUser) {
      if (result.partialContentAccepted) {
        return '已停止当前生成，并保留已完成的阶段结果。';
      }
      return '已停止当前生成。';
    }
    if (result.stoppedByToolError && savedPath.isNotEmpty) {
      final errorSummary = result.toolErrorSummary.trim();
      final suffix = errorSummary.isEmpty ? '' : '，但部分工具失败：$errorSummary';
      return '内容生成完成，并已保存到 $savedPath$suffix';
    }
    if (result.stoppedByToolError) {
      final errorSummary = result.toolErrorSummary.trim();
      return errorSummary.isEmpty ? '工具执行失败。' : '工具执行失败：$errorSummary';
    }
    if (result.waitingForUserChoice) {
      return '智能体需要你先确认下一步选项。';
    }
    if (savedPath.isNotEmpty) {
      return '内容生成完成，并已保存到 $savedPath';
    }
    if (result.draftMarkdown.trim().isNotEmpty) {
      return '内容生成完成，尚未保存到项目目录。';
    }
    if (result.writtenPaths.isNotEmpty || result.changedPaths.isNotEmpty) {
      return '处理完成，项目文件已更新。';
    }
    return '本轮处理完成。';
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
      final names = progress.pendingToolCalls
          .map((call) => _stringValue(call['name']))
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList(growable: false);
      if (names.isEmpty) {
        return '正在准备工具调用...';
      }
      return '正在调用：${names.join('、')}';
    }
    if (progress.executedTools.isNotEmpty &&
        progress.draftMarkdown.trim().isEmpty) {
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
