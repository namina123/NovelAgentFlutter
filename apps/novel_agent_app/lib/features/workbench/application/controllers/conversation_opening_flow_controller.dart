part of 'workbench_conversation_controller.dart';

class ConversationOpeningFlowController {
  ConversationOpeningFlowController(this._controller);

  final WorkbenchConversationController _controller;

  void onModelSelected(String modelId) {
    // 中文注释: 顶部模型切换继续写回共享设置，保证 GUI/CLI 默认模型配置一致。
    final settings = _controller._readSettings();
    final cleanModelId = modelId.trim();
    if (settings == null || cleanModelId.isEmpty) {
      return;
    }
    final updated = settings.copyWith(
      defaultModelId: cleanModelId,
      extraSettings: <String, Object?>{
        ...settings.extraSettings,
        'model_settings': <String, Object?>{
          ..._controller._modelSettingsOf(settings),
          'model_id': cleanModelId,
        },
      },
    );
    _controller._persistSettings(
      updated,
      successMessage: '已切换模型：$cleanModelId',
    );
  }

  void onAgentGroupSelected(String groupId) {
    // 中文注释: 会话栏与 opening 面板共用同一条项目默认组切换链，保证 group-first 事实源只有一处。
    unawaited(_controller._selectOpeningAgentGroup(groupId));
  }

  void onConversationAgentSelected(String agentId) {
    final cleanAgentId = agentId.trim();
    if (cleanAgentId.isEmpty) {
      return;
    }
    _controller._mutateWorkbench(
      (current) => _controller.applyConversationState(
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
    await _controller._selectOpeningAgentGroup(groupId);
  }

  void onQuickThemeRequested() async {
    // 中文注释: 快速主题切换直接复用正式主题偏好写盘链，避免工作台和设置页出现两套主题事实源。
    final settings = _controller._readSettings();
    if (settings == null) {
      return;
    }
    final nextThemeId = _controller._themePreferenceResolver.quickToggleThemeId(
      _controller._readThemeId(),
    );
    final updated = settings.copyWith(
      themeSettings: _controller._themePreferenceResolver
          .payloadForSelectedTheme(
            selectedThemeId: nextThemeId,
            base: settings.themeSettings,
          ),
    );
    await _controller._saveSettingsSilently(updated);
    _controller._refreshSettingsViewData();
    _controller._notifyShell();
    _controller._announce(
      '已切换主题：${_controller._themePreferenceResolver.labelOf(nextThemeId)}',
    );
  }

  void onScreenModeRequested() {
    // 中文注释: 会话/文档切换只改工作台显示态，不重载项目和文档内容。
    final nextVisible = !_controller._readWorkbench().isDocumentsWorkspaceVisible;
    _controller._mutateWorkbench(
      (current) => _controller.applyConversationState(
        current.copyWith(
          isDocumentsWorkspaceVisible: nextVisible,
          generationStatus: nextVisible ? '已切到文档视图。' : '已切回会话视图。',
        ),
      ),
    );
  }

  void onDocumentsWorkspaceRequested() {
    // 中文注释: 窄屏文档入口只切换显示状态，不自行拼装工作台其他面板。
    _controller._mutateWorkbench(
      (current) => _controller.applyConversationState(
        current.copyWith(isDocumentsWorkspaceVisible: true),
      ),
    );
  }

  void onDocumentsWorkspaceDismissRequested() {
    // 中文注释: 文档工作区关闭只恢复会话视图，不改会话内容和项目状态。
    _controller._mutateWorkbench(
      (current) => _controller.applyConversationState(
        current.copyWith(isDocumentsWorkspaceVisible: false),
      ),
    );
  }

  void onHistoryRequested() {
    // 中文注释: 历史面板切换只改当前会话视图投影，不触碰会话底层记录。
    final runtimeState = _controller._readRuntimeState();
    _controller._writeRuntimeState(
      runtimeState.copyWith(
        showSessionHistory: !runtimeState.showSessionHistory,
      ),
    );
    _controller._mutateWorkbench(
      (current) => _controller.applyConversationState(current),
    );
  }

  void onNewSessionRequested() {
    // 中文注释: 新会话只重置交互链，不影响当前项目工作区和已打开文档。
    final activeState = _controller._activeConversationState();
    if (activeState != null &&
        activeState.entries.isEmpty &&
        _controller._needsGoalSelection(activeState)) {
      _controller._writeRuntimeState(
        _controller._readRuntimeState().copyWith(showSessionHistory: false),
      );
      _controller._mutateWorkbench(
        (current) => _controller.applyConversationState(
          current.copyWith(generationStatus: '当前已经是一个待选择目标的新会话。'),
        ),
      );
      unawaited(
        _controller._refreshOpeningProjection(
          activeState: activeState,
          forceReloadModeGuidance: false,
        ),
      );
      return;
    }
    final session = _controller._createConversationSession();
    _controller._replaceConversationSession(session, activate: true);
    _controller._writeRuntimeState(
      _controller._readRuntimeState().copyWith(
        showSessionHistory: false,
        guideScope: '',
        activeModeGuidanceState: null,
      ),
    );
    _controller._mutateWorkbench(
      (current) => _controller.applyConversationState(
        current.copyWith(
          generationStatus: '已创建新会话，请先选择一个入口，或直接输入第一句话。',
        ),
      ),
    );
    unawaited(
      _controller._refreshOpeningProjection(
        activeState: session,
        forceReloadModeGuidance: true,
      ),
    );
  }

  void onSessionHistorySelected(String sessionId) {
    // 中文注释: 历史切换只改变活动会话指针，不让页面直接操作会话记录结构。
    final runtimeState = _controller._readRuntimeState();
    final exists = runtimeState.sessions.any(
      (state) => _controller._sessionIdOf(state) == sessionId,
    );
    if (!exists) {
      return;
    }
    _controller._writeRuntimeState(
      runtimeState.copyWith(
        activeSessionId: sessionId,
        showSessionHistory: false,
        guideScope: '',
      ),
    );
    _controller._scheduleSessionPersistence();
    _controller._mutateWorkbench(
      (current) => _controller.applyConversationState(
        current.copyWith(generationStatus: '已切换到所选历史会话。'),
      ),
    );
    unawaited(
      _controller._refreshOpeningProjection(
        activeState: _controller._activeConversationState(),
        forceReloadModeGuidance: false,
      ),
    );
  }

  void onConversationSettingsRequested() {
    // 中文注释: 会话栏设置入口直接复用全局设置页，不再长一套局部设置状态。
    _controller._showSettings();
  }

  Future<void> onPrimaryActionRequested(String actionId) async {
    // 中文注释: 主动作计划在独立服务中解析，控制器只负责执行对应的三类结果。
    PrimaryActionViewData? action;
    for (final item in _controller._readWorkbench().primaryActions) {
      if (item.id == actionId) {
        action = item;
        break;
      }
    }
    if (action == null) {
      _controller._announce('未找到对应的工作流入口。');
      return;
    }
    if (await _controller._handleGuideNavigationAction(action)) {
      return;
    }
    if (await _controller._handleDeterministicLongTaskPrimaryAction(action)) {
      return;
    }
    final plan = _controller._workbenchPrimaryActionService.build(
      action: action,
      project: _controller._workspaceController.currentProjectInfo(),
      activeDocumentPath: _controller._workspaceController.activeDocumentPath,
      activeDocumentBody: _controller._workspaceController.activeDocumentBody,
    );
    switch (plan.kind) {
      case WorkbenchPrimaryActionPlanKind.refreshProject:
        _controller._workspaceController.onRefreshFilesRequested();
        return;
      case WorkbenchPrimaryActionPlanKind.announce:
        _controller._announce(plan.message);
        return;
      case WorkbenchPrimaryActionPlanKind.sendPrompt:
        await _controller._startPrimaryActionPrompt(
          plan,
          userVisibleText: _controller._conversationUserVisibleTextService
              .textForPrimaryAction(action, plan),
        );
        return;
    }
  }
}
