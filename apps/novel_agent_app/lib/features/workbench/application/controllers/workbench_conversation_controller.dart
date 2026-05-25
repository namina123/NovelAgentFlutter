import 'package:flutter/material.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../presentation/contracts/conversation_action_handler.dart';
import '../../presentation/models/retry_request_view_data.dart';
import '../../presentation/models/user_option_view_data.dart';
import '../../presentation/models/workbench_view_data.dart';
import '../models/conversation_retry_request.dart';
import '../models/conversation_session_state.dart';
import '../models/workbench_conversation_runtime_state.dart';
import '../models/workbench_primary_action_plan.dart';
import 'generate_draft_use_case_factory.dart';
import '../services/conversation_guide_view_data_service.dart';
import '../services/conversation_session_state_service.dart';
import '../services/conversation_streaming_state_service.dart';
import '../services/conversation_user_visible_text_service.dart';
import '../services/workbench_primary_action_service.dart';
import 'workbench_workspace_controller.dart';

class WorkbenchConversationController implements ConversationActionHandler {
  WorkbenchConversationController({
    required SaveDraftUseCase saveDraftUseCase,
    required GenerateDraftUseCaseFactory generateDraftUseCaseFactory,
    required ModelExecutionProfileService modelExecutionProfileService,
    required ConversationSessionStateService conversationSessionStateService,
    required ConversationStreamingStateService
    conversationStreamingStateService,
    required ConversationGuideViewDataService conversationGuideViewDataService,
    required ConversationUserVisibleTextService conversationUserVisibleTextService,
    required WorkbenchPrimaryActionService workbenchPrimaryActionService,
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
    required void Function(WorkbenchViewData Function(WorkbenchViewData current))
    mutateWorkbench,
    required AppSettings? Function() readSettings,
    required Future<void> Function(
      AppSettings nextSettings, {
      required String successMessage,
      String? selectedProviderId,
    })
    persistSettings,
    required void Function() refreshSettingsViewData,
    required ThemeMode Function() readThemeMode,
    required void Function(ThemeMode themeMode) writeThemeMode,
    required void Function() notifyShell,
    required Future<void> Function() showSettings,
    required JsonMap Function(AppSettings settings) contextStrategySettingsOf,
    required ProviderEndpointSettings? Function(AppSettings settings)
    selectedModelProvider,
    required String Function(AppSettings settings) agentLabel,
    required void Function(String message) announce,
  }) : _saveDraftUseCase = saveDraftUseCase,
       _generateDraftUseCaseFactory = generateDraftUseCaseFactory,
       _modelExecutionProfileService = modelExecutionProfileService,
       _conversationSessionStateService = conversationSessionStateService,
       _conversationStreamingStateService = conversationStreamingStateService,
       _conversationGuideViewDataService = conversationGuideViewDataService,
       _conversationUserVisibleTextService = conversationUserVisibleTextService,
       _workbenchPrimaryActionService = workbenchPrimaryActionService,
       _userOptionPromptBuilderService = userOptionPromptBuilderService,
       _loadModeGuidanceStateUseCase = loadModeGuidanceStateUseCase,
       _answerModeGuidanceStageUseCase = answerModeGuidanceStageUseCase,
       _buildModeGuidancePlanInputUseCase =
           buildModeGuidancePlanInputUseCase,
       _modeGuidanceTransitionService = modeGuidanceTransitionService,
       _workflowRuntimeService = workflowRuntimeService,
       _workspaceController = workspaceController,
       _readRuntimeState = readRuntimeState,
       _writeRuntimeState = writeRuntimeState,
       _readWorkbench = readWorkbench,
       _mutateWorkbench = mutateWorkbench,
       _readSettings = readSettings,
       _persistSettings = persistSettings,
       _refreshSettingsViewData = refreshSettingsViewData,
       _readThemeMode = readThemeMode,
       _writeThemeMode = writeThemeMode,
       _notifyShell = notifyShell,
       _showSettings = showSettings,
       _contextStrategySettingsOf = contextStrategySettingsOf,
       _selectedModelProvider = selectedModelProvider,
       _agentLabel = agentLabel,
       _announce = announce;

  final SaveDraftUseCase _saveDraftUseCase;
  final GenerateDraftUseCaseFactory _generateDraftUseCaseFactory;
  final ModelExecutionProfileService _modelExecutionProfileService;
  final ConversationSessionStateService _conversationSessionStateService;
  final ConversationStreamingStateService _conversationStreamingStateService;
  final ConversationGuideViewDataService _conversationGuideViewDataService;
  final ConversationUserVisibleTextService _conversationUserVisibleTextService;
  final WorkbenchPrimaryActionService _workbenchPrimaryActionService;
  final UserOptionPromptBuilderService _userOptionPromptBuilderService;
  final LoadModeGuidanceStateUseCase _loadModeGuidanceStateUseCase;
  final AnswerModeGuidanceStageUseCase _answerModeGuidanceStageUseCase;
  final BuildModeGuidancePlanInputUseCase _buildModeGuidancePlanInputUseCase;
  final ModeGuidanceTransitionService _modeGuidanceTransitionService;
  final ProjectWorkflowRuntimeService _workflowRuntimeService;
  final WorkbenchWorkspaceController _workspaceController;
  final WorkbenchConversationRuntimeState Function() _readRuntimeState;
  final void Function(WorkbenchConversationRuntimeState state) _writeRuntimeState;
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
  final void Function() _refreshSettingsViewData;
  final ThemeMode Function() _readThemeMode;
  final void Function(ThemeMode themeMode) _writeThemeMode;
  final void Function() _notifyShell;
  final Future<void> Function() _showSettings;
  final JsonMap Function(AppSettings settings) _contextStrategySettingsOf;
  final ProviderEndpointSettings? Function(AppSettings settings)
  _selectedModelProvider;
  final String Function(AppSettings settings) _agentLabel;
  final void Function(String message) _announce;

  void resetRuntimeState() {
    // 中文注释: 切换项目时会话运行时状态必须整体重置，避免旧项目会话残留继续投影到新工作区。
    _writeRuntimeState(const WorkbenchConversationRuntimeState());
  }

  WorkbenchViewData applyConversationState(
    WorkbenchViewData base, {
    String? contextSummaryOverride,
  }) {
    // 中文注释: 会话视图投影统一在这里完成，避免壳层和工作区各自手拼右栏状态。
    final runtimeState = _readRuntimeState();
    final activeState = _activeConversationState();
    final guide = _conversationGuideViewDataService.build(
      projectType: _workspaceController.currentProject?.projectType ?? 'novel',
      needsGoalSelection: _needsGoalSelection(activeState),
      isGenerating: base.isGenerating,
      guideScope: runtimeState.guideScope,
      modeGuidanceState: runtimeState.activeModeGuidanceState,
    );
    return base.copyWith(
      workflowTitle: guide.workflowTitle,
      workflowDescription: guide.workflowDescription,
      composerHint: guide.composerHint,
      primaryActions: guide.primaryActions,
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
  void onAgentSelected(String agentId) {
    // 中文注释: 智能体切换只更新默认 agent 绑定，不在 UI 层直接拼角色正文。
    final settings = _readSettings();
    final cleanAgentId = agentId.trim();
    if (settings == null || cleanAgentId.isEmpty) {
      return;
    }
    final updated = settings.copyWith(defaultAgentId: cleanAgentId);
    _persistSettings(updated, successMessage: '已切换智能体：${_agentLabel(updated)}');
  }

  @override
  void onQuickThemeRequested() {
    // 中文注释: 快速主题切换只改应用外观状态，业务 core 不感知这类界面偏好。
    final nextThemeMode = _readThemeMode() == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    _writeThemeMode(nextThemeMode);
    _refreshSettingsViewData();
    _notifyShell();
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
      runtimeState.copyWith(showSessionHistory: !runtimeState.showSessionHistory),
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
        current.copyWith(
          generationStatus: '已创建新会话，请先选择一个入口，或直接输入第一句话。',
        ),
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
      visibleText: _conversationUserVisibleTextService.textForUserOption(option),
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
    final executionProfile = _modelExecutionProfileService.resolve(
      settings: settings,
      provider: provider,
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
    _writeRuntimeState(
      _readRuntimeState().copyWith(
        showSessionHistory: false,
        guideScope: '',
        activeModeGuidanceState: null,
      ),
    );
    _mutateWorkbench(
      (current) => applyConversationState(
        current.copyWith(
          isGenerating: true,
          generationStatus: '正在请求 ${provider.title} 生成草稿...',
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
    void handleProgress(DraftGenerationProgress progress) {
      final streamingState = _conversationStreamingStateService
          .stateWithProgress(userPromptState, progress);
      _replaceConversationSession(streamingState, activate: true);
      _mutateWorkbench(
        (current) => applyConversationState(
          current.copyWith(
            isGenerating: true,
            generationStatus: _streamingGenerationStatus(provider, progress),
            toolCoreStatus: progress.pendingToolCalls.isNotEmpty ? '正在调用工具' : '',
          ),
          contextSummaryOverride: _conversationSummary(
            streamingState,
            fallback: '正在接收模型输出',
          ),
        ),
      );
    }

    try {
      final useCase = _generateDraftUseCaseFactory(
        provider,
        settings.networkSettings,
      );
      final result = await useCase.execute(
        project: project,
        userPrompt: cleanText,
        modelId: resolvedModelId,
        title: title,
        sessionContext: sessionContext,
        requestOptions: _mapValue(executionProfile['request_options']),
        contextSettings: contextStrategySettings,
        modelProfile: runtimeProfile,
        activeDocumentPath: _workspaceController.activeDocumentPath,
        activeDocumentBody: _workspaceController.activeDocumentBody,
        onProgress: handleProgress,
      );
      final assistantState = _conversationSessionStateService
          .stateWithAssistantResult(
            userPromptState,
            result,
            strategySettings: contextStrategySettings,
            modelProfile: runtimeProfile,
          );
      _replaceConversationSession(assistantState, activate: true);
      var savedPath = result.writtenPaths.isEmpty ? '' : result.writtenPaths.first;
      if (savedPath.isEmpty &&
          settings.autoSaveDrafts &&
          !result.waitingForUserChoice &&
          result.draftMarkdown.trim().isNotEmpty) {
        savedPath = await _saveDraftUseCase.execute(
          project: project,
          content: result.draftMarkdown,
          title: title,
        );
      }
      final selectedResourcePath = savedPath.isEmpty
          ? _workspaceController.activeDocumentPath
          : savedPath;
      final shouldReloadResources =
          savedPath.isNotEmpty ||
          result.writtenPaths.isNotEmpty ||
          result.changedPaths.isNotEmpty;
      final resourceEntries = shouldReloadResources
          ? await _workspaceController.reloadResourceEntries(
              selectedId: selectedResourcePath,
            )
          : _workspaceController.applyWorkbenchState(_readWorkbench()).resourceEntries;
      final resolvedBody = await _workspaceController.resolvedDocumentBody(
        project: project,
        generatedMarkdown: result.draftMarkdown,
        relativePath: savedPath,
      );
      final hasDocumentContent = resolvedBody.trim().isNotEmpty;
      if (hasDocumentContent) {
        _workspaceController.openOrActivateDocument(
          relativePath: savedPath,
          title: title.isEmpty ? '新草稿' : title,
          content: resolvedBody,
        );
      }
      _mutateWorkbench(
        (current) => applyConversationState(
          _workspaceController.applyWorkbenchState(
            current.copyWith(
              resourceEntries: resourceEntries,
              modelLabel: '${provider.title} · ${result.modelId}',
              contextSummary: _resultContextSummary(result, assistantState),
              generationStatus: _generationStatusFor(result, savedPath),
              toolCoreStatus: result.waitingForUserChoice ? '等待选择' : '',
              isGenerating: false,
            ),
          ),
        ),
      );
    } catch (error) {
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
  }

  Future<bool> _handleGuideNavigationAction(
    PrimaryActionViewData action,
  ) async {
    // 中文注释: 工作流细分页导航只切换引导状态，不直接触发模型调用。
    final runtimeState = _readRuntimeState();
    switch (action.commandId.trim()) {
      case 'guide.open_long_task_modes':
        _writeRuntimeState(
          runtimeState.copyWith(
            guideScope: 'long_task_modes',
            activeModeGuidanceState: null,
            showSessionHistory: false,
          ),
        );
        _mutateWorkbench((current) => applyConversationState(current));
        return true;
      case 'guide.open_mode_guidance':
        final project = _workspaceController.currentProject;
        if (project == null) {
          _announce('请先创建或打开长篇项目。');
          return true;
        }
        final modeId = _stringValue(
          action.payload['mode'],
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
        return true;
      case 'guide.create_workflow_from_mode_guidance':
        final project = _workspaceController.currentProject;
        if (project == null) {
          _announce('请先创建或打开长篇项目。');
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
      case 'guide.back.default':
        _writeRuntimeState(
          runtimeState.copyWith(
            guideScope: '',
            activeModeGuidanceState: null,
            showSessionHistory: false,
          ),
        );
        _mutateWorkbench((current) => applyConversationState(current));
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
      _announce(_resultMessage(result, success: '长任务队列已根据模式引导生成。'));
    } catch (error) {
      _announce('根据模式引导生成长任务队列失败：$error');
    } finally {
      _mutateWorkbench((current) => applyConversationState(current));
    }
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

  String _conversationSummary(
    ConversationSessionState? state, {
    required String fallback,
  }) {
    if (state == null || state.entries.isEmpty) {
      return fallback;
    }
    final summary = _conversationSessionStateService.publicSummary(state).trim();
    return summary.isEmpty ? fallback : summary;
  }

  bool _needsGoalSelection(ConversationSessionState? state) {
    return state == null
        ? true
        : _boolValue(state.sessionRecord['needs_goal_selection']);
  }

  RetryRequestViewData? _retryRequestViewData(
    ConversationRetryRequest? retryRequest,
  ) {
    if (retryRequest == null) {
      return null;
    }
    return RetryRequestViewData(
      label: '重试上次失败请求',
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
    if (result.stoppedByToolError) {
      final errorSummary = result.toolErrorSummary.trim();
      return errorSummary.isEmpty ? '工具执行失败。' : '工具执行失败：$errorSummary';
    }
    if (result.waitingForUserChoice) {
      return '智能体需要你先确认下一步选项。';
    }
    if (savedPath.isNotEmpty) {
      return '草稿生成完成，并已保存到 $savedPath';
    }
    if (result.draftMarkdown.trim().isNotEmpty) {
      return '草稿生成完成，尚未保存到项目目录。';
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

  String _titleFromPrompt(String prompt) {
    final lines = prompt
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty);
    if (lines.isEmpty) {
      return '新草稿';
    }
    final firstLine = lines.first;
    return firstLine.length <= 24 ? firstLine : '${firstLine.substring(0, 24)}...';
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
