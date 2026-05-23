import 'package:flutter/material.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../features/agent_ecosystem/presentation/contracts/agent_ecosystem_action_handler.dart';
import '../../features/settings/presentation/contracts/settings_action_handler.dart';
import '../../features/settings/presentation/models/settings_view_data.dart';
import '../../features/workbench/application/models/conversation_session_state.dart';
import '../../features/workbench/application/models/workbench_primary_action_plan.dart';
import '../../features/workbench/application/services/conversation_session_state_service.dart';
import '../../features/workbench/application/services/conversation_guide_view_data_service.dart';
import '../../features/workbench/application/services/project_launcher_view_data_service.dart';
import '../../features/workbench/application/services/workbench_primary_action_service.dart';
import '../../features/workbench/presentation/contracts/conversation_action_handler.dart';
import '../../features/workbench/presentation/contracts/document_workspace_action_handler.dart';
import '../../features/workbench/presentation/contracts/resource_manager_action_handler.dart';
import '../../features/workbench/presentation/models/project_launcher_view_data.dart';
import '../../features/workbench/presentation/models/project_create_request_view_data.dart';
import '../../features/workbench/presentation/models/user_option_view_data.dart';
import '../../features/workbench/presentation/models/workbench_view_data.dart';
import '../../shared/view_models/app_shell_view_model.dart';
import '../routing/app_destination.dart';

typedef GenerateDraftUseCaseFactory =
    GenerateDraftUseCase Function(ProviderEndpointSettings provider);

class AppShellController extends ChangeNotifier
    implements
        ResourceManagerActionHandler,
        DocumentWorkspaceActionHandler,
        ConversationActionHandler,
        SettingsActionHandler,
        AgentEcosystemActionHandler {
  AppShellController({
    required SettingsRepository settingsRepository,
    required LoadProjectWorkspaceUseCase loadProjectWorkspaceUseCase,
    required ReadProjectFileUseCase readProjectFileUseCase,
    required SaveDraftUseCase saveDraftUseCase,
    required CreateProjectWorkspaceUseCase createProjectWorkspaceUseCase,
    required DiscoverProjectsUseCase discoverProjectsUseCase,
    required String settingsRootPath,
    required List<String> settingsSearchRoots,
    required String defaultProjectsRootPath,
    required bool isMobileProjectRootLocked,
    required GenerateDraftUseCaseFactory generateDraftUseCaseFactory,
    ConversationSessionStateService? conversationSessionStateService,
    ConversationGuideViewDataService? conversationGuideViewDataService,
    ProjectLauncherViewDataService? projectLauncherViewDataService,
    WorkbenchPrimaryActionService? workbenchPrimaryActionService,
    UserOptionPromptBuilderService? userOptionPromptBuilderService,
  }) : _settingsRepository = settingsRepository,
       _loadProjectWorkspaceUseCase = loadProjectWorkspaceUseCase,
       _readProjectFileUseCase = readProjectFileUseCase,
       _saveDraftUseCase = saveDraftUseCase,
       _createProjectWorkspaceUseCase = createProjectWorkspaceUseCase,
       _discoverProjectsUseCase = discoverProjectsUseCase,
       _settingsRootPath = settingsRootPath,
       _settingsSearchRoots = List<String>.unmodifiable(settingsSearchRoots),
       _defaultProjectsRootPath = defaultProjectsRootPath,
       _isMobileProjectRootLocked = isMobileProjectRootLocked,
       _generateDraftUseCaseFactory = generateDraftUseCaseFactory,
       _conversationSessionStateService =
           conversationSessionStateService ?? ConversationSessionStateService(),
       _conversationGuideViewDataService =
           conversationGuideViewDataService ??
           ConversationGuideViewDataService(),
       _projectLauncherViewDataService =
           projectLauncherViewDataService ?? ProjectLauncherViewDataService(),
       _workbenchPrimaryActionService =
           workbenchPrimaryActionService ?? WorkbenchPrimaryActionService(),
       _userOptionPromptBuilderService =
           userOptionPromptBuilderService ?? UserOptionPromptBuilderService(),
       _viewModel = AppShellViewModel.initial();

  final SettingsRepository _settingsRepository;
  final LoadProjectWorkspaceUseCase _loadProjectWorkspaceUseCase;
  final ReadProjectFileUseCase _readProjectFileUseCase;
  final SaveDraftUseCase _saveDraftUseCase;
  final CreateProjectWorkspaceUseCase _createProjectWorkspaceUseCase;
  final DiscoverProjectsUseCase _discoverProjectsUseCase;
  final String _settingsRootPath;
  final List<String> _settingsSearchRoots;
  final String _defaultProjectsRootPath;
  final bool _isMobileProjectRootLocked;
  final GenerateDraftUseCaseFactory _generateDraftUseCaseFactory;
  final ConversationSessionStateService _conversationSessionStateService;
  final ConversationGuideViewDataService _conversationGuideViewDataService;
  final ProjectLauncherViewDataService _projectLauncherViewDataService;
  final WorkbenchPrimaryActionService _workbenchPrimaryActionService;
  final UserOptionPromptBuilderService _userOptionPromptBuilderService;

  AppShellViewModel _viewModel;
  AppSettings? _settings;
  ProjectDescriptor? _currentProject;
  List<ConversationSessionState> _conversationSessions =
      const <ConversationSessionState>[];
  String _activeSessionId = '';
  bool _showSessionHistory = false;
  ThemeMode _themeMode = ThemeMode.light;
  bool _disposed = false;
  bool _initialized = false;

  AppShellViewModel get viewModel => _viewModel;
  ThemeMode get themeMode => _themeMode;

  Future<void> initialize() async {
    // 中文注释: 控制器初始化负责加载默认设置和项目，但不会把适配器实例化逻辑带进状态层。
    if (_initialized) {
      return;
    }
    _initialized = true;
    _updateWorkbench(
      _viewModel.workbench.copyWith(
        generationStatus: '正在加载设置...',
        toolCoreStatus: '',
      ),
    );
    try {
      final settings = await _settingsRepository.load();
      _settings = settings;
      _themeMode = _themeModeFromSettings(settings);
      _viewModel = _viewModel.copyWith(
        settings: _settingsViewDataFrom(settings),
        workbench: _viewModel.workbench.copyWith(
          modelLabel: _defaultModelLabel(settings),
          agentLabel: _agentLabel(settings),
          toolCoreStatus: '',
        ),
      );
      _safeNotifyListeners();
      await _loadDefaultProject();
    } catch (error) {
      _updateWorkbench(
        _viewModel.workbench.copyWith(
          generationStatus: '初始化失败：$error',
          toolCoreStatus: '',
        ),
      );
    }
  }

  void showWorkbench() {
    // 中文注释: 该方法统一负责切回主工作台，避免页面自己决定全局导航状态。
    _viewModel = _viewModel.copyWith(destination: AppDestination.workbench);
    _safeNotifyListeners();
  }

  void showSettings() {
    // 中文注释: 该方法统一负责切换到设置页，让设置入口不再分散在多个组件内部。
    _viewModel = _viewModel.copyWith(destination: AppDestination.settings);
    _safeNotifyListeners();
  }

  void showAgentEcosystem() {
    // 中文注释: 该方法统一负责切换到智能体生态页，避免资源面板和会话面板各自维护路由。
    _viewModel = _viewModel.copyWith(
      destination: AppDestination.agentEcosystem,
    );
    _safeNotifyListeners();
  }

  @override
  void onModelSettingsRequested() {
    // 中文注释: 资源管理器的模型按钮直接跳到设置页，但不接触设置页内部状态。
    showSettings();
  }

  @override
  void onCreateProjectRequested() async {
    // 中文注释: 新建项目入口先拉起创建面板，让创建标题和后续模板扩展都能挂在同一交互壳里。
    await _showProjectLauncher(ProjectLauncherMode.create);
  }

  @override
  void onOpenProjectRequested() {
    // 中文注释: 打开项目入口统一走默认项目根目录扫描，移动端与桌面端都不需要直接暴露系统文件夹。
    _showProjectLauncher(ProjectLauncherMode.open);
  }

  @override
  void onProjectLauncherDismissed() {
    // 中文注释: 项目启动弹层的关闭只重置工作台上的弹层状态，不触碰当前项目本身。
    _updateWorkbench(_viewModel.workbench.copyWith(projectLauncher: null));
  }

  @override
  void onProjectLauncherRefreshRequested() async {
    // 中文注释: 打开项目面板的刷新只重扫默认项目根，不让面板自己直接碰文件系统。
    final launcher = _viewModel.workbench.projectLauncher;
    if (launcher == null) {
      return;
    }
    await _showProjectLauncher(
      launcher.mode,
      status: launcher.mode == ProjectLauncherMode.open
          ? '项目列表已刷新。'
          : launcher.status,
    );
  }

  @override
  void onProjectEntryOpened(String projectPath) async {
    // 中文注释: 选择项目条目后直接切换工作区，并关闭项目弹层。
    _updateWorkbench(
      _viewModel.workbench.copyWith(
        projectLauncher: null,
        generationStatus: '正在打开项目...',
      ),
    );
    await _loadProject(projectPath);
  }

  @override
  void onProjectCreationSubmitted(ProjectCreateRequestViewData request) async {
    // 中文注释: 创建项目的真正副作用统一收口在这里，弹层只负责收集用户输入。
    final cleanTitle = request.title.trim();
    final projectTypeId = request.projectTypeId.trim().isEmpty
        ? 'novel'
        : request.projectTypeId.trim();
    _updateWorkbench(
      _withConversationState(
        _viewModel.workbench.copyWith(
          projectLauncher: _projectLauncherViewDataService.build(
            mode: ProjectLauncherMode.create,
            projectsRootPath: _defaultProjectsRootPath,
            projects: const <JsonMap>[],
            status: '正在创建项目：${cleanTitle.isEmpty ? '未命名项目' : cleanTitle}',
            selectedProjectTypeId: projectTypeId,
          ),
        ),
      ),
    );
    try {
      final project = await _createProjectWorkspaceUseCase.execute(
        projectsRootPath: _defaultProjectsRootPath,
        title: cleanTitle,
        projectType: projectTypeId,
      );
      _updateWorkbench(_viewModel.workbench.copyWith(projectLauncher: null));
      await _loadProject(project.rootPath);
      _announce('已创建并打开新项目：${project.name}');
    } catch (error) {
      await _showProjectLauncher(
        ProjectLauncherMode.create,
        status: '创建项目失败：$error',
      );
    }
  }

  @override
  void onEditProjectInfoRequested() {
    // 中文注释: 项目信息入口先只暴露动作，具体弹窗与持久化后续接用例。
    debugPrint('TODO: edit project info');
  }

  @override
  void onRefreshFilesRequested() {
    // 中文注释: 刷新动作统一重载当前项目工作区，避免资源树自己直接接文件系统。
    if (_currentProject != null) {
      _loadProject(_currentProject!.rootPath);
      return;
    }
    _loadDefaultProject();
  }

  @override
  void onCreateFileRequested() {
    // 中文注释: 新建文件属于项目操作，不应直接在组件里自写逻辑。
    debugPrint('TODO: create file');
  }

  @override
  void onCreateFolderRequested() {
    // 中文注释: 新建文件夹动作先经过统一控制器，后续再接项目仓储用例。
    debugPrint('TODO: create folder');
  }

  @override
  void onImportRequested() {
    // 中文注释: 导入动作只留接口，后续可以分别接桌面和移动端的权限流。
    debugPrint('TODO: import files');
  }

  @override
  void onCreateChapterRequested() {
    // 中文注释: 当前阶段先引导用户通过发送提示词生成草稿，章节显式创建后续再接表单流程。
    _announce('直接在右侧输入章节需求并发送，当前版本会自动保存到 drafts/。');
  }

  @override
  void onSaveCurrentRequested() {
    // 中文注释: 当前保存逻辑只处理已经载入的活动草稿，避免工具栏自己碰文件路径规则。
    _saveCurrentDocument();
  }

  @override
  void onAgentEcosystemRequested() {
    // 中文注释: 左侧快捷入口统一跳转到生态页，保持工作台与生态页解耦。
    showAgentEcosystem();
  }

  @override
  void onTasksRequested() {
    // 中文注释: 任务中心当前只保留接口，后续会接独立页面或抽屉。
    debugPrint('TODO: open tasks');
  }

  @override
  void onReviewsRequested() {
    // 中文注释: 审稿页当前只保留接口，不在工作台内直接落重逻辑。
    debugPrint('TODO: open reviews');
  }

  @override
  void onTemplatesRequested() {
    // 中文注释: 模板页当前只留导航接口，后续接独立 feature 页面。
    debugPrint('TODO: open templates');
  }

  @override
  void onResourceEntrySelected(String entryId) {
    // 中文注释: 资源树点击统一走读取用例，保持文件打开逻辑脱离具体组件。
    _openResource(entryId);
  }

  @override
  void onDocumentActionRequested(DocumentToolbarAction action) {
    // 中文注释: 文档工具栏目前只接入可用的保存行为，其余动作先回传状态提示保持边界清晰。
    switch (action) {
      case DocumentToolbarAction.save:
        _saveCurrentDocument();
        break;
      case DocumentToolbarAction.preview:
        _announce('当前正文区已经是可复制预览态，编辑器与双栏预览后续继续接。');
        break;
      case DocumentToolbarAction.outline:
        _announce('结构视图尚未接入，当前可通过资源树直接查看大纲与章纲文件。');
        break;
      case DocumentToolbarAction.review:
        _announce('审稿工作流核心已在迁移中，GUI 审稿入口会在下一阶段接上。');
        break;
    }
  }

  @override
  void onQuickThemeRequested() {
    // 中文注释: 快速主题先在浅色和夜间模式之间切换，后续更细的主题设置仍可挂到同一状态入口。
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    _refreshSettingsViewData();
    _safeNotifyListeners();
  }

  @override
  void onScreenModeRequested() {
    // 中文注释: 屏幕模式切换属于宿主体验动作，当前 UI 层只暴露事件。
    debugPrint('TODO: screen mode');
  }

  @override
  void onDocumentsWorkspaceRequested() {
    // 中文注释: 窄屏或双栏模式下，文档工作区通过统一状态切换进入，避免会话栏自己直接装配其他面板。
    _updateWorkbench(
      _withConversationState(
        _viewModel.workbench.copyWith(isDocumentsWorkspaceVisible: true),
      ),
    );
  }

  @override
  void onDocumentsWorkspaceDismissRequested() {
    // 中文注释: 返回会话时只切回工作台视图状态，不重载项目和文档内容。
    _updateWorkbench(
      _withConversationState(
        _viewModel.workbench.copyWith(isDocumentsWorkspaceVisible: false),
      ),
    );
  }

  @override
  void onHistoryRequested() {
    // 中文注释: 历史按钮只切换面板显隐，不把会话列表逻辑散落到多个子控件里。
    _showSessionHistory = !_showSessionHistory;
    _updateWorkbench(_withConversationState(_viewModel.workbench));
  }

  @override
  void onNewSessionRequested() {
    // 中文注释: 新会话只重置交互链，不影响项目工作区与已打开文档。
    final activeState = _activeConversationState();
    if (activeState != null &&
        activeState.entries.isEmpty &&
        _needsGoalSelection(activeState)) {
      _showSessionHistory = false;
      _updateWorkbench(
        _withConversationState(
          _viewModel.workbench.copyWith(generationStatus: '当前已经是一个待选择目标的新会话。'),
        ),
      );
      return;
    }
    final session = _createConversationSession();
    _replaceConversationSession(session, activate: true);
    _showSessionHistory = false;
    _updateWorkbench(
      _withConversationState(
        _viewModel.workbench.copyWith(generationStatus: '已创建新会话，请先选择一个入口，或直接输入第一句话。'),
      ),
    );
  }

  @override
  void onSessionHistorySelected(String sessionId) {
    // 中文注释: 历史切换只改变活动会话指针，具体会话内容仍由会话状态服务维护。
    final exists = _conversationSessions.any(
      (state) => _sessionIdOf(state) == sessionId,
    );
    if (!exists) {
      return;
    }
    _activeSessionId = sessionId;
    _showSessionHistory = false;
    _updateWorkbench(
      _withConversationState(
        _viewModel.workbench.copyWith(generationStatus: '已切换到所选历史会话。'),
      ),
    );
  }

  @override
  void onUserOptionSelected(UserOptionViewData option) async {
    // 中文注释: 选项点击统一转换成补充提示词，再复用同一条发送链继续推进。
    final prompt = _userOptionPromptBuilderService.build(<String, Object?>{
      'label': option.label,
      'description': option.description,
      'prompt': option.prompt,
      '_source_question': option.sourceQuestion,
      '_all_options': option.allOptions,
    });
    await _sendPrompt(prompt);
  }

  @override
  void onConversationSettingsRequested() {
    // 中文注释: 会话栏顶部设置入口复用全局设置页，避免再生一套局部设置状态。
    showSettings();
  }

  @override
  void onPrimaryActionRequested(String actionId) {
    // 中文注释: 主动作执行计划交给独立服务解析，控制器只负责执行刷新、播报或发送三种结果。
    PrimaryActionViewData? action;
    for (final item in _viewModel.workbench.primaryActions) {
      if (item.id == actionId) {
        action = item;
        break;
      }
    }
    if (action == null) {
      _announce('未找到对应的工作流入口。');
      return;
    }
    final plan = _workbenchPrimaryActionService.build(
      action: action,
      project: _currentProjectInfo(),
      activeDocumentPath: _viewModel.workbench.activeDocumentPath,
      activeDocumentBody: _viewModel.workbench.activeDocumentBody,
    );
    switch (plan.kind) {
      case WorkbenchPrimaryActionPlanKind.refreshProject:
        onRefreshFilesRequested();
        return;
      case WorkbenchPrimaryActionPlanKind.announce:
        _announce(plan.message);
        return;
      case WorkbenchPrimaryActionPlanKind.sendPrompt:
        _startPrimaryActionPrompt(plan);
        return;
    }
  }

  @override
  void onOptimizeRequested() {
    // 中文注释: 还没有单独提示词优化链路前，这里先给出轻量引导，避免空按钮体验。
    _announce('当前先直接发送自然语言需求；提示词优化链路后续会接独立用例。');
  }

  @override
  void onToolOptionsRequested() {
    // 中文注释: 工具选项按钮后续会接工具策略面板，当前只保留事件边界。
    debugPrint('TODO: tool options');
  }

  @override
  void onSendRequested(String text) async {
    // 中文注释: 发送动作统一复用同一条会话请求链，避免按钮发送与选项发送走出两套行为。
    await _sendPrompt(text);
  }

  Future<void> _sendPrompt(String text) async {
    // 中文注释: 真正的发送链在这里收口，统一处理会话状态写入、上下文渲染、生成和结果回放。
    final cleanText = text.trim();
    if (cleanText.isEmpty) {
      _announce('请输入创作需求后再发送。');
      return;
    }
    final settings = _settings;
    final project = _currentProject;
    if (settings == null || project == null) {
      _announce('默认项目尚未加载完成，请稍后再试。');
      return;
    }
    final provider = settings.defaultProvider();
    if (provider == null) {
      _announce('当前没有可用 provider 配置。');
      return;
    }
    final resolvedModelId = settings.defaultModelId.trim().isEmpty
        ? provider.modelId
        : settings.defaultModelId;
    if (provider.baseUrl.trim().isEmpty || resolvedModelId.trim().isEmpty) {
      _announce('请先在 novel_agent_settings.json 或环境变量里配置真实的模型接口地址和模型名。');
      return;
    }
    final title = _titleFromPrompt(cleanText);
    final activeState = _ensureConversationSession();
    final userPromptState = _conversationSessionStateService
        .stateWithUserPrompt(activeState, cleanText);
    _replaceConversationSession(userPromptState, activate: true);
    _showSessionHistory = false;
    _updateWorkbench(
      _withConversationState(
        _viewModel.workbench.copyWith(
          isGenerating: true,
          generationStatus: '正在请求 ${provider.title} 生成草稿...',
          toolCoreStatus: 'ToolCore: 共享草稿生成链路运行中',
        ),
        contextSummaryOverride: _conversationSummary(
          userPromptState,
          fallback: '上下文准备中 · 等待模型读取会话与项目信息',
        ),
      ),
    );
    final sessionContext = _conversationSessionStateService
        .sessionContextMarkdown(
          userPromptState,
          excludeLatestUserContent: cleanText,
        );
    try {
      final useCase = _generateDraftUseCaseFactory(provider);
      final result = await useCase.execute(
        project: project,
        userPrompt: cleanText,
        modelId: resolvedModelId,
        title: title,
        sessionContext: sessionContext,
      );
      final assistantState = _conversationSessionStateService
          .stateWithAssistantResult(userPromptState, result);
      _replaceConversationSession(assistantState, activate: true);
      var savedPath = result.writtenPaths.isEmpty
          ? ''
          : result.writtenPaths.first;
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
          ? _viewModel.workbench.activeDocumentPath
          : savedPath;
      final shouldReloadResources =
          savedPath.isNotEmpty ||
          result.writtenPaths.isNotEmpty ||
          result.changedPaths.isNotEmpty;
      final resourceEntries = shouldReloadResources
          ? await _reloadResourceEntries(selectedId: selectedResourcePath)
          : _markResourceSelection(
              _viewModel.workbench.resourceEntries,
              selectedId: selectedResourcePath,
            );
      final resolvedBody = await _resolvedDocumentBody(
        project: project,
        generatedMarkdown: result.draftMarkdown,
        relativePath: savedPath,
      );
      final hasDocumentContent = resolvedBody.trim().isNotEmpty;
      final nextWorkbench = _viewModel.workbench.copyWith(
        documents: hasDocumentContent
            ? _documentsFor(
                title: title.isEmpty ? '新草稿' : title,
                relativePath: savedPath,
              )
            : _viewModel.workbench.documents,
        resourceEntries: resourceEntries,
        modelLabel: '${provider.title} · ${result.modelId}',
        activeDocumentTitle: hasDocumentContent
            ? (title.isEmpty ? '新草稿' : title)
            : _viewModel.workbench.activeDocumentTitle,
        activeDocumentPath: hasDocumentContent
            ? savedPath
            : _viewModel.workbench.activeDocumentPath,
        activeDocumentBody: hasDocumentContent
            ? resolvedBody
            : _viewModel.workbench.activeDocumentBody,
        contextSummary: _resultContextSummary(result, assistantState),
        generationStatus: _generationStatusFor(result, savedPath),
        toolCoreStatus: result.waitingForUserChoice ? '等待选择' : '',
        isGenerating: false,
      );
      _updateWorkbench(_withConversationState(nextWorkbench));
    } catch (error) {
      final failedState = _conversationSessionStateService
          .stateWithAssistantFailure(userPromptState, '生成失败：$error');
      _replaceConversationSession(failedState, activate: true);
      _updateWorkbench(
        _withConversationState(
          _viewModel.workbench.copyWith(
            generationStatus: '生成失败：$error',
            toolCoreStatus: '',
            isGenerating: false,
          ),
        ),
      );
    }
  }

  @override
  void onSettingsBackRequested() {
    // 中文注释: 设置页关闭统一回到工作台，避免设置页内部依赖全局导航组件。
    showWorkbench();
  }

  @override
  void onSettingsTabSelected(String tabId) {
    // 中文注释: 设置页的 tab 切换只更新设置视图模型，不触碰其他页面状态。
    _refreshSettingsViewData(activeTabId: tabId);
    _safeNotifyListeners();
  }

  @override
  void onProviderSelected(String providerId) {
    // 中文注释: provider 选择只更新设置视图投影，不让详情面板自行维护重复状态。
    _refreshSettingsViewData(selectedProviderId: providerId);
    _safeNotifyListeners();
  }

  @override
  void onProviderSaved(Map<String, Object?> payload) {
    // 中文注释: provider 保存统一落到控制器，保证默认接口、选中状态和磁盘写入使用同一条链路。
    final settings = _settings;
    if (settings == null) {
      return;
    }
    final sourceId = _stringValue(payload['source_id']);
    final nextId = _stringValue(
      payload['id'],
      sourceId.trim().isEmpty ? 'provider_${DateTime.now().millisecondsSinceEpoch}' : sourceId,
    );
    final nextProvider = ProviderEndpointSettings(
      id: nextId,
      title: _stringValue(payload['title'], '新接口'),
      protocol: _stringValue(payload['protocol'], 'openai_compatible'),
      baseUrl: _stringValue(payload['base_url']),
      apiKey: _stringValue(payload['api_key']),
      modelId: _stringValue(payload['model_id']),
      description: _stringValue(payload['description']),
      isDefault: _boolValue(payload['is_default']),
    );
    final providers = <ProviderEndpointSettings>[];
    var replaced = false;
    for (final provider in settings.providers) {
      if (provider.id == sourceId && sourceId.trim().isNotEmpty) {
        providers.add(nextProvider);
        replaced = true;
        continue;
      }
      providers.add(
        provider.copyWith(
          isDefault: nextProvider.isDefault ? false : provider.isDefault,
        ),
      );
    }
    if (!replaced) {
      if (nextProvider.isDefault) {
        for (var index = 0; index < providers.length; index += 1) {
          providers[index] = providers[index].copyWith(isDefault: false);
        }
      }
      providers.add(nextProvider);
    }
    final updated = settings.copyWith(
      providers: providers,
      defaultProviderId:
          nextProvider.isDefault || settings.defaultProviderId == sourceId
          ? nextProvider.id
          : settings.defaultProviderId,
      defaultModelId: settings.defaultProviderId == sourceId &&
              settings.defaultModelId == _providerModelIdOf(settings, sourceId)
          ? nextProvider.modelId
          : settings.defaultModelId,
    );
    _persistSettings(
      updated,
      successMessage: '接口设置已保存。',
      selectedProviderId: nextProvider.id,
    );
  }

  @override
  void onProviderDeleted(String providerId) {
    // 中文注释: provider 删除前先在控制器里重建默认项，避免设置文件出现悬空默认接口 id。
    final settings = _settings;
    if (settings == null) {
      return;
    }
    final providers = settings.providers
        .where((provider) => provider.id != providerId)
        .toList(growable: false);
    if (providers.isEmpty) {
      _announce('至少需要保留一个接口配置。');
      return;
    }
    final fallbackDefault = providers.firstWhere(
      (provider) => provider.isDefault,
      orElse: () => providers.first.copyWith(isDefault: true),
    );
    final normalizedProviders = providers
        .map(
          (provider) => provider.copyWith(
            isDefault: provider.id == fallbackDefault.id,
          ),
        )
        .toList(growable: false);
    final updated = settings.copyWith(
      providers: normalizedProviders,
      defaultProviderId: settings.defaultProviderId == providerId
          ? fallbackDefault.id
          : settings.defaultProviderId,
    );
    _persistSettings(updated, successMessage: '接口已删除。');
  }

  @override
  void onModelSettingsSaved(Map<String, Object?> payload) {
    // 中文注释: 默认模型相关设置统一保存回 AppSettings，确保 GUI/CLI 读取到同一套默认值。
    final settings = _settings;
    if (settings == null) {
      return;
    }
    final updated = settings.copyWith(
      defaultProviderId: _stringValue(
        payload['default_provider_id'],
        settings.defaultProviderId,
      ),
      defaultModelId: _stringValue(
        payload['default_model_id'],
        settings.defaultModelId,
      ),
      defaultAgentId: _stringValue(
        payload['default_agent_id'],
        settings.defaultAgentId,
      ),
      autoSaveDrafts:
          payload['auto_save_drafts'] is bool
          ? payload['auto_save_drafts'] as bool
          : settings.autoSaveDrafts,
    );
    _persistSettings(updated, successMessage: '模型设置已保存。');
  }

  @override
  void onPermissionSettingsSaved(Map<String, Object?> payload) {
    final settings = _settings;
    if (settings == null) {
      return;
    }
    _persistSettings(
      settings.copyWith(permissionSettings: Map<String, Object?>.from(payload)),
      successMessage: '权限设置已保存。',
    );
  }

  @override
  void onToolStrategySettingsSaved(Map<String, Object?> payload) {
    final settings = _settings;
    if (settings == null) {
      return;
    }
    _persistSettings(
      settings.copyWith(
        toolStrategySettings: Map<String, Object?>.from(payload),
      ),
      successMessage: '工具策略已保存。',
    );
  }

  @override
  void onNetworkSettingsSaved(Map<String, Object?> payload) {
    final settings = _settings;
    if (settings == null) {
      return;
    }
    _persistSettings(
      settings.copyWith(networkSettings: Map<String, Object?>.from(payload)),
      successMessage: '网络设置已保存。',
    );
  }

  @override
  void onContextSettingsSaved(Map<String, Object?> payload) {
    final settings = _settings;
    if (settings == null) {
      return;
    }
    var nextProjectPath = settings.defaultProjectPath;
    if (!_isMobileProjectRootLocked) {
      nextProjectPath = _stringValue(
        payload['default_project_path'],
        settings.defaultProjectPath,
      );
    }
    final contextSettings = Map<String, Object?>.from(payload)
      ..remove('default_project_path');
    _persistSettings(
      settings.copyWith(
        defaultProjectPath: nextProjectPath,
        contextSettings: contextSettings,
      ),
      successMessage: '上下文设置已保存。',
    );
  }

  @override
  void onThemeSettingsSaved(Map<String, Object?> payload) {
    final settings = _settings;
    if (settings == null) {
      return;
    }
    final updated = settings.copyWith(
      themeSettings: Map<String, Object?>.from(payload),
    );
    _themeMode = _themeModeFromValue(_stringValue(payload['mode'], 'light'));
    _persistSettings(updated, successMessage: '主题设置已保存。');
  }

  @override
  void onAgentEcosystemBackRequested() {
    // 中文注释: 生态页关闭统一回到工作台，避免页内自己操作外层导航结构。
    showWorkbench();
  }

  @override
  void onEcosystemRefreshRequested() {
    // 中文注释: 生态刷新动作后续会由生态用例承接，当前只保留接口。
    debugPrint('TODO: refresh ecosystem');
  }

  @override
  void onImportEcosystemPackageRequested() {
    // 中文注释: 导入生态包需要文件选择和解析流程，当前 UI 先只保留边界。
    debugPrint('TODO: import ecosystem package');
  }

  @override
  void onGenerateIndexRequested() {
    // 中文注释: 生成索引属于较重的业务动作，当前不会写进 UI 页面的内部逻辑。
    debugPrint('TODO: generate index');
  }

  @override
  void onEcosystemTabSelected(String tabId) {
    // 中文注释: 生态页 tab 切换只改变本页视图模型，不跨页污染其他状态。
    _viewModel = _viewModel.copyWith(
      agentEcosystem: _viewModel.agentEcosystem.copyWith(activeTabId: tabId),
    );
    _safeNotifyListeners();
  }

  @override
  void onEcosystemEntrySelected(String entryId) {
    // 中文注释: 生态条目点击后续会接详情面板或编辑器，当前先保留统一接口。
    debugPrint('TODO: select ecosystem entry $entryId');
  }

  @override
  void onCreateAgentRequested() {
    // 中文注释: 创建智能体动作后续交给生态编辑用例，当前只暴露入口。
    debugPrint('TODO: create agent');
  }

  @override
  void onCreateSkillRequested() {
    // 中文注释: 创建技能动作保留给未来表单页处理，当前不把编辑逻辑写进生态列表页。
    debugPrint('TODO: create skill');
  }

  @override
  void onCreateSkillGroupRequested() {
    // 中文注释: 创建技能组动作只暴露接口，保持生态页轻量。
    debugPrint('TODO: create skill group');
  }

  @override
  void onCreateAgentGroupRequested() {
    // 中文注释: 创建智能体组动作只暴露接口，后续再接编辑表单。
    debugPrint('TODO: create agent group');
  }

  @override
  void dispose() {
    // 中文注释: 控制器销毁时标记生命周期状态，避免异步回调在组件已卸载后继续通知 UI。
    _disposed = true;
    super.dispose();
  }

  Future<void> _loadDefaultProject() async {
    // 中文注释: 默认项目加载走统一入口，这样设置仓储与工作区用例的边界始终稳定。
    final settings = _settings;
    if (settings == null) {
      return;
    }
    await _loadProject(settings.defaultProjectPath);
  }

  Future<void> _loadProject(String rootPath) async {
    // 中文注释: 项目加载统一负责刷新工作台基础信息，不让资源树和文档面板各自拼状态。
    _updateWorkbench(
      _viewModel.workbench.copyWith(
        generationStatus: '正在加载项目...',
        toolCoreStatus: '',
      ),
    );
    final snapshot = await _loadProjectWorkspaceUseCase.execute(rootPath);
    if (snapshot == null) {
      _currentProject = null;
      _refreshSettingsViewData();
      _updateWorkbench(
        _viewModel.workbench.copyWith(
          generationStatus: '未找到默认项目目录：$rootPath',
          toolCoreStatus: '',
        ),
      );
      return;
    }
    _currentProject = snapshot.project;
    _resetConversationSessions();
    var workbench = _viewModel.workbench.copyWith(
      projectName: snapshot.project.name,
      projectSubtitle: _projectSubtitleFor(snapshot.project.projectType),
      projectPath: snapshot.project.rootPath,
      toolCoreStatus: '',
      resourceEntries: _markResourceSelection(
        _resourceEntriesFrom(snapshot.entries),
        selectedId: '',
      ),
      contextSummary: '资源 ${snapshot.entries.length} 项',
      generationStatus: '',
      documents: const <DocumentTabViewData>[],
      activeDocumentTitle: '',
      activeDocumentPath: '',
      activeDocumentBody: '',
      conversationEntries: const [],
      pendingOptions: const [],
      subAgentRuns: const [],
      sessionHistoryEntries: const [],
      activeSessionId: '',
      showSessionHistory: false,
      isDocumentsWorkspaceVisible: false,
      projectLauncher: null,
      isGenerating: false,
    );
    final firstOpenable = _firstOpenablePath(snapshot.entries);
    if (firstOpenable.trim().isNotEmpty) {
      final content = await _readProjectFileUseCase.execute(
        snapshot.project,
        firstOpenable,
      );
      if (content != null && content.trim().isNotEmpty) {
        workbench = workbench.copyWith(
          documents: _documentsFor(
            title: _displayNameOf(firstOpenable),
            relativePath: firstOpenable,
          ),
          resourceEntries: _markResourceSelection(
            workbench.resourceEntries,
            selectedId: firstOpenable,
          ),
          activeDocumentTitle: _displayNameOf(firstOpenable),
          activeDocumentPath: firstOpenable,
          activeDocumentBody: content,
          generationStatus: '已打开 $firstOpenable',
        );
      }
    }
    _replaceConversationSession(_createConversationSession(), activate: true);
    _refreshSettingsViewData();
    _updateWorkbench(_withConversationState(workbench));
  }

  Future<void> _openResource(String relativePath) async {
    // 中文注释: 打开资源只处理文本文件，目录点击则只更新提示状态，不让 UI 猜测文件系统语义。
    final project = _currentProject;
    if (project == null) {
      _announce('项目尚未加载完成。');
      return;
    }
    final content = await _readProjectFileUseCase.execute(
      project,
      relativePath,
    );
    if (content == null) {
      _updateWorkbench(
        _viewModel.workbench.copyWith(
          resourceEntries: _markResourceSelection(
            _viewModel.workbench.resourceEntries,
            selectedId: relativePath,
          ),
          generationStatus: '已选中目录或非文本资源：$relativePath',
        ),
      );
      return;
    }
    _updateWorkbench(
      _viewModel.workbench.copyWith(
        documents: _documentsFor(
          title: _displayNameOf(relativePath),
          relativePath: relativePath,
        ),
        resourceEntries: _markResourceSelection(
          _viewModel.workbench.resourceEntries,
          selectedId: relativePath,
        ),
        activeDocumentTitle: _displayNameOf(relativePath),
        activeDocumentPath: relativePath,
        activeDocumentBody: content,
        generationStatus: '已打开 $relativePath',
      ),
    );
  }

  Future<void> _saveCurrentDocument() async {
    // 中文注释: 当前保存仅处理活动文档内容，保持工具栏行为与项目写入规则解耦。
    final project = _currentProject;
    final body = _viewModel.workbench.activeDocumentBody.trim();
    if (project == null || body.isEmpty) {
      _announce('当前没有可保存的草稿内容。');
      return;
    }
    try {
      final savedPath = await _saveDraftUseCase.execute(
        project: project,
        content: _viewModel.workbench.activeDocumentBody,
        title: _viewModel.workbench.activeDocumentTitle,
        relativePath: _viewModel.workbench.activeDocumentPath,
      );
      final resourceEntries = await _reloadResourceEntries(
        selectedId: savedPath,
      );
      _updateWorkbench(
        _viewModel.workbench.copyWith(
          activeDocumentPath: savedPath,
          documents: _documentsFor(
            title: _viewModel.workbench.activeDocumentTitle,
            relativePath: savedPath,
          ),
          resourceEntries: resourceEntries,
          generationStatus: '已保存到 $savedPath',
        ),
      );
    } catch (error) {
      _announce('保存失败：$error');
    }
  }

  Future<List<ResourceEntryViewData>> _reloadResourceEntries({
    required String selectedId,
  }) async {
    // 中文注释: 保存新草稿后重新拉取资源树，可以让 GUI 立刻反映项目目录的真实状态。
    final project = _currentProject;
    if (project == null) {
      return _viewModel.workbench.resourceEntries;
    }
    final snapshot = await _loadProjectWorkspaceUseCase.execute(
      project.rootPath,
    );
    if (snapshot == null) {
      return _viewModel.workbench.resourceEntries;
    }
    return _markResourceSelection(
      _resourceEntriesFrom(snapshot.entries),
      selectedId: selectedId,
    );
  }

  SettingsViewData _settingsViewDataFrom(
    AppSettings settings, {
    String? activeTabId,
    String? selectedProviderId,
  }) {
    // 中文注释: 设置页数据投影由控制器统一完成，避免展示层直接理解核心设置模型。
    final resolvedActiveTabId = activeTabId ?? _viewModel.settings.activeTabId;
    final effectiveProviderId =
        selectedProviderId ?? _selectedProviderId(settings);
    final providers = settings.providers
        .map(
          (provider) => ProviderEndpointViewData(
            id: provider.id,
            title: provider.title,
            protocol: provider.protocol,
            baseUrl: provider.baseUrl,
            modelId:
                provider.modelId.trim().isEmpty ? '未配置模型' : provider.modelId,
            rawApiKey: provider.apiKey,
            apiKeyState: provider.apiKey.trim().isEmpty ? '未配置密钥' : '已配置密钥',
            description: provider.description,
            isDefault:
                provider.id == settings.defaultProviderId || provider.isDefault,
            isSelected: provider.id == effectiveProviderId,
          ),
        )
        .toList(growable: false);
    return SettingsViewData(
      activeTabId: resolvedActiveTabId,
      tabs: const [
        SettingsTabViewData(id: 'interfaces', label: '接口'),
        SettingsTabViewData(id: 'models', label: '模型'),
        SettingsTabViewData(id: 'permissions', label: '权限'),
        SettingsTabViewData(id: 'tooling', label: '工具策略'),
        SettingsTabViewData(id: 'network', label: '网络'),
        SettingsTabViewData(id: 'context', label: '上下文'),
        SettingsTabViewData(id: 'theme', label: '主题'),
        SettingsTabViewData(id: 'dev', label: '开发'),
      ],
      providers: providers,
      tabSections: _settingsSections(settings),
      defaultProviderId: settings.defaultProviderId,
      defaultAgentId: settings.defaultAgentId,
      defaultModelId: settings.defaultModelId,
      defaultProjectPath: settings.defaultProjectPath,
      autoSaveDrafts: settings.autoSaveDrafts,
      permissionSettings: settings.permissionSettings,
      toolStrategySettings: settings.toolStrategySettings,
      networkSettings: settings.networkSettings,
      contextSettings: settings.contextSettings,
      themeSettings: settings.themeSettings,
      settingsRootPath: _settingsRootPath,
      settingsSearchRoots: _settingsSearchRoots,
      defaultProjectsRootPath: _defaultProjectsRootPath,
      isMobileProjectRootLocked: _isMobileProjectRootLocked,
    );
  }

  void _refreshSettingsViewData({
    String? activeTabId,
    String? selectedProviderId,
  }) {
    // 中文注释: 设置视图重建统一收口，保证主题切换、项目切换和 provider 选择都走同一条投影路径。
    final settings = _settings;
    if (settings == null) {
      return;
    }
    _viewModel = _viewModel.copyWith(
      settings: _settingsViewDataFrom(
        settings,
        activeTabId: activeTabId,
        selectedProviderId: selectedProviderId,
      ),
    );
  }

  String _selectedProviderId(AppSettings settings) {
    // 中文注释: 当前选中的 provider 优先沿用设置页状态，没有时再退回默认 provider。
    for (final provider in _viewModel.settings.providers) {
      if (provider.isSelected) {
        return provider.id;
      }
    }
    final fallback = settings.defaultProvider();
    if (fallback != null) {
      return fallback.id;
    }
    return settings.providers.isEmpty ? '' : settings.providers.first.id;
  }

  Map<String, List<SettingsSectionViewData>> _settingsSections(
    AppSettings settings,
  ) {
    // 中文注释: 各 tab 的展示信息在这里按主题分组，后续某个 tab 变成可编辑面板时可以单独替换这一段映射。
    final provider = settings.defaultProvider();
    final providerLabel = provider == null ? '未配置' : provider.title;
    final providerBaseUrl = provider == null || provider.baseUrl.trim().isEmpty
        ? '未配置接口地址'
        : provider.baseUrl;
    final modelLabel = settings.defaultModelId.trim().isEmpty
        ? (provider?.modelId.trim().isEmpty ?? true ? '未配置模型' : provider!.modelId)
        : settings.defaultModelId;
    final currentProjectPath = _currentProject?.rootPath.trim().isNotEmpty == true
        ? _currentProject!.rootPath
        : settings.defaultProjectPath;
    final searchRoots = _settingsSearchRoots.isEmpty
        ? '未配置搜索根'
        : _settingsSearchRoots.join('\n');
    return <String, List<SettingsSectionViewData>>{
      'models': [
        SettingsSectionViewData(
          title: '默认推理入口',
          description: '这里反映当前 GUI 会使用的默认模型、默认 provider 与默认主智能体。',
          items: [
            SettingsItemViewData(label: '默认接口', value: providerLabel),
            SettingsItemViewData(label: '默认模型', value: modelLabel),
            SettingsItemViewData(
              label: '默认智能体',
              value: _agentLabel(settings),
            ),
          ],
        ),
      ],
      'permissions': [
        SettingsSectionViewData(
          title: '工作区权限边界',
          description: '当前版本只在项目工作区与设置根目录内读写，不向移动端额外申请外部存储权限。',
          items: [
            SettingsItemViewData(label: '项目根策略', value: currentProjectPath),
            SettingsItemViewData(
              label: '移动端目录',
              value: _isMobileProjectRootLocked ? '固定在应用文档目录内' : '不适用',
            ),
            SettingsItemViewData(
              label: '外部权限',
              value: '未启用额外外部存储权限',
            ),
          ],
        ),
      ],
      'tooling': [
        SettingsSectionViewData(
          title: '共享运行链路',
          description: 'GUI 与 CLI 共用同一套 core 调度与工具执行入口，宿主层只负责界面与平台适配。',
          items: const [
            SettingsItemViewData(label: '文件访问', value: 'ProjectWorkspacePort'),
            SettingsItemViewData(label: '工具调度', value: 'ToolExecutionService / ProjectToolDispatcher'),
            SettingsItemViewData(label: '交互回流', value: '会话、选项、子智能体运行都会回写同一条会话状态链'),
          ],
        ),
      ],
      'network': [
        SettingsSectionViewData(
          title: '网络与接口',
          description: '模型网络入口来自 provider 配置；临时代理仅允许走进程环境，不写入任何持久化设置文件。',
          items: [
            SettingsItemViewData(label: '默认接口地址', value: providerBaseUrl),
            SettingsItemViewData(
              label: '代理策略',
              value: '临时代理只允许在本次进程生效，不持久化到项目或设置目录。',
            ),
            SettingsItemViewData(
              label: '配置方式',
              value: '优先读取 novel_agent_settings.json，其次读取环境变量覆盖。',
            ),
          ],
        ),
      ],
      'context': [
        SettingsSectionViewData(
          title: '上下文与保存',
          description: '上下文装配、会话历史和自动保存都走共享 core；这里展示当前启用的关键行为。',
          items: [
            SettingsItemViewData(label: '默认项目', value: settings.defaultProjectPath),
            SettingsItemViewData(
              label: '当前项目',
              value: currentProjectPath.trim().isEmpty ? '未加载项目' : currentProjectPath,
            ),
            SettingsItemViewData(
              label: '自动保存草稿',
              value: settings.autoSaveDrafts ? '开启' : '关闭',
            ),
            SettingsItemViewData(
              label: '项目根目录',
              value: _defaultProjectsRootPath,
            ),
          ],
        ),
      ],
      'theme': [
        SettingsSectionViewData(
          title: '界面外观',
          description: '主题切换在应用层生效，但不改变 core 行为和项目数据。',
          items: [
            SettingsItemViewData(label: '当前主题', value: _themeModeLabel()),
            SettingsItemViewData(label: '分栏风格', value: '直角面板 + 线性分割'),
            SettingsItemViewData(label: '窄屏入口', value: '会话栏额外暴露文档与设置入口'),
          ],
        ),
      ],
      'dev': [
        SettingsSectionViewData(
          title: '本地路径',
          description: '下面这些路径来自应用启动装配，便于排查桌面端与移动端各自的宿主行为。',
          items: [
            SettingsItemViewData(label: '设置根目录', value: _settingsRootPath),
            SettingsItemViewData(label: '搜索根目录', value: searchRoots),
            SettingsItemViewData(label: '默认项目根', value: _defaultProjectsRootPath),
          ],
        ),
      ],
    };
  }

  Future<void> _persistSettings(
    AppSettings nextSettings, {
    required String successMessage,
    String? selectedProviderId,
  }) async {
    // 中文注释: 所有设置写盘统一走这里，保证保存、刷新视图和主题切换始终使用同一条收束路径。
    try {
      final savedSettings = await _settingsRepository.save(nextSettings);
      _settings = savedSettings;
      _themeMode = _themeModeFromSettings(savedSettings);
      _refreshSettingsViewData(selectedProviderId: selectedProviderId);
      _viewModel = _viewModel.copyWith(
        workbench: _viewModel.workbench.copyWith(
          modelLabel: _defaultModelLabel(savedSettings),
          agentLabel: _agentLabel(savedSettings),
        ),
      );
      _announce(successMessage);
    } catch (error) {
      _announce('保存设置失败：$error');
    }
  }

  String _providerModelIdOf(AppSettings settings, String providerId) {
    // 中文注释: provider 对应的模型 id 查询集中处理，避免保存默认 provider 时到处重复遍历列表。
    for (final provider in settings.providers) {
      if (provider.id == providerId) {
        return provider.modelId;
      }
    }
    return '';
  }

  ThemeMode _themeModeFromSettings(AppSettings settings) {
    // 中文注释: 主题模式优先从设置文档读取，保证重启应用后仍能回到用户保存的模式。
    return _themeModeFromValue(_stringValue(settings.themeSettings['mode'], 'light'));
  }

  ThemeMode _themeModeFromValue(String value) {
    // 中文注释: 字符串主题值到 ThemeMode 的映射统一放在这里，避免保存和初始化各自维护判断分支。
    switch (value.trim().toLowerCase()) {
      case 'dark':
      case 'night':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      case 'custom':
      case 'light':
      case 'day':
      default:
        return ThemeMode.light;
    }
  }

  String _themeModeLabel() {
    // 中文注释: 主题文案从当前 ThemeMode 推导，避免设置页和工作台各自维护两套状态字串。
    switch (_themeMode) {
      case ThemeMode.system:
        return '跟随系统';
      case ThemeMode.dark:
        return '夜间';
      case ThemeMode.light:
        return '浅色';
    }
  }

  List<ResourceEntryViewData> _resourceEntriesFrom(List<JsonMap> entries) {
    // 中文注释: 资源树视图项只保留展示所需字段，避免把底层目录快照原样塞进 UI。
    return entries
        .map((entry) {
          final relativePath = _stringValue(entry['relative_path']);
          final isDirectory = _boolValue(entry['is_dir']);
          final depth = relativePath.split('/').length - 1;
          return ResourceEntryViewData(
            id: relativePath,
            title: _resourceTitleOf(relativePath, isDirectory: isDirectory),
            depth: depth < 0 ? 0 : depth,
            isDirectory: isDirectory,
          );
        })
        .toList(growable: false);
  }

  List<ResourceEntryViewData> _markResourceSelection(
    List<ResourceEntryViewData> entries, {
    required String selectedId,
  }) {
    // 中文注释: 资源选中状态单独重建，避免每次打开文件都重复计算其他工作台字段。
    return entries
        .map(
          (entry) => ResourceEntryViewData(
            id: entry.id,
            title: entry.title,
            depth: entry.depth,
            isDirectory: entry.isDirectory,
            isSelected: entry.id == selectedId,
          ),
        )
        .toList(growable: false);
  }

  List<DocumentTabViewData> _documentsFor({
    required String title,
    required String relativePath,
  }) {
    // 中文注释: 当前最小可用版本先维护单个活动文档标签，后续多标签再独立扩展。
    return [
      DocumentTabViewData(
        id: relativePath.trim().isEmpty ? title : relativePath,
        title: title.trim().isEmpty ? '未命名草稿' : title,
        isActive: true,
      ),
    ];
  }

  String _displayNameOf(String relativePath) {
    // 中文注释: 展示名称统一从相对路径末段提取，保持资源树和文档标题口径一致。
    final segments = relativePath.split('/');
    return segments.isEmpty ? relativePath : segments.last;
  }

  String _projectSubtitleFor(String projectType) {
    // 中文注释: 项目副标题只显示类型语义，不再占位置解释运行链路状态。
    return ProjectTypeCatalogService().definitionOf(projectType).name;
  }

  String _resourceTitleOf(String relativePath, {required bool isDirectory}) {
    // 中文注释: 资源树只显示中文映射或文件名本身，实际磁盘路径仍保持英文目录结构。
    final cleanPath = relativePath.trim();
    if (cleanPath.isEmpty) {
      return '';
    }
    final segments = cleanPath.split('/');
    final topLevel = segments.first;
    if (isDirectory && segments.length == 1) {
      return _workspaceDirectoryLabel(topLevel);
    }
    return segments.last;
  }

  String _workspaceDirectoryLabel(String directoryName) {
    // 中文注释: 顶层工作区目录统一映射为中文标签，避免展示层泄露英文目录结构细节。
    const labels = <String, String>{
      'specs': '项目规格',
      'styles': '风格',
      'outline': '总纲',
      'volume_outlines': '卷纲',
      'chapter_outlines': '章纲',
      'drafts': '草稿',
      'chapters': '正文',
      'world': '设定',
      'characters': '角色',
      'summaries': '摘要',
      'knowledge': '知识库',
      'inspiration': '灵感',
      'assets': '素材',
      'tasks': '任务',
      'reviews': '审稿',
      'agents': '智能体配置',
      'agent_groups': '智能体组配置',
      'skills': '技能配置',
      'skill_groups': '技能组配置',
      'prompts': '提示词模板',
      'tracking': '执行追踪',
      'runs': '生成记录',
      'backups': '备份',
      'exports': '导出包',
    };
    return labels[directoryName] ?? directoryName;
  }

  String _firstOpenablePath(List<JsonMap> entries) {
    // 中文注释: 初始打开文件只挑第一个文本资源，避免工作台加载后完全空白。
    for (final entry in entries) {
      final isDir = _boolValue(entry['is_dir']);
      final path = _stringValue(entry['relative_path']);
      if (isDir) {
        continue;
      }
      final normalized = path.toLowerCase();
      if (normalized.endsWith('.md') ||
          normalized.endsWith('.txt') ||
          normalized.endsWith('.json') ||
          normalized.endsWith('.yaml') ||
          normalized.endsWith('.yml')) {
        return path;
      }
    }
    return '';
  }

  String _defaultModelLabel(AppSettings settings) {
    // 中文注释: 模型展示文案统一从设置推导，避免 UI 自己拼接 provider 与模型字段。
    final provider = settings.defaultProvider();
    if (provider == null) {
      return settings.defaultModelId;
    }
    final modelId = settings.defaultModelId.trim().isEmpty
        ? provider.modelId
        : settings.defaultModelId;
    if (provider.baseUrl.trim().isEmpty || modelId.trim().isEmpty) {
      return '未配置模型';
    }
    return '${provider.title} · $modelId';
  }

  String _agentLabel(AppSettings settings) {
    // 中文注释: 默认智能体标签先根据核心设置投影，后续接真实生态配置时仍沿用同一入口。
    if (settings.defaultAgentId == 'default_generalist') {
      return '综合创作智能体';
    }
    return settings.defaultAgentId;
  }

  String _titleFromPrompt(String prompt) {
    // 中文注释: 自动保存需要一个轻量标题，这里从提示词首句提取，避免额外打断用户。
    final firstLine = prompt.split('\n').first.trim();
    if (firstLine.isEmpty) {
      return '新草稿';
    }
    return firstLine.length > 24 ? firstLine.substring(0, 24) : firstLine;
  }

  void _announce(String message) {
    // 中文注释: 轻量状态提示统一落到工作台状态栏，避免到处散落 debugPrint。
    _updateWorkbench(
      _withConversationState(
        _viewModel.workbench.copyWith(generationStatus: message),
      ),
    );
  }

  ConversationSessionState _createConversationSession() {
    // 中文注释: 新会话实例统一由这里创建，确保 GUI 端所有会话骨架都走同一套 core 规则。
    return _conversationSessionStateService.createSession(
      sessionId: 'session_${DateTime.now().microsecondsSinceEpoch}',
      title: '',
      needsGoalSelection: true,
    );
  }

  ConversationSessionState _ensureConversationSession() {
    // 中文注释: 发送前如果还没有活动会话，则自动补一个，避免多个入口各自兜底。
    final activeState = _activeConversationState();
    if (activeState != null) {
      return activeState;
    }
    final session = _createConversationSession();
    _replaceConversationSession(session, activate: true);
    return session;
  }

  ConversationSessionState? _activeConversationState() {
    // 中文注释: 活动会话查找独立收口，减少控制器四处散落查表逻辑。
    for (final state in _conversationSessions) {
      if (_sessionIdOf(state) == _activeSessionId) {
        return state;
      }
    }
    return _conversationSessions.isEmpty ? null : _conversationSessions.last;
  }

  void _replaceConversationSession(
    ConversationSessionState state, {
    required bool activate,
  }) {
    // 中文注释: 会话替换通过同一入口维护顺序和活动指针，避免列表更新逻辑分叉。
    final sessionId = _sessionIdOf(state);
    final next = <ConversationSessionState>[];
    var replaced = false;
    for (final current in _conversationSessions) {
      if (_sessionIdOf(current) == sessionId) {
        next.add(state);
        replaced = true;
        continue;
      }
      next.add(current);
    }
    if (!replaced) {
      next.add(state);
    }
    _conversationSessions = next;
    if (activate || _activeSessionId.trim().isEmpty) {
      _activeSessionId = sessionId;
    }
  }

  void _resetConversationSessions() {
    // 中文注释: 切换项目时会话链整体重置，避免不同项目的历史上下文相互污染。
    _conversationSessions = const <ConversationSessionState>[];
    _activeSessionId = '';
    _showSessionHistory = false;
  }

  String _sessionIdOf(ConversationSessionState state) {
    // 中文注释: 会话 id 从记录里统一抽取，避免上层直接理解 sessionRecord 的内部结构。
    final id = _stringValue(state.sessionRecord['session_id']).trim();
    if (id.isNotEmpty) {
      return id;
    }
    return _stringValue(state.sessionRecord['id']);
  }

  WorkbenchViewData _withConversationState(
    WorkbenchViewData base, {
    String? contextSummaryOverride,
  }) {
    // 中文注释: 工作台与会话状态的投影统一在这里完成，避免 controller 多处手拼右栏字段。
    final activeState = _activeConversationState();
    final guide = _conversationGuideViewDataService.build(
      projectType: _currentProject?.projectType ?? 'novel',
      needsGoalSelection: _needsGoalSelection(activeState),
      isGenerating: base.isGenerating,
    );
    return base.copyWith(
      workflowTitle: guide.workflowTitle,
      workflowDescription: guide.workflowDescription,
      composerHint: guide.composerHint,
      primaryActions: guide.primaryActions,
      conversationEntries: activeState?.entries ?? const [],
      pendingOptions: activeState?.pendingOptions ?? const [],
      subAgentRuns: activeState?.subAgentRuns ?? const [],
      sessionHistoryEntries: _conversationSessionStateService.historyEntries(
        _conversationSessions,
        _activeSessionId,
      ),
      activeSessionId: _activeSessionId,
      showSessionHistory: _showSessionHistory,
      contextSummary:
          contextSummaryOverride ??
          _conversationSummary(activeState, fallback: base.contextSummary),
    );
  }

  String _conversationSummary(
    ConversationSessionState? state, {
    required String fallback,
  }) {
    // 中文注释: 会话摘要优先展示多轮上下文状态，没有有效会话内容时再退回项目摘要。
    if (state == null || state.entries.isEmpty) {
      return fallback;
    }
    final summary = _conversationSessionStateService
        .publicSummary(state)
        .trim();
    return summary.isEmpty ? fallback : summary;
  }

  bool _needsGoalSelection(ConversationSessionState? state) {
    // 中文注释: 会话是否仍在待选目标阶段只看会话记录本身，避免页面状态反向决定核心流程。
    return state == null
        ? true
        : _boolValue(state.sessionRecord['needs_goal_selection']);
  }

  JsonMap _currentProjectInfo() {
    // 中文注释: 当前项目的轻量上下文给动作计划和提示词构建服务复用，避免它们直接依赖控制器内部对象。
    final project = _currentProject;
    if (project == null) {
      return const <String, Object?>{};
    }
    return <String, Object?>{
      'id': project.id,
      'title': project.name,
      'path': project.rootPath,
      'project_type': project.projectType,
    };
  }

  Future<void> _startPrimaryActionPrompt(
    WorkbenchPrimaryActionPlan plan,
  ) async {
    // 中文注释: 主动作如果会启动一条真实提示词链，先写入目标模式，再复用同一发送入口继续推进。
    final activeState = _ensureConversationSession();
    if (plan.sessionMode.trim().isNotEmpty) {
      final nextState = _conversationSessionStateService.stateWithGoalSelection(
        activeState,
        plan.sessionMode,
      );
      _replaceConversationSession(nextState, activate: true);
    }
    if (plan.message.trim().isNotEmpty) {
      _updateWorkbench(
        _withConversationState(
          _viewModel.workbench.copyWith(generationStatus: plan.message),
        ),
      );
    }
    await _sendPrompt(plan.prompt);
  }

  String _resultContextSummary(
    DraftGenerationResult result,
    ConversationSessionState assistantState,
  ) {
    // 中文注释: 结果摘要把会话、文件和工具三类信息压成一行，供右栏状态徽章直接复用。
    final sessionSummary = _conversationSummary(
      assistantState,
      fallback: '会话已更新',
    );
    return '$sessionSummary · 读取 ${result.selectedPaths.length} 个文件 · 工具 ${result.executedTools.length} 次 · 上下文 ${result.contextPack['used_chars'] ?? 0} 字';
  }

  String _generationStatusFor(DraftGenerationResult result, String savedPath) {
    // 中文注释: 生成状态文案集中在这里，避免不同完成分支手写出不一致的提示语。
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

  Future<String> _resolvedDocumentBody({
    required ProjectDescriptor project,
    required String generatedMarkdown,
    required String relativePath,
  }) async {
    // 中文注释: 当内容是由工具直接写入文件而不是正文回复时，这里兜底读取真实文件内容给正文区展示。
    if (generatedMarkdown.trim().isNotEmpty) {
      return generatedMarkdown;
    }
    if (relativePath.trim().isEmpty) {
      return '';
    }
    final content = await _readProjectFileUseCase.execute(
      project,
      relativePath,
    );
    return content ?? '';
  }

  Future<void> _showProjectLauncher(
    ProjectLauncherMode mode, {
    String status = '',
  }) async {
    // 中文注释: 项目启动弹层的数据准备统一在这里完成，避免打开和创建两条入口各自重复扫描项目根目录。
    final projects = await _discoverProjectsUseCase.execute(
      _defaultProjectsRootPath,
    );
    _updateWorkbench(
      _withConversationState(
        _viewModel.workbench.copyWith(
          projectLauncher: _projectLauncherViewDataService.build(
            mode: mode,
            projectsRootPath: _defaultProjectsRootPath,
            projects: projects,
            status: status,
          ),
        ),
      ),
    );
  }

  void _updateWorkbench(WorkbenchViewData workbench) {
    // 中文注释: 工作台状态更新统一收口，保证异步动作与普通导航使用同一通知路径。
    _viewModel = _viewModel.copyWith(workbench: workbench);
    _safeNotifyListeners();
  }

  void _safeNotifyListeners() {
    // 中文注释: 控制器在页面销毁后不再通知监听器，避免异步初始化和请求完成时抛异常。
    if (_disposed) {
      return;
    }
    notifyListeners();
  }

  String _stringValue(Object? value, [String fallback = '']) {
    // 中文注释: 控制器只需要轻量文本投影，这里本地收口，避免依赖 core 内部未导出的工具实现。
    if (value == null) {
      return fallback;
    }
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  bool _boolValue(Object? value) {
    // 中文注释: 布尔投影仅服务当前视图映射，控制器内部自行处理即可，不需要越层拿动态读取工具。
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    final normalized = value?.toString().trim().toLowerCase() ?? '';
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }
}
