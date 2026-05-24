import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../features/agent_ecosystem/application/models/agent_ecosystem_snapshot.dart';
import '../../features/agent_ecosystem/application/services/agent_ecosystem_view_data_service.dart';
import '../../features/agent_ecosystem/application/services/customization_import_preview_text_service.dart';
import '../../features/agent_ecosystem/application/services/ecosystem_entry_creation_plan_service.dart';
import '../../features/agent_ecosystem/application/services/ecosystem_entry_editor_service.dart';
import '../../features/agent_ecosystem/presentation/contracts/agent_ecosystem_action_handler.dart';
import '../../features/agent_ecosystem/presentation/models/ecosystem_editor_view_data.dart';
import '../../features/agent_ecosystem/presentation/models/ecosystem_import_command_view_data.dart';
import '../../features/prompt_templates/application/services/prompt_templates_view_data_service.dart';
import '../../features/prompt_templates/presentation/contracts/prompt_templates_action_handler.dart';
import '../../features/prompt_templates/presentation/models/prompt_templates_view_data.dart';
import '../../features/project_collection/application/models/project_collection_snapshot.dart';
import '../../features/project_collection/application/services/project_collection_loader_service.dart';
import '../../features/project_collection/presentation/contracts/project_collection_action_handler.dart';
import '../../features/project_collection/presentation/models/project_collection_view_data.dart';
import '../../features/review_center/application/services/review_center_view_data_service.dart';
import '../../features/review_center/presentation/contracts/review_center_action_handler.dart';
import '../../features/settings/application/services/model_settings_view_data_service.dart';
import '../../features/settings/presentation/contracts/settings_action_handler.dart';
import '../../features/settings/presentation/models/settings_view_data.dart';
import '../../features/task_center/application/services/task_center_view_data_service.dart';
import '../../features/task_center/presentation/contracts/task_center_action_handler.dart';
import '../../features/task_center/presentation/models/task_center_view_data.dart';
import '../../features/workbench/application/models/conversation_session_state.dart';
import '../../features/workbench/application/models/open_document_state.dart';
import '../../features/workbench/application/models/workbench_primary_action_plan.dart';
import '../../features/workbench/application/services/conversation_session_state_service.dart';
import '../../features/workbench/application/services/conversation_streaming_state_service.dart';
import '../../features/workbench/application/services/conversation_guide_view_data_service.dart';
import '../../features/workbench/application/services/project_launcher_view_data_service.dart';
import '../../features/workbench/application/services/workbench_primary_action_service.dart';
import '../../features/workbench/application/services/conversation_user_visible_text_service.dart';
import '../../features/workbench/presentation/contracts/conversation_action_handler.dart';
import '../../features/workbench/presentation/contracts/document_workspace_action_handler.dart';
import '../../features/workbench/presentation/contracts/resource_manager_action_handler.dart';
import '../../features/workbench/presentation/models/project_launcher_view_data.dart';
import '../../features/workbench/presentation/models/project_create_request_view_data.dart';
import '../../features/workbench/presentation/models/selector_option_view_data.dart';
import '../../features/workbench/presentation/models/user_option_view_data.dart';
import '../../features/workbench/presentation/models/workbench_view_data.dart';
import '../../shared/view_models/app_shell_view_model.dart';
import '../routing/app_destination.dart';

typedef GenerateDraftUseCaseFactory =
    GenerateDraftUseCase Function(
      ProviderEndpointSettings provider,
      JsonMap networkSettings,
    );
typedef LoadAgentPackages =
    Future<List<JsonMap>> Function(ProjectDescriptor project);
typedef LoadAgentGroups =
    Future<List<JsonMap>> Function(ProjectDescriptor project);
typedef LoadSkillPackages =
    Future<List<JsonMap>> Function(ProjectDescriptor project);
typedef LoadSkillGroups =
    Future<List<JsonMap>> Function(ProjectDescriptor project);

class AppShellController extends ChangeNotifier
    implements
        ResourceManagerActionHandler,
        DocumentWorkspaceActionHandler,
        ConversationActionHandler,
        SettingsActionHandler,
        AgentEcosystemActionHandler,
        ProjectCollectionActionHandler,
        TaskCenterActionHandler,
        ReviewCenterActionHandler,
        PromptTemplatesActionHandler {
  AppShellController({
    required SettingsRepository settingsRepository,
    required LoadProjectWorkspaceUseCase loadProjectWorkspaceUseCase,
    required ReadProjectFileUseCase readProjectFileUseCase,
    required SaveDraftUseCase saveDraftUseCase,
    required CreateProjectWorkspaceUseCase createProjectWorkspaceUseCase,
    required DiscoverProjectsUseCase discoverProjectsUseCase,
    required CreateProjectEntryUseCase createProjectEntryUseCase,
    required ImportProjectFilesUseCase importProjectFilesUseCase,
    required UpdateProjectManifestUseCase updateProjectManifestUseCase,
    required ProjectToolHostPort projectToolHostPort,
    required PreviewCustomizationBundleImportUseCase
    previewCustomizationBundleImportUseCase,
    required ImportCustomizationBundleUseCase importCustomizationBundleUseCase,
    required GenerateCustomizationIndexesUseCase
    generateCustomizationIndexesUseCase,
    required SaveCustomizationMarketIndexUseCase
    saveCustomizationMarketIndexUseCase,
    required String settingsRootPath,
    required List<String> settingsSearchRoots,
    required String defaultProjectsRootPath,
    required bool isMobileProjectRootLocked,
    required LoadAgentPackages loadAgentPackages,
    required LoadAgentGroups loadAgentGroups,
    required LoadSkillPackages loadSkillPackages,
    required LoadSkillGroups loadSkillGroups,
    required WriteProjectTextFileUseCase writeProjectTextFileUseCase,
    required GenerateDraftUseCaseFactory generateDraftUseCaseFactory,
    required ProjectWorkflowRuntimeService workflowRuntimeService,
    required ProjectReviewReportService reviewReportService,
    required ProjectPromptTemplateService promptTemplateService,
    ConversationSessionStateService? conversationSessionStateService,
    ConversationStreamingStateService? conversationStreamingStateService,
    ConversationGuideViewDataService? conversationGuideViewDataService,
    ConversationUserVisibleTextService? conversationUserVisibleTextService,
    ProjectLauncherViewDataService? projectLauncherViewDataService,
    WorkbenchPrimaryActionService? workbenchPrimaryActionService,
    UserOptionPromptBuilderService? userOptionPromptBuilderService,
    AgentEcosystemViewDataService? agentEcosystemViewDataService,
    EcosystemEntryCreationPlanService? ecosystemEntryCreationPlanService,
    EcosystemEntryEditorService? ecosystemEntryEditorService,
    CustomizationImportPreviewTextService?
    customizationImportPreviewTextService,
    ProjectCollectionLoaderService? projectCollectionLoaderService,
    TaskCenterViewDataService? taskCenterViewDataService,
    ReviewCenterViewDataService? reviewCenterViewDataService,
    PromptTemplatesViewDataService? promptTemplatesViewDataService,
    PromptTemplatePreviewService? promptTemplatePreviewService,
    PromptTemplateNormalizerService? promptTemplateNormalizerService,
    ModelSettingsViewDataService? modelSettingsViewDataService,
    ModelExecutionProfileService? modelExecutionProfileService,
  }) : _settingsRepository = settingsRepository,
       _loadProjectWorkspaceUseCase = loadProjectWorkspaceUseCase,
       _readProjectFileUseCase = readProjectFileUseCase,
       _saveDraftUseCase = saveDraftUseCase,
       _createProjectWorkspaceUseCase = createProjectWorkspaceUseCase,
       _discoverProjectsUseCase = discoverProjectsUseCase,
       _createProjectEntryUseCase = createProjectEntryUseCase,
       _importProjectFilesUseCase = importProjectFilesUseCase,
       _updateProjectManifestUseCase = updateProjectManifestUseCase,
       _projectToolHostPort = projectToolHostPort,
       _previewCustomizationBundleImportUseCase =
           previewCustomizationBundleImportUseCase,
       _importCustomizationBundleUseCase = importCustomizationBundleUseCase,
       _generateCustomizationIndexesUseCase =
           generateCustomizationIndexesUseCase,
       _saveCustomizationMarketIndexUseCase =
           saveCustomizationMarketIndexUseCase,
       _settingsRootPath = settingsRootPath,
       _settingsSearchRoots = List<String>.unmodifiable(settingsSearchRoots),
       _defaultProjectsRootPath = defaultProjectsRootPath,
       _isMobileProjectRootLocked = isMobileProjectRootLocked,
       _loadAgentPackages = loadAgentPackages,
       _loadAgentGroups = loadAgentGroups,
       _loadSkillPackages = loadSkillPackages,
       _loadSkillGroups = loadSkillGroups,
       _writeProjectTextFileUseCase = writeProjectTextFileUseCase,
       _generateDraftUseCaseFactory = generateDraftUseCaseFactory,
       _workflowRuntimeService = workflowRuntimeService,
       _reviewReportService = reviewReportService,
       _promptTemplateService = promptTemplateService,
       _conversationSessionStateService =
           conversationSessionStateService ?? ConversationSessionStateService(),
       _conversationStreamingStateService =
           conversationStreamingStateService ??
           ConversationStreamingStateService(
             sessionStateService:
                 conversationSessionStateService ??
                 ConversationSessionStateService(),
           ),
       _conversationGuideViewDataService =
           conversationGuideViewDataService ??
           ConversationGuideViewDataService(),
       _conversationUserVisibleTextService =
           conversationUserVisibleTextService ??
           const ConversationUserVisibleTextService(),
       _projectLauncherViewDataService =
           projectLauncherViewDataService ?? ProjectLauncherViewDataService(),
       _workbenchPrimaryActionService =
           workbenchPrimaryActionService ?? WorkbenchPrimaryActionService(),
       _userOptionPromptBuilderService =
           userOptionPromptBuilderService ?? UserOptionPromptBuilderService(),
       _agentEcosystemViewDataService =
           agentEcosystemViewDataService ??
           const AgentEcosystemViewDataService(),
       _ecosystemEntryCreationPlanService =
           ecosystemEntryCreationPlanService ??
           EcosystemEntryCreationPlanService(),
       _ecosystemEntryEditorService =
           ecosystemEntryEditorService ?? EcosystemEntryEditorService(),
       _customizationImportPreviewTextService =
           customizationImportPreviewTextService ??
           const CustomizationImportPreviewTextService(),
       _projectCollectionLoaderService =
           projectCollectionLoaderService ?? ProjectCollectionLoaderService(),
       _taskCenterViewDataService =
           taskCenterViewDataService ?? const TaskCenterViewDataService(),
       _reviewCenterViewDataService =
           reviewCenterViewDataService ?? const ReviewCenterViewDataService(),
       _promptTemplatesViewDataService =
           promptTemplatesViewDataService ??
           const PromptTemplatesViewDataService(),
       _promptTemplatePreviewService =
           promptTemplatePreviewService ?? PromptTemplatePreviewService(),
       _promptTemplateNormalizerService =
           promptTemplateNormalizerService ?? PromptTemplateNormalizerService(),
       _modelSettingsViewDataService =
           modelSettingsViewDataService ?? ModelSettingsViewDataService(),
       _modelExecutionProfileService =
           modelExecutionProfileService ?? ModelExecutionProfileService(),
       _viewModel = AppShellViewModel.initial();

  final SettingsRepository _settingsRepository;
  final LoadProjectWorkspaceUseCase _loadProjectWorkspaceUseCase;
  final ReadProjectFileUseCase _readProjectFileUseCase;
  final SaveDraftUseCase _saveDraftUseCase;
  final CreateProjectWorkspaceUseCase _createProjectWorkspaceUseCase;
  final DiscoverProjectsUseCase _discoverProjectsUseCase;
  final CreateProjectEntryUseCase _createProjectEntryUseCase;
  final ImportProjectFilesUseCase _importProjectFilesUseCase;
  final UpdateProjectManifestUseCase _updateProjectManifestUseCase;
  final ProjectToolHostPort _projectToolHostPort;
  final PreviewCustomizationBundleImportUseCase
  _previewCustomizationBundleImportUseCase;
  final ImportCustomizationBundleUseCase _importCustomizationBundleUseCase;
  final GenerateCustomizationIndexesUseCase
  _generateCustomizationIndexesUseCase;
  final SaveCustomizationMarketIndexUseCase
  _saveCustomizationMarketIndexUseCase;
  final String _settingsRootPath;
  final List<String> _settingsSearchRoots;
  final String _defaultProjectsRootPath;
  final bool _isMobileProjectRootLocked;
  final LoadAgentPackages _loadAgentPackages;
  final LoadAgentGroups _loadAgentGroups;
  final LoadSkillPackages _loadSkillPackages;
  final LoadSkillGroups _loadSkillGroups;
  final WriteProjectTextFileUseCase _writeProjectTextFileUseCase;
  final GenerateDraftUseCaseFactory _generateDraftUseCaseFactory;
  final ProjectWorkflowRuntimeService _workflowRuntimeService;
  final ProjectReviewReportService _reviewReportService;
  final ProjectPromptTemplateService _promptTemplateService;
  final ConversationSessionStateService _conversationSessionStateService;
  final ConversationStreamingStateService _conversationStreamingStateService;
  final ConversationGuideViewDataService _conversationGuideViewDataService;
  final ConversationUserVisibleTextService _conversationUserVisibleTextService;
  final ProjectLauncherViewDataService _projectLauncherViewDataService;
  final WorkbenchPrimaryActionService _workbenchPrimaryActionService;
  final UserOptionPromptBuilderService _userOptionPromptBuilderService;
  final AgentEcosystemViewDataService _agentEcosystemViewDataService;
  final EcosystemEntryCreationPlanService _ecosystemEntryCreationPlanService;
  final EcosystemEntryEditorService _ecosystemEntryEditorService;
  final CustomizationImportPreviewTextService
  _customizationImportPreviewTextService;
  final ProjectCollectionLoaderService _projectCollectionLoaderService;
  final TaskCenterViewDataService _taskCenterViewDataService;
  final ReviewCenterViewDataService _reviewCenterViewDataService;
  final PromptTemplatesViewDataService _promptTemplatesViewDataService;
  final PromptTemplatePreviewService _promptTemplatePreviewService;
  final PromptTemplateNormalizerService _promptTemplateNormalizerService;
  final ModelSettingsViewDataService _modelSettingsViewDataService;
  final ModelExecutionProfileService _modelExecutionProfileService;

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
  AgentEcosystemSnapshot _agentEcosystemSnapshot =
      AgentEcosystemSnapshot.initial();
  ProjectCollectionSnapshot _projectCollectionSnapshot =
      ProjectCollectionSnapshot.initial();
  String _agentEcosystemStatusMessage = '';
  EcosystemImportCommandViewData? _ecosystemImportCommand;
  EcosystemEditorViewData? _ecosystemEditorViewData;
  List<JsonMap> _taskCenterTasks = const <JsonMap>[];
  String _selectedTaskId = '';
  String _selectedLongTaskRunPath = '';
  String _selectedTaskQueueRunPath = '';
  String _taskCenterStatusMessage = '';
  List<JsonMap> _reviewCenterEntries = const <JsonMap>[];
  String _selectedReviewEntryId = '';
  String _reviewCenterStatusMessage = '';
  String _reviewTypeFilter = '';
  String _reviewScopeFilter = '';
  String _reviewSourceFilter = '';
  List<JsonMap> _promptTemplates = const <JsonMap>[];
  JsonMap _selectedPromptTemplate = const <String, Object?>{};
  String _selectedPromptTemplateId = '';
  String _promptTemplatesStatusMessage = '';
  String _promptTemplatePreviewText = '';
  List<JsonMap> _resourceSnapshotEntries = const <JsonMap>[];
  Set<String> _expandedResourceDirectories = <String>{};
  List<OpenDocumentState> _openDocuments = const <OpenDocumentState>[];
  String _activeOpenDocumentId = '';
  bool _savingWorkbenchSnapshot = false;

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
          modelOptions: _modelSelectorOptions(settings),
          agentLabel: _agentLabel(settings),
          agentOptions: _agentSelectorOptions(),
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
    _refreshAgentEcosystem();
  }

  void showTaskCenter() {
    // 中文注释: 长任务中心导航和数据刷新统一收口，避免资源栏与会话动作各自重复读任务目录。
    _viewModel = _viewModel.copyWith(destination: AppDestination.taskCenter);
    _safeNotifyListeners();
    _refreshTaskCenter();
  }

  void showReviewCenter() {
    // 中文注释: 审稿中心切换后立即刷新报告列表，让文档工具栏和左栏入口共用同一页面状态。
    _viewModel = _viewModel.copyWith(destination: AppDestination.reviewCenter);
    _safeNotifyListeners();
    _refreshReviewCenter();
  }

  void showPromptTemplates() {
    // 中文注释: 模板页导航与数据刷新统一收口，避免后续从设置页或任务页进入时出现两套状态来源。
    _viewModel = _viewModel.copyWith(
      destination: AppDestination.promptTemplates,
    );
    _safeNotifyListeners();
    _refreshPromptTemplates();
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
    // 中文注释: 项目信息编辑只负责弹出表单，不在资源面板内部直接操作项目文件。
    final project = _currentProject;
    _showWorkspaceCommand(
      WorkspaceCommandViewData(
        mode: WorkspaceCommandMode.editProjectInfo,
        title: '编辑项目信息',
        description: '更新项目标题、类型与简介文档。',
        confirmLabel: '保存项目',
        status: project == null ? '当前还没有打开项目。' : '',
        projectTitle: project?.name ?? '',
        projectType: project?.projectType ?? 'novel',
        genre: '',
        premise: '',
        notes: '',
        relativePath: '',
        entryName: '',
        content: '',
        sourcePathsText: '',
        targetDirectory: '',
      ),
    );
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
    // 中文注释: 新建文件走统一工作区命令弹层，让 GUI 和 CLI 后续都能复用相同核心用例。
    _showWorkspaceCommand(
      const WorkspaceCommandViewData(
        mode: WorkspaceCommandMode.createFile,
        title: '新建文件',
        description: '在项目目录下创建一个新文件。',
        confirmLabel: '创建文件',
        status: '',
        projectTitle: '',
        projectType: '',
        genre: '',
        premise: '',
        notes: '',
        relativePath: 'drafts',
        entryName: 'new_file.md',
        content: '',
        sourcePathsText: '',
        targetDirectory: '',
      ),
    );
  }

  @override
  void onCreateFolderRequested() {
    // 中文注释: 新建目录也走同一命令弹层，避免不同项目操作入口各自管理表单状态。
    _showWorkspaceCommand(
      const WorkspaceCommandViewData(
        mode: WorkspaceCommandMode.createFolder,
        title: '新建文件夹',
        description: '在项目目录下创建一个新目录。',
        confirmLabel: '创建目录',
        status: '',
        projectTitle: '',
        projectType: '',
        genre: '',
        premise: '',
        notes: '',
        relativePath: 'world',
        entryName: 'new_folder',
        content: '',
        sourcePathsText: '',
        targetDirectory: '',
      ),
    );
  }

  @override
  void onImportRequested() {
    // 中文注释: 导入入口先走绝对路径表单，后续再补平台文件选择器也不影响核心导入用例。
    _showWorkspaceCommand(
      const WorkspaceCommandViewData(
        mode: WorkspaceCommandMode.importFiles,
        title: '导入文件',
        description: '每行输入一个绝对路径，导入到项目指定目录。',
        confirmLabel: '导入文件',
        status: '',
        projectTitle: '',
        projectType: '',
        genre: '',
        premise: '',
        notes: '',
        relativePath: '',
        entryName: '',
        content: '',
        sourcePathsText: '',
        targetDirectory: 'assets',
      ),
    );
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
    // 中文注释: 任务入口直接进入真实任务中心，而不是停留在旧的泛集合浏览页。
    showTaskCenter();
  }

  @override
  void onReviewsRequested() {
    // 中文注释: 审稿入口直接进入真实审稿中心，后续修复任务和过滤都从这里继续推进。
    showReviewCenter();
  }

  @override
  void onTemplatesRequested() {
    // 中文注释: 模板入口切到真实模板页，支持项目覆盖、内置恢复和预览。
    showPromptTemplates();
  }

  @override
  void onResourceEntrySelected(String entryId) {
    // 中文注释: 资源树点击统一走读取用例，保持文件打开逻辑脱离具体组件。
    _openResource(entryId);
  }

  @override
  void onWorkspaceCommandDismissed() {
    // 中文注释: 工作区命令弹层关闭只清理弹层状态，不触碰项目和文档状态。
    _updateWorkbench(_viewModel.workbench.copyWith(workspaceCommand: null));
  }

  @override
  void onWorkspaceCommandSubmitted(WorkspaceCommandRequestViewData request) {
    // 中文注释: 命令提交统一从这里分派到共享用例，避免表单组件直接碰业务依赖。
    switch (request.mode) {
      case WorkspaceCommandMode.editProjectInfo:
        _submitProjectInfoCommand(request);
        return;
      case WorkspaceCommandMode.createFile:
        _submitCreateFileCommand(request);
        return;
      case WorkspaceCommandMode.createFolder:
        _submitCreateFolderCommand(request);
        return;
      case WorkspaceCommandMode.importFiles:
        _submitImportFilesCommand(request);
        return;
    }
  }

  @override
  void onDocumentActionRequested(DocumentToolbarAction action) {
    // 中文注释: 文档工具栏动作尽量接到真实工作流，避免再次出现只有提示没有行为的空按钮。
    switch (action) {
      case DocumentToolbarAction.save:
        _saveCurrentDocument();
        break;
      case DocumentToolbarAction.render:
        _toggleActiveDocumentRenderMode();
        break;
      case DocumentToolbarAction.outline:
        _openLikelyOutlineDocument();
        break;
      case DocumentToolbarAction.review:
        _createReviewTaskForCurrentDocument();
        break;
    }
  }

  @override
  void onDocumentSelected(String documentId) {
    // 中文注释: 标签切换只改变活动文档，不在这里引入任何读盘副作用。
    if (documentId.trim().isEmpty || documentId == _activeOpenDocumentId) {
      return;
    }
    _activeOpenDocumentId = documentId;
    _updateWorkbench(
      _applyOpenDocuments(
        _viewModel.workbench.copyWith(generationStatus: '已切换文档。'),
      ),
    );
    _persistWorkbenchSnapshot();
  }

  @override
  void onDocumentClosed(String documentId) {
    // 中文注释: 关闭标签只维护内存中的打开文档集合，保存策略仍由显式保存按钮控制。
    final index = _openDocuments.indexWhere(
      (document) => document.id == documentId,
    );
    if (index < 0) {
      return;
    }
    final nextDocuments = List<OpenDocumentState>.from(_openDocuments)
      ..removeAt(index);
    _openDocuments = nextDocuments;
    if (_activeOpenDocumentId == documentId) {
      if (nextDocuments.isEmpty) {
        _activeOpenDocumentId = '';
      } else if (index >= nextDocuments.length) {
        _activeOpenDocumentId = nextDocuments.last.id;
      } else {
        _activeOpenDocumentId = nextDocuments[index].id;
      }
    }
    _updateWorkbench(
      _applyOpenDocuments(
        _viewModel.workbench.copyWith(generationStatus: '已关闭文档。'),
      ),
    );
    _persistWorkbenchSnapshot();
  }

  @override
  void onDocumentBodyChanged(String value) {
    // 中文注释: 正文编辑只改工作台当前文档内容和脏标记，不在输入过程中触发任何持久化副作用。
    final active = _activeOpenDocument();
    if (active == null) {
      return;
    }
    _replaceOpenDocument(
      active.copyWith(content: value, isDirty: true, isRendered: false),
    );
    _updateWorkbench(_applyOpenDocuments(_viewModel.workbench));
  }

  @override
  void onModelSelected(String modelId) {
    // 中文注释: 会话栏顶部模型选择直接落到共享设置，保持 GUI/CLI 同一份默认运行配置。
    final settings = _settings;
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
    // 中文注释: 会话栏顶部智能体选择只改默认智能体 id，不在展示层直接拼接角色正文。
    final settings = _settings;
    final cleanAgentId = agentId.trim();
    if (settings == null || cleanAgentId.isEmpty) {
      return;
    }
    final updated = settings.copyWith(defaultAgentId: cleanAgentId);
    _persistSettings(updated, successMessage: '已切换智能体：${_agentLabel(updated)}');
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
    // 中文注释: 屏幕模式按钮当前负责在会话视图与文档视图之间切换，避免窄屏入口成为空按钮。
    final nextVisible = !_viewModel.workbench.isDocumentsWorkspaceVisible;
    _updateWorkbench(
      _withConversationState(
        _viewModel.workbench.copyWith(
          isDocumentsWorkspaceVisible: nextVisible,
          generationStatus: nextVisible ? '已切到文档视图。' : '已切回会话视图。',
        ),
      ),
    );
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
        _viewModel.workbench.copyWith(
          generationStatus: '已创建新会话，请先选择一个入口，或直接输入第一句话。',
        ),
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
    await _sendPrompt(
      prompt,
      visibleText: _conversationUserVisibleTextService.textForUserOption(option),
    );
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
        _startPrimaryActionPrompt(
          plan,
          userVisibleText: _conversationUserVisibleTextService
              .textForPrimaryAction(action, plan),
        );
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
    // 中文注释: 工具选项当前直接复用设置页入口，避免按钮存在但没有任何实际行为。
    showSettings();
    _announce('已打开设置页，可继续调整工具策略与权限。');
  }

  @override
  void onSendRequested(String text) async {
    // 中文注释: 发送动作统一复用同一条会话请求链，避免按钮发送与选项发送走出两套行为。
    await _sendPrompt(text);
  }

  Future<void> _sendPrompt(String text, {String visibleText = ''}) async {
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
    final userPromptState = _conversationSessionStateService
        .stateWithUserPrompt(
          activeState,
          cleanText,
          displayContent: visibleText,
          strategySettings: contextStrategySettings,
          modelProfile: runtimeProfile,
        );
    _replaceConversationSession(userPromptState, activate: true);
    _showSessionHistory = false;
    _updateWorkbench(
      _withConversationState(
        _viewModel.workbench.copyWith(
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
      _updateWorkbench(
        _withConversationState(
          _viewModel.workbench.copyWith(
            isGenerating: true,
            generationStatus: _streamingGenerationStatus(provider, progress),
            toolCoreStatus: progress.pendingToolCalls.isNotEmpty
                ? '正在调用工具'
                : '',
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
        activeDocumentPath: _viewModel.workbench.activeDocumentPath,
        activeDocumentBody: _activeOpenDocument()?.content ?? '',
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
      if (hasDocumentContent) {
        _openOrActivateDocument(
          relativePath: savedPath,
          title: title.isEmpty ? '新草稿' : title,
          content: resolvedBody,
        );
      }
      final nextWorkbench = _applyOpenDocuments(
        _viewModel.workbench.copyWith(
          resourceEntries: resourceEntries,
          modelLabel: '${provider.title} · ${result.modelId}',
          contextSummary: _resultContextSummary(result, assistantState),
          generationStatus: _generationStatusFor(result, savedPath),
          toolCoreStatus: result.waitingForUserChoice ? '等待选择' : '',
          isGenerating: false,
        ),
      );
      _updateWorkbench(_withConversationState(nextWorkbench));
    } catch (error) {
      final failedState = _conversationSessionStateService
          .stateWithAssistantFailure(
            userPromptState,
            '生成失败：$error',
            strategySettings: contextStrategySettings,
            modelProfile: runtimeProfile,
          );
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
    final nextTitle = _stringValue(payload['title'], '新接口');
    final nextId = sourceId.trim().isNotEmpty
        ? sourceId
        : _nextProviderId(settings.providers, nextTitle);
    final nextProvider = ProviderEndpointSettings(
      id: nextId,
      title: nextTitle,
      protocol: _stringValue(payload['protocol'], 'openai_compatible'),
      baseUrl: _stringValue(payload['base_url']),
      apiKey: _stringValue(payload['api_key']),
      modelId: '',
      description: _stringValue(payload['description']),
      isDefault: false,
    );
    final providers = <ProviderEndpointSettings>[];
    var replaced = false;
    for (final provider in settings.providers) {
      if (provider.id == sourceId && sourceId.trim().isNotEmpty) {
        providers.add(nextProvider);
        replaced = true;
        continue;
      }
      providers.add(provider);
    }
    if (!replaced) {
      providers.add(nextProvider);
    }
    final modelSettings = _modelSettingsOf(settings);
    final selectedProviderId = _stringValue(
      modelSettings['provider_id'],
      settings.defaultProviderId,
    );
    final updated = settings.copyWith(
      providers: providers,
      defaultProviderId: settings.defaultProviderId == sourceId
          ? nextProvider.id
          : settings.defaultProviderId,
      extraSettings: <String, Object?>{
        ...settings.extraSettings,
        'model_settings': <String, Object?>{
          ...modelSettings,
          if (selectedProviderId == sourceId) 'provider_id': nextProvider.id,
        },
      },
    );
    _persistSettings(
      updated,
      successMessage: '接口设置已保存。',
      selectedProviderId: nextProvider.id,
    );
  }

  @override
  void onProviderDeleted(String providerId) {
    // 中文注释: provider 删除后允许接口列表为空，同时修正模型设置里可能悬空的接口选择。
    final settings = _settings;
    if (settings == null) {
      return;
    }
    final providers = settings.providers
        .where((provider) => provider.id != providerId)
        .toList(growable: false);
    final modelSettings = _modelSettingsOf(settings);
    final currentModelProviderId = _stringValue(
      modelSettings['provider_id'],
      settings.defaultProviderId,
    );
    final nextModelProviderId = currentModelProviderId == providerId
        ? ''
        : currentModelProviderId;
    final updated = settings.copyWith(
      providers: providers,
      defaultProviderId: settings.defaultProviderId == providerId
          ? ''
          : settings.defaultProviderId,
      extraSettings: <String, Object?>{
        ...settings.extraSettings,
        'model_settings': <String, Object?>{
          ...modelSettings,
          'provider_id': nextModelProviderId,
        },
      },
    );
    _persistSettings(updated, successMessage: '接口已删除。');
  }

  @override
  void onModelSettingsSaved(Map<String, Object?> payload) {
    // 中文注释: 模型设置单独落成一段运行参数，接口创建与模型运行不会再互相挤进同一份表单。
    final settings = _settings;
    if (settings == null) {
      return;
    }
    final modelSettings = <String, Object?>{
      ..._modelSettingsOf(settings),
      'provider_id': _stringValue(
        payload['default_provider_id'],
        settings.defaultProviderId,
      ),
      'model_id': _stringValue(
        payload['model_id'],
        _stringValue(payload['default_model_id'], settings.defaultModelId),
      ),
      'compatible_context_window': _stringValue(
        payload['compatible_context_window'],
      ),
      'app_context_window': _stringValue(payload['app_context_window']),
      'stream_mode': _stringValue(payload['stream_mode'], 'stream'),
      'api_mode': _stringValue(payload['api_mode'], 'chat'),
      'thinking_enabled': _boolValue(payload['thinking_enabled']),
      'thinking_effort': _stringValue(payload['thinking_effort'], 'high'),
      'temperature': _stringValue(payload['temperature']),
      'top_p': _stringValue(payload['top_p']),
      'top_k': _stringValue(payload['top_k']),
      'custom_parameters': ValueReaders.deepCopyList(
        ValueReaders.objectList(payload['custom_parameters']),
      ),
    };
    final updated = settings.copyWith(
      defaultProviderId: _stringValue(
        payload['default_provider_id'],
        settings.defaultProviderId,
      ),
      defaultModelId: _stringValue(
        payload['default_model_id'],
        settings.defaultModelId,
      ),
      extraSettings: <String, Object?>{
        ...settings.extraSettings,
        'model_settings': modelSettings,
      },
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
    // 中文注释: 生态刷新统一回到控制器，再由独立的目录加载与 view data 服务承接细节。
    _refreshAgentEcosystem();
  }

  @override
  void onImportEcosystemPackageRequested() {
    // 中文注释: 生态导入入口只负责拉起表单弹层，具体预检和写盘统一走共享用例。
    if (_currentProject == null) {
      _setAgentEcosystemStatus('请先创建或打开项目，再导入生态包。');
      return;
    }
    _ecosystemImportCommand = const EcosystemImportCommandViewData(
      bundlePath: '',
      overwrite: true,
      allowBuiltinShadow: true,
      status: '',
      previewSummary: '',
    );
    _refreshAgentEcosystemView();
  }

  @override
  void onEcosystemImportDismissed() {
    // 中文注释: 导入弹层关闭只清理表单状态，不影响生态列表和当前选中条目。
    _ecosystemImportCommand = null;
    _refreshAgentEcosystemView();
  }

  @override
  void onEcosystemImportSubmitted(
    EcosystemImportRequestViewData request,
  ) async {
    // 中文注释: 导入提交统一在这里完成外部文本读取、预检、写盘和刷新，避免页面自己碰宿主文件系统。
    final project = _currentProject;
    if (project == null) {
      _setAgentEcosystemStatus('请先创建或打开项目，再导入生态包。');
      return;
    }
    final bundlePath = request.bundlePath.trim();
    if (bundlePath.isEmpty) {
      _updateEcosystemImportCommand(
        _ecosystemImportCommand?.copyWith(status: '请输入生态包绝对路径。'),
      );
      return;
    }
    _updateEcosystemImportCommand(
      _ecosystemImportCommand?.copyWith(
        bundlePath: bundlePath,
        overwrite: request.overwrite,
        allowBuiltinShadow: request.allowBuiltinShadow,
        status: '正在读取生态包并进行预检...',
        previewSummary: '',
      ),
    );
    final bundleContent = await _projectToolHostPort.readExternalTextFile(
      bundlePath,
    );
    if ((bundleContent ?? '').trim().isEmpty) {
      _updateEcosystemImportCommand(
        _ecosystemImportCommand?.copyWith(status: '生态包文件不存在或不是可读文本。'),
      );
      return;
    }
    try {
      await _refreshAgentEcosystem();
      final preview = _previewCustomizationBundleImportUseCase.execute(
        bundleContent: bundleContent!,
        overwrite: request.overwrite,
        allowBuiltinShadow: request.allowBuiltinShadow,
        projectAgents: _projectEntriesOf(_agentEcosystemSnapshot.agents),
        projectSkills: _projectEntriesOf(_agentEcosystemSnapshot.skills),
        projectSkillGroups: _projectEntriesOf(
          _agentEcosystemSnapshot.skillGroups,
        ),
        projectAgentGroups: _projectEntriesOf(
          _agentEcosystemSnapshot.agentGroups,
        ),
        builtinAgents: _builtinEntriesOf(_agentEcosystemSnapshot.agents),
        builtinSkills: _builtinEntriesOf(_agentEcosystemSnapshot.skills),
        builtinSkillGroups: _builtinEntriesOf(
          _agentEcosystemSnapshot.skillGroups,
        ),
        builtinAgentGroups: _builtinEntriesOf(
          _agentEcosystemSnapshot.agentGroups,
        ),
      );
      final previewText = _customizationImportPreviewTextService
          .buildPreviewText(preview);
      if (!ValueReaders.boolValue(preview['ok'])) {
        _updateEcosystemImportCommand(
          _ecosystemImportCommand?.copyWith(
            status:
                '生态包预检失败：${ValueReaders.stringValue(preview["error"], "未知错误")}',
            previewSummary: previewText,
          ),
        );
        return;
      }
      _updateEcosystemImportCommand(
        _ecosystemImportCommand?.copyWith(
          status: '预检完成，正在导入...',
          previewSummary: previewText,
        ),
      );
      final result = await _importCustomizationBundleUseCase.execute(
        project: project,
        bundleContent: bundleContent,
        overwrite: request.overwrite,
        allowBuiltinShadow: request.allowBuiltinShadow,
        builtinAgentIds: _idsOf(
          _builtinEntriesOf(_agentEcosystemSnapshot.agents),
        ),
        builtinSkillIds: _idsOf(
          _builtinEntriesOf(_agentEcosystemSnapshot.skills),
        ),
        builtinSkillGroupIds: _idsOf(
          _builtinEntriesOf(_agentEcosystemSnapshot.skillGroups),
        ),
        builtinAgentGroupIds: _idsOf(
          _builtinEntriesOf(_agentEcosystemSnapshot.agentGroups),
        ),
      );
      if (!ValueReaders.boolValue(result['ok'])) {
        _updateEcosystemImportCommand(
          _ecosystemImportCommand?.copyWith(
            status:
                '生态包导入失败：${ValueReaders.stringValue(result["error"], "未知错误")}',
            previewSummary: previewText,
          ),
        );
        return;
      }
      _ecosystemImportCommand = null;
      await _refreshAgentEcosystem();
      _setAgentEcosystemStatus(
        '$previewText\n已导入 ${ValueReaders.stringList(result["changed_paths"]).length} 个文件，跳过 ${ValueReaders.stringList(result["skipped_paths"]).length} 个条目。',
      );
    } catch (error) {
      _updateEcosystemImportCommand(
        _ecosystemImportCommand?.copyWith(status: '生态包导入失败：$error'),
      );
    }
  }

  @override
  void onGenerateIndexRequested() async {
    // 中文注释: 索引生成统一调用共享 use case，同时补齐生态根目录索引和 exports 市场索引。
    final project = _currentProject;
    if (project == null) {
      _setAgentEcosystemStatus('请先创建或打开项目，再生成生态索引。');
      return;
    }
    try {
      final rootIndexPaths = await _generateCustomizationIndexesUseCase.execute(
        project,
      );
      final marketIndexResult = await _saveCustomizationMarketIndexUseCase
          .execute(project);
      final changedPaths = <String>[
        ...rootIndexPaths,
        ...ValueReaders.stringList(marketIndexResult['changed_paths']),
      ];
      _setAgentEcosystemStatus('已生成生态索引，共更新 ${changedPaths.length} 个文件。');
    } catch (error) {
      _setAgentEcosystemStatus('生成生态索引失败：$error');
    }
  }

  @override
  void onEcosystemTabSelected(String tabId) {
    // 中文注释: 生态页 tab 切换只改变本页视图模型，不跨页污染其他状态。
    _ecosystemEditorViewData = null;
    _agentEcosystemSnapshot = _agentEcosystemSnapshot.copyWith(
      activeTabId: tabId,
    );
    _refreshAgentEcosystemView();
  }

  @override
  void onEcosystemEntrySelected(String entryId) {
    // 中文注释: 条目选中只更新生态快照，不让展示组件自己维护重复的选中状态。
    _ecosystemEditorViewData = null;
    final nextSelections = Map<String, String>.from(
      _agentEcosystemSnapshot.selectedEntryIds,
    )..[_agentEcosystemSnapshot.activeTabId] = entryId;
    _agentEcosystemSnapshot = _agentEcosystemSnapshot.copyWith(
      selectedEntryIds: nextSelections,
    );
    _refreshAgentEcosystemView();
  }

  @override
  void onCreateAgentRequested() {
    // 中文注释: 创建智能体脚手架后立即写入项目目录，再复用文档工作区进行编辑。
    _createEcosystemEntry('agents');
  }

  @override
  void onCreateSkillRequested() {
    // 中文注释: 技能创建与智能体创建共用同一条计划+写盘链路，避免生态页再分叉一套保存逻辑。
    _createEcosystemEntry('skills');
  }

  @override
  void onCreateSkillGroupRequested() {
    // 中文注释: 技能组创建先落项目 JSON 文件，后续即使切换成 Markdown 也只需要换创建计划服务。
    _createEcosystemEntry('skill-groups');
  }

  @override
  void onCreateAgentGroupRequested() {
    // 中文注释: 智能体组和其他生态条目统一走项目文本写入用例，保证桌面与移动端路径策略一致。
    _createEcosystemEntry('agent-groups');
  }

  @override
  void onOpenEcosystemEntrySourceRequested(String entryId) {
    // 中文注释: 生态页打开源文件只认项目内相对路径，避免 UI 直接碰宿主绝对路径。
    _openEcosystemEntrySource(entryId);
  }

  @override
  void onEditEcosystemEntryRequested(String entryId) {
    // 中文注释: 编辑已有条目时先从项目内源文件恢复原始内容，确保表单不是只靠列表摘要拼出来。
    _showEcosystemEditor(entryId);
  }

  @override
  void onEcosystemEditorDismissed() {
    // 中文注释: 编辑弹层关闭只清理当前表单，不影响已加载好的生态快照。
    _updateEcosystemEditorViewData(null);
  }

  @override
  void onEcosystemEditorSubmitted(EcosystemEditorRequestViewData request) {
    // 中文注释: 编辑保存统一走“渲染计划 -> 写盘 -> 清理旧路径 -> 刷新快照”，避免 UI 直接操作文件系统。
    _saveEcosystemEditorRequest(request);
  }

  @override
  void onEcosystemEditorDeleteRequested(
    EcosystemEditorRequestViewData request,
  ) {
    // 中文注释: 删除只允许项目级条目，内置素材本身不会被这里改动。
    _deleteEcosystemEditorRequest(request);
  }

  Future<void> _refreshAgentEcosystem({
    String? selectedTabId,
    String? selectedEntryId,
  }) async {
    // 中文注释: 生态刷新收口在这里，项目级 agent/skill/group 与内置条目都在这一层统一聚合。
    final project = _currentProject;
    final builtinSkillGroups = const BuiltinSkillGroupCatalogService()
        .builtinGroups();
    final collaboratorCatalogService = BuiltinCollaboratorCatalogService();
    final builtinAgentGroups = collaboratorCatalogService
        .optionalCollaboratorGroups();
    final builtinCollaboratorAgents = collaboratorCatalogService
        .optionalCollaboratorProfiles();
    if (project == null) {
      _agentEcosystemSnapshot = _agentEcosystemSnapshot.copyWith(
        activeTabId: selectedTabId ?? _agentEcosystemSnapshot.activeTabId,
        agents: builtinCollaboratorAgents,
        skills: const <JsonMap>[],
        skillGroups: builtinSkillGroups,
        agentGroups: builtinAgentGroups,
        selectedEntryIds: _nextEcosystemSelections(
          activeTabId: selectedTabId ?? _agentEcosystemSnapshot.activeTabId,
          selectedEntryId: selectedEntryId,
          agents: builtinCollaboratorAgents,
          skills: const <JsonMap>[],
          skillGroups: builtinSkillGroups,
          agentGroups: builtinAgentGroups,
        ),
      );
      _refreshAgentEcosystemView();
      return;
    }
    final loadedAgents = _withProjectRelativePaths(
      await _loadAgentPackages(project),
      project,
    );
    final loadedSkills = _withProjectRelativePaths(
      await _loadSkillPackages(project),
      project,
    );
    final loadedSkillGroups = _withProjectRelativePaths(
      await _loadSkillGroups(project),
      project,
    );
    final loadedAgentGroups = _withProjectRelativePaths(
      await _loadAgentGroups(project),
      project,
    );
    final agents = _mergeEntriesById(loadedAgents, builtinCollaboratorAgents);
    final skills = _mergeEntriesById(loadedSkills, const <JsonMap>[]);
    final skillGroups = _mergeEntriesById(
      loadedSkillGroups,
      builtinSkillGroups,
    );
    final agentGroups = _mergeEntriesById(
      loadedAgentGroups,
      builtinAgentGroups,
    );
    final activeTabId = selectedTabId ?? _agentEcosystemSnapshot.activeTabId;
    _agentEcosystemSnapshot = _agentEcosystemSnapshot.copyWith(
      activeTabId: activeTabId,
      agents: agents,
      skills: skills,
      skillGroups: skillGroups,
      agentGroups: agentGroups,
      selectedEntryIds: _nextEcosystemSelections(
        activeTabId: activeTabId,
        selectedEntryId: selectedEntryId,
        agents: agents,
        skills: skills,
        skillGroups: skillGroups,
        agentGroups: agentGroups,
      ),
    );
    _refreshAgentEcosystemView();
  }

  void _refreshAgentEcosystemView() {
    final viewData = _agentEcosystemViewDataService
        .build(_agentEcosystemSnapshot)
        .copyWith(
          statusMessage: _agentEcosystemStatusMessage,
          importCommand: _ecosystemImportCommand,
          editorViewData: _ecosystemEditorViewData,
        );
    final settings = _settings;
    _viewModel = _viewModel.copyWith(agentEcosystem: viewData);
    if (settings != null) {
      _viewModel = _viewModel.copyWith(
        workbench: _viewModel.workbench.copyWith(
          modelOptions: _modelSelectorOptions(settings),
          agentLabel: _agentLabel(settings),
          agentOptions: _agentSelectorOptions(),
        ),
      );
    }
    _safeNotifyListeners();
  }

  void _setAgentEcosystemStatus(String message) {
    // 中文注释: 生态页状态提示统一收口在这里，避免刷新、导入、索引生成各自改视图字段。
    _agentEcosystemStatusMessage = message;
    _refreshAgentEcosystemView();
  }

  void _updateEcosystemImportCommand(EcosystemImportCommandViewData? command) {
    // 中文注释: 导入弹层状态更新统一走这里，便于后续替换成更通用的生态命令容器。
    _ecosystemImportCommand = command;
    _refreshAgentEcosystemView();
  }

  void _updateEcosystemEditorViewData(EcosystemEditorViewData? viewData) {
    // 中文注释: 编辑弹层状态单独维护，避免导入弹层与编辑弹层互相覆盖。
    _ecosystemEditorViewData = viewData;
    _refreshAgentEcosystemView();
  }

  List<JsonMap> _projectEntriesOf(List<JsonMap> entries) {
    // 中文注释: 项目级条目通过 project_relative_path 判断，方便导入预检复用当前生态快照。
    return entries
        .where(
          (entry) =>
              _stringValue(entry['project_relative_path']).trim().isNotEmpty,
        )
        .map(ValueReaders.deepCopyMap)
        .toList(growable: false);
  }

  List<JsonMap> _builtinEntriesOf(List<JsonMap> entries) {
    // 中文注释: 非项目路径条目视作内置或宿主内置素材，供导入预检识别遮蔽关系。
    return entries
        .where(
          (entry) =>
              _stringValue(entry['project_relative_path']).trim().isEmpty,
        )
        .map(ValueReaders.deepCopyMap)
        .toList(growable: false);
  }

  List<String> _idsOf(List<JsonMap> entries) {
    // 中文注释: 生态条目 ID 列表统一在这里抽取，避免导入调用点反复写同样的过滤逻辑。
    final result = <String>[];
    for (final entry in entries) {
      final id = _stringValue(entry['id']).trim();
      if (id.isNotEmpty && !result.contains(id)) {
        result.add(id);
      }
    }
    return result;
  }

  void _showWorkspaceCommand(WorkspaceCommandViewData command) {
    // 中文注释: 工作区命令弹层状态统一从这里进入，方便后续替换为全局弹层容器。
    _updateWorkbench(_viewModel.workbench.copyWith(workspaceCommand: command));
  }

  Future<void> _submitProjectInfoCommand(
    WorkspaceCommandRequestViewData request,
  ) async {
    final project = _currentProject;
    if (project == null) {
      _announce('请先打开项目。');
      return;
    }
    final cleanTitle = request.projectTitle.trim();
    try {
      await _updateProjectManifestUseCase.execute(
        project: project,
        title: cleanTitle.isEmpty ? project.name : cleanTitle,
        projectType: request.projectType.trim().isEmpty
            ? project.projectType
            : request.projectType.trim(),
        genre: request.genre,
        premise: request.premise,
        notes: request.notes,
      );
      onWorkspaceCommandDismissed();
      await _loadProject(project.rootPath);
      _announce('已更新项目信息。');
    } catch (error) {
      _announce('保存项目信息失败：$error');
    }
  }

  Future<void> _submitCreateFileCommand(
    WorkspaceCommandRequestViewData request,
  ) async {
    final project = _currentProject;
    if (project == null) {
      _announce('请先打开项目。');
      return;
    }
    final relativePath = _joinedProjectPath(
      request.relativePath,
      request.entryName,
      defaultFileName: 'new_file.md',
    );
    final initialContent = request.content.trim().isEmpty
        ? '# ${_displayNameOf(relativePath)}\n\n'
        : request.content;
    try {
      final result = await _createProjectEntryUseCase.execute(
        project: project,
        relativePath: relativePath,
        content: initialContent,
      );
      if (!_boolValue(result['ok'])) {
        _announce(_stringValue(result['error'], '创建文件失败。'));
        return;
      }
      final createdPath = _stringValue(result['relative_path']);
      onWorkspaceCommandDismissed();
      final resourceEntries = await _reloadResourceEntries(
        selectedId: createdPath,
      );
      _updateWorkbench(
        _viewModel.workbench.copyWith(resourceEntries: resourceEntries),
      );
      await _openResource(createdPath);
      _announce('已创建文件：$createdPath');
    } catch (error) {
      _announce('创建文件失败：$error');
    }
  }

  Future<void> _submitCreateFolderCommand(
    WorkspaceCommandRequestViewData request,
  ) async {
    final project = _currentProject;
    if (project == null) {
      _announce('请先打开项目。');
      return;
    }
    final relativePath = _joinedProjectPath(
      request.relativePath,
      request.entryName,
      defaultFileName: 'new_folder',
    );
    try {
      final result = await _createProjectEntryUseCase.execute(
        project: project,
        relativePath: relativePath,
        isFolder: true,
      );
      if (!_boolValue(result['ok'])) {
        _announce(_stringValue(result['error'], '创建目录失败。'));
        return;
      }
      final createdPath = _stringValue(result['relative_path']);
      onWorkspaceCommandDismissed();
      final resourceEntries = await _reloadResourceEntries(
        selectedId: createdPath,
      );
      _updateWorkbench(
        _viewModel.workbench.copyWith(
          resourceEntries: resourceEntries,
          generationStatus: '已创建目录：$createdPath',
        ),
      );
    } catch (error) {
      _announce('创建目录失败：$error');
    }
  }

  Future<void> _submitImportFilesCommand(
    WorkspaceCommandRequestViewData request,
  ) async {
    final project = _currentProject;
    if (project == null) {
      _announce('请先打开项目。');
      return;
    }
    final sourcePaths = request.sourcePathsText
        .split(RegExp(r'\r?\n'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    if (sourcePaths.isEmpty) {
      _announce('请至少填写一个要导入的文件路径。');
      return;
    }
    try {
      final result = await _importProjectFilesUseCase.execute(
        project: project,
        sourcePaths: sourcePaths,
        targetDirectory: request.targetDirectory,
      );
      if (!_boolValue(result['ok'])) {
        _announce(
          _stringValue(result['error'], _stringValue(result['summary'])),
        );
        return;
      }
      final importedPaths = ValueReaders.stringList(result['imported_paths']);
      onWorkspaceCommandDismissed();
      final selectedId = importedPaths.isEmpty ? '' : importedPaths.first;
      final resourceEntries = await _reloadResourceEntries(
        selectedId: selectedId,
      );
      _updateWorkbench(
        _viewModel.workbench.copyWith(resourceEntries: resourceEntries),
      );
      if (selectedId.isNotEmpty) {
        await _openResource(selectedId);
      }
      _announce(_stringValue(result['summary'], '导入完成。'));
    } catch (error) {
      _announce('导入文件失败：$error');
    }
  }

  Future<void> _createEcosystemEntry(String kind) async {
    // 中文注释: 生态条目创建统一走“生成计划 -> 写入项目 -> 刷新快照 -> 打开源文件”的闭环。
    final project = _currentProject;
    if (project == null) {
      _announce('请先打开一个项目，再创建项目内生态条目。');
      return;
    }
    final plan = _ecosystemEntryCreationPlanService.createPlan(kind);
    try {
      await _writeProjectTextFileUseCase.execute(
        project: project,
        relativePath: plan.relativePath,
        content: plan.content,
      );
      await _refreshAgentEcosystem(
        selectedTabId: plan.kind,
        selectedEntryId: plan.entryId,
      );
      showWorkbench();
      await _openResource(plan.relativePath);
      _announce('已创建 ${_ecosystemKindLabel(plan.kind)}：${plan.title}');
    } catch (error) {
      _announce('创建生态条目失败：$error');
    }
  }

  Future<void> _openEcosystemEntrySource(String entryId) async {
    // 中文注释: 生态源文件打开统一从当前快照反查，避免详情面板自己理解项目目录结构。
    final entry = _selectedEcosystemSnapshotEntry(entryId);
    if (entry == null) {
      _announce('未找到要打开的生态条目。');
      return;
    }
    final projectRelativePath = _stringValue(entry['project_relative_path']);
    if (projectRelativePath.trim().isEmpty) {
      _announce('当前条目没有项目内可编辑源文件。');
      return;
    }
    showWorkbench();
    await _openResource(projectRelativePath);
  }

  Future<void> _showEcosystemEditor(String entryId) async {
    final project = _currentProject;
    if (project == null) {
      _setAgentEcosystemStatus('请先创建或打开项目。');
      return;
    }
    final entry = _selectedEcosystemSnapshotEntry(entryId);
    if (entry == null) {
      _setAgentEcosystemStatus('未找到要编辑的生态条目。');
      return;
    }
    final kind = _agentEcosystemSnapshot.activeTabId;
    final relativePath = _stringValue(entry['project_relative_path']).trim();
    if (relativePath.isEmpty) {
      _setAgentEcosystemStatus('当前条目不是项目级条目，不能直接编辑。');
      return;
    }
    final sourceContent =
        await _projectToolHostPort.readTextFile(
          project.rootPath,
          relativePath,
        ) ??
        '';
    final editorViewData = _ecosystemEntryEditorService.buildForEntry(
      entry,
      kind: kind,
      sourceContent: sourceContent,
    );
    _updateEcosystemEditorViewData(editorViewData);
  }

  Future<void> _saveEcosystemEditorRequest(
    EcosystemEditorRequestViewData request,
  ) async {
    final project = _currentProject;
    if (project == null) {
      _setAgentEcosystemStatus('请先创建或打开项目。');
      return;
    }
    try {
      final plan = _ecosystemEntryEditorService.buildSavePlan(request);
      await _writeProjectTextFileUseCase.execute(
        project: project,
        relativePath: plan.relativePath,
        content: plan.content,
      );
      final oldRelativePath = plan.oldRelativePath.trim();
      if (oldRelativePath.isNotEmpty &&
          oldRelativePath != plan.relativePath &&
          await _projectToolHostPort.entryExists(
            project.rootPath,
            oldRelativePath,
          )) {
        await _projectToolHostPort.deleteEntry(
          project.rootPath,
          oldRelativePath,
        );
      }
      _updateEcosystemEditorViewData(null);
      await _refreshAgentEcosystem(
        selectedTabId: request.kind,
        selectedEntryId: request.entryId,
      );
      _setAgentEcosystemStatus(
        '已保存${_ecosystemKindLabel(request.kind)}：${request.name.trim().isEmpty ? request.entryId : request.name.trim()}',
      );
    } catch (error) {
      _updateEcosystemEditorViewData(
        _ecosystemEditorViewData?.copyWith(statusMessage: '保存失败：$error'),
      );
    }
  }

  Future<void> _deleteEcosystemEditorRequest(
    EcosystemEditorRequestViewData request,
  ) async {
    final project = _currentProject;
    if (project == null) {
      _setAgentEcosystemStatus('请先创建或打开项目。');
      return;
    }
    final relativePath = request.originalRelativePath.trim();
    if (relativePath.isEmpty) {
      _updateEcosystemEditorViewData(
        _ecosystemEditorViewData?.copyWith(statusMessage: '当前条目没有项目级源文件，不能删除。'),
      );
      return;
    }
    try {
      await _projectToolHostPort.deleteEntry(project.rootPath, relativePath);
      _updateEcosystemEditorViewData(null);
      await _refreshAgentEcosystem(selectedTabId: request.kind);
      _setAgentEcosystemStatus(
        '已删除项目级${_ecosystemKindLabel(request.kind)}：${request.entryId}',
      );
    } catch (error) {
      _updateEcosystemEditorViewData(
        _ecosystemEditorViewData?.copyWith(statusMessage: '删除失败：$error'),
      );
    }
  }

  List<JsonMap> _mergeEntriesById(
    List<JsonMap> primaryEntries,
    List<JsonMap> secondaryEntries,
  ) {
    // 中文注释: 生态列表合并统一按 id 去重，优先保留更具体的项目/包数据，再补充内置协作素材。
    final byId = <String, JsonMap>{};
    for (final entry in secondaryEntries) {
      final id = ValueReaders.stringValue(entry['id']).trim();
      if (id.isEmpty) {
        continue;
      }
      byId[id] = entry;
    }
    for (final entry in primaryEntries) {
      final id = ValueReaders.stringValue(entry['id']).trim();
      if (id.isEmpty) {
        continue;
      }
      byId[id] = entry;
    }
    return byId.values.toList(growable: false);
  }

  @override
  void onProjectCollectionBackRequested() {
    // 中文注释: 集合页返回统一回到工作台，避免集合页自己持有全局导航状态。
    showWorkbench();
  }

  @override
  void onProjectCollectionRefreshRequested() {
    // 中文注释: 刷新集合页会重新从当前项目资源树重读对应目录内容。
    _showProjectCollection(_projectCollectionSnapshot.kind);
  }

  @override
  void onProjectCollectionEntrySelected(String entryId) {
    // 中文注释: 集合条目选中只更新当前集合快照和详情正文。
    _projectCollectionSnapshot = ProjectCollectionSnapshot(
      kind: _projectCollectionSnapshot.kind,
      title: _projectCollectionSnapshot.title,
      description: _projectCollectionSnapshot.description,
      entries: _projectCollectionSnapshot.entries,
      selectedEntryId: entryId,
    );
    _refreshProjectCollectionView();
  }

  @override
  void onProjectCollectionOpenRequested(String entryId) {
    // 中文注释: 集合页打开源文件统一回到工作台并复用现有打开资源链路。
    showWorkbench();
    _openResource(entryId);
  }

  @override
  void onProjectCollectionCreateRequested() {
    // 中文注释: 不同集合的新建动作映射到不同项目目录，避免页面自己写路径策略。
    showWorkbench();
    switch (_projectCollectionSnapshot.kind) {
      case 'reviews':
        _showWorkspaceCommand(
          const WorkspaceCommandViewData(
            mode: WorkspaceCommandMode.createFile,
            title: '新建审稿文件',
            description: '在 reviews/ 下创建一个新的审稿条目。',
            confirmLabel: '创建审稿文件',
            status: '',
            projectTitle: '',
            projectType: '',
            genre: '',
            premise: '',
            notes: '',
            relativePath: 'reviews/general',
            entryName: 'review_note.md',
            content: '# 审稿记录\n\n',
            sourcePathsText: '',
            targetDirectory: '',
          ),
        );
        return;
      case 'templates':
        _showWorkspaceCommand(
          const WorkspaceCommandViewData(
            mode: WorkspaceCommandMode.createFile,
            title: '新建模板',
            description: '在 prompts/ 下创建一个新的提示词模板文件。',
            confirmLabel: '创建模板',
            status: '',
            projectTitle: '',
            projectType: '',
            genre: '',
            premise: '',
            notes: '',
            relativePath: 'prompts',
            entryName: 'new_template.json',
            content:
                '{\n  "id": "new_template",\n  "name": "新模板",\n  "scope": "project",\n  "description": "",\n  "content": ""\n}\n',
            sourcePathsText: '',
            targetDirectory: '',
          ),
        );
        return;
      case 'tasks':
      default:
        _showWorkspaceCommand(
          const WorkspaceCommandViewData(
            mode: WorkspaceCommandMode.createFile,
            title: '新建任务文件',
            description: '在 tasks/ 下创建一个新的任务文件。',
            confirmLabel: '创建任务',
            status: '',
            projectTitle: '',
            projectType: '',
            genre: '',
            premise: '',
            notes: '',
            relativePath: 'tasks',
            entryName: 'new_task.task.json',
            content:
                '{\n  "id": "task_new",\n  "title": "新任务",\n  "task_type": "chapter",\n  "goal": "",\n  "status": "pending"\n}\n',
            sourcePathsText: '',
            targetDirectory: '',
          ),
        );
        return;
    }
  }

  Future<void> _showProjectCollection(String kind) async {
    // 中文注释: 任务、审稿、模板三类页面统一从同一集合加载服务读取，避免重复造三套目录浏览逻辑。
    final project = _currentProject;
    if (project == null) {
      _announce('请先打开项目。');
      return;
    }
    final snapshot = await _projectCollectionLoaderService.load(
      kind: kind,
      project: project,
      resourceEntries: _viewModel.workbench.resourceEntries,
      readFile: (currentProject, relativePath) =>
          _readProjectFileUseCase.execute(currentProject, relativePath),
      selectedEntryId: _projectCollectionSnapshot.kind == kind
          ? _projectCollectionSnapshot.selectedEntryId
          : '',
    );
    _projectCollectionSnapshot = snapshot;
    _viewModel = _viewModel.copyWith(
      destination: AppDestination.projectCollection,
    );
    await _refreshProjectCollectionView();
  }

  Future<void> _refreshProjectCollectionView() async {
    final selectedId = _projectCollectionSnapshot.selectedEntryId;
    final detailPath = selectedId;
    final detailBody = await _projectCollectionDetailBody(selectedId);
    final entries = _projectCollectionSnapshot.entries
        .map(
          (entry) => ProjectCollectionEntryViewData(
            id: _stringValue(entry['id']),
            title: _stringValue(entry['title']),
            subtitle: _stringValue(entry['subtitle']),
            badge: _stringValue(entry['badge']),
            description: _stringValue(entry['description']),
            relativePath: _stringValue(entry['relative_path']),
            isSelected: _stringValue(entry['id']) == selectedId,
          ),
        )
        .toList(growable: false);
    _viewModel = _viewModel.copyWith(
      projectCollection: ProjectCollectionViewData(
        kind: _projectCollectionSnapshot.kind,
        title: _projectCollectionSnapshot.title,
        description: _projectCollectionSnapshot.description,
        entries: entries,
        selectedEntryId: selectedId,
        detailPath: detailPath,
        detailBody: detailBody,
        status: entries.isEmpty ? '当前目录还没有可展示的条目。' : '',
      ),
    );
    _safeNotifyListeners();
  }

  Future<String> _projectCollectionDetailBody(String relativePath) async {
    final project = _currentProject;
    if (project == null || relativePath.trim().isEmpty) {
      return '';
    }
    return await _readProjectFileUseCase.execute(project, relativePath) ?? '';
  }

  @override
  void onTaskCenterBackRequested() {
    // 中文注释: 任务中心返回只切回工作台，不额外改动当前项目和任务状态。
    showWorkbench();
  }

  @override
  void onTaskCenterRefreshRequested() {
    // 中文注释: 刷新动作统一重读项目任务、调度和预检摘要，避免页面局部各刷各的。
    _refreshTaskCenter();
  }

  @override
  void onTaskCenterTaskSelected(String taskId) {
    // 中文注释: 选中任务只变更当前详情定位，不触发任何执行副作用。
    _selectedTaskId = taskId;
    _refreshTaskCenterView();
  }

  @override
  void onTaskCenterTaskOpened(String taskId) {
    // 中文注释: 从任务中心打开任务文件仍然复用工作台资源打开链，保持文件查看入口单一。
    showWorkbench();
    _openResource(taskId);
  }

  @override
  void onTaskCenterLongTaskRunSelected(String relativePath) {
    // 中文注释: 运行记录切换只改变当前日志面板选中项，不触发任何任务状态变更。
    _selectedLongTaskRunPath = relativePath.trim();
    _refreshTaskCenterView();
  }

  @override
  void onTaskCenterTaskQueueRunSelected(String relativePath) {
    // 中文注释: 队列运行记录切换与长任务运行记录分开保存，便于回放不同层级的日志。
    _selectedTaskQueueRunPath = relativePath.trim();
    _refreshTaskCenterView();
  }

  @override
  void onTaskCenterWorkflowCreateSubmitted(
    TaskWorkflowCreateRequestViewData request,
  ) async {
    // 中文注释: 长任务开局只负责生成计划与任务文件，真正执行仍交给后续单步或队列动作。
    final project = _currentProject;
    if (project == null) {
      await _refreshTaskCenter(status: '请先创建或打开项目。');
      return;
    }
    _taskCenterStatusMessage = '正在生成长任务队列...';
    await _refreshTaskCenterView();
    final result = await _workflowRuntimeService.createLongTaskWorkflow(
      project,
      request.mode.trim().isEmpty
          ? TaskRuntimeConstants.modeHumanOutlineAiDraft
          : request.mode.trim(),
      options: <String, Object?>{
        'outline_path': request.outlinePath.trim(),
        'seed_prompt': request.seedPrompt.trim(),
        'chapter_count': request.chapterCount,
        'checkpoint_interval': request.checkpointInterval,
      },
    );
    await _syncWorkbenchResources();
    _selectedTaskId = ValueReaders.stringValue(
      ValueReaders.objectList(result['created_tasks']).isEmpty
          ? ''
          : ValueReaders.mapValue(
              ValueReaders.objectList(result['created_tasks']).first,
            )['relative_path'],
    );
    await _refreshTaskCenter(
      status: _resultMessage(result, success: '长任务队列已生成。'),
    );
  }

  @override
  void onTaskCenterSavePlanRequested() {
    _runTaskCenterSelectorCommand(
      pendingMessage: '正在生成任务计划...',
      successMessage: '任务计划已生成。',
      operation: (project, selector, settings) {
        return _workflowRuntimeService.saveWorkflowTaskPlan(project, selector);
      },
    );
  }

  @override
  void onTaskCenterSaveChainSnapshotRequested() {
    _runTaskCenterProjectCommand(
      pendingMessage: '正在保存链路快照...',
      successMessage: '任务链路快照已保存。',
      operation: (project, settings) {
        return _workflowRuntimeService.saveWorkflowChainSnapshot(project);
      },
    );
  }

  @override
  void onTaskCenterPrepareExecutionRequested() {
    _runTaskCenterSelectorCommand(
      pendingMessage: '正在准备执行包...',
      successMessage: '执行包已准备完成。',
      operation: (project, selector, settings) {
        return _workflowRuntimeService.prepareWorkflowTaskExecution(
          project,
          selector,
          contextSettings:
              settings?.contextSettings ?? const <String, Object?>{},
        );
      },
      requireSettings: false,
    );
  }

  @override
  void onTaskCenterRunSelectedOnceRequested() {
    _runTaskCenterSelectorCommand(
      pendingMessage: '正在执行当前任务...',
      successMessage: '当前任务已执行一轮。',
      operation: (project, selector, settings) {
        if (settings == null) {
          return Future<JsonMap>.value(<String, Object?>{
            'ok': false,
            'error': '设置尚未加载完成。',
          });
        }
        return _workflowRuntimeService.runWorkflowTaskOnce(
          project,
          settings,
          selector,
        );
      },
      requireSettings: true,
    );
  }

  @override
  void onTaskCenterRunNextOnceRequested() {
    _runTaskCenterProjectCommand(
      pendingMessage: '正在执行下一任务...',
      successMessage: '下一任务已执行一轮。',
      operation: (project, settings) {
        if (settings == null) {
          return Future<JsonMap>.value(<String, Object?>{
            'ok': false,
            'error': '设置尚未加载完成。',
          });
        }
        return _workflowRuntimeService.runNextWorkflowTaskOnce(
          project,
          settings,
        );
      },
      requireSettings: true,
    );
  }

  @override
  void onTaskCenterRunQueueRequested() {
    _runTaskCenterProjectCommand(
      pendingMessage: '正在启动受控连续运行...',
      successMessage: '队列运行已推进。',
      operation: (project, settings) {
        if (settings == null) {
          return Future<JsonMap>.value(<String, Object?>{
            'ok': false,
            'error': '设置尚未加载完成。',
          });
        }
        return _workflowRuntimeService.runWorkflowTaskQueue(project, settings);
      },
      requireSettings: true,
    );
  }

  @override
  void onTaskCenterPostprocessSelectedRequested() {
    _runTaskCenterSelectorCommand(
      pendingMessage: '正在执行当前任务后处理...',
      successMessage: '当前任务后处理已完成一轮。',
      operation: (project, selector, settings) {
        if (settings == null) {
          return Future<JsonMap>.value(<String, Object?>{
            'ok': false,
            'error': '设置尚未加载完成。',
          });
        }
        return _workflowRuntimeService.runWorkflowTaskPostprocessOnce(
          project,
          settings,
          selector,
        );
      },
      requireSettings: true,
    );
  }

  @override
  void onTaskCenterPostprocessNextRequested() {
    _runTaskCenterProjectCommand(
      pendingMessage: '正在执行下一条后处理...',
      successMessage: '下一条后处理已完成一轮。',
      operation: (project, settings) {
        if (settings == null) {
          return Future<JsonMap>.value(<String, Object?>{
            'ok': false,
            'error': '设置尚未加载完成。',
          });
        }
        return _workflowRuntimeService.runNextWorkflowTaskPostprocessOnce(
          project,
          settings,
        );
      },
      requireSettings: true,
    );
  }

  @override
  void onTaskCenterMarkSucceededRequested() {
    _runTaskCenterSelectorCommand(
      pendingMessage: '正在标记任务完成...',
      successMessage: '任务已标记完成。',
      operation: (project, selector, settings) {
        return _workflowRuntimeService.transitionWorkflowTask(
          project,
          selector,
          TaskRuntimeConstants.statusSucceeded,
          note: '用户在任务中心手动确认完成。',
        );
      },
    );
  }

  @override
  void onTaskCenterCompleteAndRunNextRequested() {
    _runTaskCenterSelectorCommand(
      pendingMessage: '正在完成当前任务并推进下一条...',
      successMessage: '已完成当前任务，并尝试继续下一条。',
      operation: (project, selector, settings) {
        if (settings == null) {
          return Future<JsonMap>.value(<String, Object?>{
            'ok': false,
            'error': '设置尚未加载完成。',
          });
        }
        return _workflowRuntimeService.completeWorkflowTaskAndRunNext(
          project,
          settings,
          selector,
        );
      },
      requireSettings: true,
    );
  }

  @override
  void onTaskCenterAcceptRevisionRequested() {
    _runTaskCenterSelectorCommand(
      pendingMessage: '正在接受修复结果...',
      successMessage: '修复结果已接受。',
      operation: (project, selector, settings) {
        return _workflowRuntimeService.acceptRevisionTask(project, selector);
      },
    );
  }

  @override
  void onTaskCenterRollbackRevisionRequested() {
    _runTaskCenterSelectorCommand(
      pendingMessage: '正在回滚修复结果...',
      successMessage: '修复结果已回滚。',
      operation: (project, selector, settings) {
        return _workflowRuntimeService.rollbackRevisionTask(project, selector);
      },
    );
  }

  @override
  void onTaskCenterPauseRequested() {
    _runTaskCenterRecentRunCommand(
      pendingMessage: '正在暂停长任务运行...',
      successMessage: '长任务运行已暂停。',
      operation: (project, settings, runPath) {
        return _workflowRuntimeService.pauseLongTaskRun(project, runPath);
      },
    );
  }

  @override
  void onTaskCenterResumeRequested() {
    _runTaskCenterRecentRunCommand(
      pendingMessage: '正在恢复长任务运行...',
      successMessage: '长任务运行已恢复推进。',
      operation: (project, settings, runPath) {
        if (settings == null) {
          return Future<JsonMap>.value(<String, Object?>{
            'ok': false,
            'error': '设置尚未加载完成。',
          });
        }
        return _workflowRuntimeService.resumeLongTaskRun(
          project,
          settings,
          runPath,
        );
      },
      requireSettings: true,
    );
  }

  @override
  void onTaskCenterRetryRequested() {
    _runTaskCenterSelectorCommand(
      pendingMessage: '正在标记重试...',
      successMessage: '任务已进入重试状态。',
      operation: (project, selector, settings) {
        return _workflowRuntimeService.transitionWorkflowTask(
          project,
          selector,
          TaskRuntimeConstants.statusRetrying,
          note: '用户要求重试当前任务。',
        );
      },
    );
  }

  @override
  void onTaskCenterCancelRequested() {
    _runTaskCenterSelectorCommand(
      pendingMessage: '正在取消任务...',
      successMessage: '任务已取消。',
      operation: (project, selector, settings) {
        return _workflowRuntimeService.transitionWorkflowTask(
          project,
          selector,
          TaskRuntimeConstants.statusCancelled,
          note: '用户在任务中心取消任务。',
        );
      },
    );
  }

  @override
  void onReviewCenterBackRequested() {
    // 中文注释: 审稿中心返回只切回工作台，不在这里重置筛选器，方便用户稍后再回来继续看。
    showWorkbench();
  }

  @override
  void onReviewCenterRefreshRequested() {
    // 中文注释: 报告刷新统一重读 reviews/ 目录和当前筛选器。
    _refreshReviewCenter();
  }

  @override
  void onReviewCenterEntrySelected(String entryId) {
    // 中文注释: 选中报告只改变详情定位，不产生任何写盘副作用。
    _selectedReviewEntryId = entryId;
    _refreshReviewCenterView();
  }

  @override
  void onReviewCenterEntryOpened(String entryId) {
    // 中文注释: 审稿页打开报告文件时，仍旧回到工作台统一展示文档。
    showWorkbench();
    _openResource(entryId);
  }

  @override
  void onReviewCenterCreateCurrentReviewRequested() {
    // 中文注释: 当前文件一键审稿从审稿页和文档工具栏共用同一入口，避免重复的任务构建规则。
    _createReviewTaskForCurrentDocument();
  }

  @override
  void onReviewCenterCreateRepairTaskRequested() async {
    // 中文注释: 修复任务从当前选中报告生成，真正执行留给任务中心统一控制。
    final project = _currentProject;
    if (project == null) {
      await _refreshReviewCenter(status: '请先创建或打开项目。');
      return;
    }
    final reportPath = _selectedReviewEntryId.trim();
    if (reportPath.isEmpty) {
      await _refreshReviewCenter(status: '请先选择一份审稿报告。');
      return;
    }
    _reviewCenterStatusMessage = '正在生成修复任务...';
    await _refreshReviewCenterView();
    final result = await _reviewReportService.createReviewRepairTask(
      project,
      reportPath,
    );
    await _syncWorkbenchResources();
    if (ValueReaders.boolValue(result['ok'])) {
      _selectedTaskId = ValueReaders.stringValue(result['relative_path']);
      await _refreshTaskCenter(status: '已从审稿报告生成修复任务。');
      _viewModel = _viewModel.copyWith(destination: AppDestination.taskCenter);
      _safeNotifyListeners();
      return;
    }
    await _refreshReviewCenter(
      status: _resultMessage(result, success: '已生成修复任务。'),
    );
  }

  @override
  void onReviewCenterFilterSubmitted({
    required String reviewType,
    required String scope,
    required String sourcePath,
  }) {
    // 中文注释: 筛选条件只在控制器内集中保存，避免页面自己记忆过滤状态。
    _reviewTypeFilter = reviewType.trim();
    _reviewScopeFilter = scope.trim();
    _reviewSourceFilter = sourcePath.trim();
    _refreshReviewCenter();
  }

  @override
  void onReviewCenterFilterCleared() {
    // 中文注释: 清空筛选会恢复全量报告列表，但不清掉当前项目。
    _reviewTypeFilter = '';
    _reviewScopeFilter = '';
    _reviewSourceFilter = '';
    _refreshReviewCenter();
  }

  @override
  void onPromptTemplatesBackRequested() {
    // 中文注释: 模板页返回时只切回工作台，让模板编辑状态保留在控制器里便于稍后继续。
    showWorkbench();
  }

  @override
  void onPromptTemplatesRefreshRequested() {
    // 中文注释: 刷新模板页会重读 merged templates，保证内置与项目覆盖视图一致。
    _refreshPromptTemplates();
  }

  @override
  void onPromptTemplatesTemplateSelected(String templateId) {
    // 中文注释: 模板选中只更新编辑器内容，不立即写盘。
    _selectedPromptTemplateId = templateId;
    _selectedPromptTemplate = _templateById(templateId);
    _promptTemplatePreviewText = '';
    _refreshPromptTemplatesView();
  }

  @override
  void onPromptTemplatesNewRequested() {
    // 中文注释: 新建模板时切到空编辑器，但不立刻生成 prompts/ 文件。
    _selectedPromptTemplateId = '';
    _selectedPromptTemplate = const <String, Object?>{};
    _promptTemplatePreviewText = '';
    _promptTemplatesStatusMessage = '正在创建新的项目模板。';
    _refreshPromptTemplatesView();
  }

  @override
  void onPromptTemplatesSaveRequested(
    PromptTemplateEditorRequestViewData request,
  ) async {
    // 中文注释: 保存模板统一走项目模板服务，路径规则和规范化交给共享层处理。
    final project = _currentProject;
    if (project == null) {
      await _refreshPromptTemplates(status: '请先创建或打开项目。');
      return;
    }
    final template = _templateRequestToMap(request);
    final result = await _promptTemplateService.saveTemplate(project, template);
    await _syncWorkbenchResources();
    if (ValueReaders.boolValue(result['ok'])) {
      _selectedPromptTemplateId = ValueReaders.stringValue(
        ValueReaders.mapValue(result['template'])['id'],
      );
      _selectedPromptTemplate = ValueReaders.mapValue(result['template']);
    }
    await _refreshPromptTemplates(
      status: _resultMessage(result, success: '模板已保存。'),
    );
  }

  @override
  void onPromptTemplatesPreviewRequested(
    PromptTemplateEditorRequestViewData request,
  ) {
    // 中文注释: 预览允许基于未保存编辑内容渲染，不必强迫用户先落盘再查看效果。
    final variables = _jsonMapFromText(request.variablesJson);
    if (variables == null) {
      _promptTemplatesStatusMessage = '预览变量必须是合法 JSON 对象。';
      _promptTemplatePreviewText = '';
      _selectedPromptTemplate = _templateRequestToMap(request);
      _refreshPromptTemplatesView();
      return;
    }
    final preview = _promptTemplatePreviewService.previewTemplate(
      _templateRequestToMap(request),
      variables,
    );
    _selectedPromptTemplate = ValueReaders.mapValue(preview['template']);
    _selectedPromptTemplateId = ValueReaders.stringValue(
      _selectedPromptTemplate['id'],
    );
    _promptTemplatePreviewText = ValueReaders.stringValue(preview['content']);
    _promptTemplatesStatusMessage = _resultMessage(
      preview,
      success: '模板预览已更新。',
    );
    _refreshPromptTemplatesView();
  }

  @override
  void onPromptTemplatesRestoreRequested(String templateId) async {
    // 中文注释: 恢复内置模板会写成项目覆盖，以便用户继续在 prompts/ 里二次调整。
    final project = _currentProject;
    if (project == null) {
      await _refreshPromptTemplates(status: '请先创建或打开项目。');
      return;
    }
    final result = await _promptTemplateService.restoreDefaultTemplate(
      project,
      templateId,
    );
    await _syncWorkbenchResources();
    if (ValueReaders.boolValue(result['ok'])) {
      _selectedPromptTemplateId = templateId;
    }
    await _refreshPromptTemplates(
      status: _resultMessage(result, success: '已恢复为内置模板。'),
    );
  }

  @override
  void onPromptTemplatesDeleteRequested(String templateId) async {
    // 中文注释: 删除只移除项目覆盖，不删除内置模板基线。
    final project = _currentProject;
    if (project == null) {
      await _refreshPromptTemplates(status: '请先创建或打开项目。');
      return;
    }
    final result = await _promptTemplateService.deleteProjectTemplate(
      project,
      templateId,
    );
    await _syncWorkbenchResources();
    if (ValueReaders.boolValue(result['ok'])) {
      _selectedPromptTemplateId = templateId;
      _selectedPromptTemplate = const <String, Object?>{};
      _promptTemplatePreviewText = '';
    }
    await _refreshPromptTemplates(
      status: _resultMessage(result, success: '项目模板覆盖已删除。'),
    );
  }

  Future<void> _refreshTaskCenter({String? status}) async {
    // 中文注释: 任务中心刷新统一拉取任务列表、预检和调度摘要，保证多个按钮回到同一页面快照口径。
    final project = _currentProject;
    if (project == null) {
      _taskCenterTasks = const <JsonMap>[];
      _selectedTaskId = '';
      _viewModel = _viewModel.copyWith(
        taskCenter: _taskCenterViewDataService.build(
          tasks: const <JsonMap>[],
          modeDefinitions: _workflowRuntimeService.listTaskRuntimeModes(),
          selectedTaskId: '',
          detailBody: '请先创建或打开项目。任务只读取当前项目目录，不会跨项目共享。',
          queueSummary: '',
          schedulerSummary: '',
          chainMarkdown: '',
          longTaskRuns: const <JsonMap>[],
          taskQueueRuns: const <JsonMap>[],
          selectedLongTaskRunPath: '',
          selectedTaskQueueRunPath: '',
          longTaskRunLog: '',
          taskQueueRunLog: '',
          status: status ?? '请先创建或打开项目。',
        ),
      );
      _safeNotifyListeners();
      return;
    }
    _taskCenterTasks = await _workflowRuntimeService.listWorkflowTasks(project);
    if (_selectedTaskId.trim().isEmpty && _taskCenterTasks.isNotEmpty) {
      _selectedTaskId = ValueReaders.stringValue(
        _taskCenterTasks.first['relative_path'],
      );
    }
    _taskCenterStatusMessage = status ?? _taskCenterStatusMessage;
    await _refreshTaskCenterView();
  }

  Future<void> _refreshTaskCenterView() async {
    // 中文注释: 任务中心视图重建只做投影和少量附加读取，不在页面构建阶段碰共享服务。
    final project = _currentProject;
    if (project == null) {
      return;
    }
    final chainView = await _workflowRuntimeService.workflowChainView(project);
    final preflight = await _workflowRuntimeService.taskQueuePreflight(project);
    final scheduler = await _workflowRuntimeService.longTaskSchedulerPlan(
      project,
    );
    final longTaskRuns = await _workflowRuntimeService.listLongTaskRuns(
      project,
      limit: 12,
    );
    final taskQueueRuns = await _workflowRuntimeService.listTaskQueueRuns(
      project,
      limit: 12,
    );
    if (_selectedLongTaskRunPath.trim().isNotEmpty &&
        !longTaskRuns.any(
          (record) =>
              ValueReaders.stringValue(record['relative_path']) ==
              _selectedLongTaskRunPath,
        )) {
      _selectedLongTaskRunPath = '';
    }
    if (_selectedTaskQueueRunPath.trim().isNotEmpty &&
        !taskQueueRuns.any(
          (record) =>
              ValueReaders.stringValue(record['relative_path']) ==
              _selectedTaskQueueRunPath,
        )) {
      _selectedTaskQueueRunPath = '';
    }
    if (_selectedLongTaskRunPath.trim().isEmpty && longTaskRuns.isNotEmpty) {
      _selectedLongTaskRunPath = ValueReaders.stringValue(
        longTaskRuns.first['relative_path'],
      );
    }
    if (_selectedTaskQueueRunPath.trim().isEmpty && taskQueueRuns.isNotEmpty) {
      _selectedTaskQueueRunPath = ValueReaders.stringValue(
        taskQueueRuns.first['relative_path'],
      );
    }
    final selectedTask = _taskByPath(_selectedTaskId);
    JsonMap execution = const <String, Object?>{};
    if (selectedTask.isNotEmpty) {
      execution = await _workflowRuntimeService.loadWorkflowTaskExecution(
        project,
        _taskSelector(selectedTask),
      );
    }
    final selectedLongRun = _selectedLongTaskRunPath.trim().isEmpty
        ? const <String, Object?>{}
        : await _workflowRuntimeService.loadLongTaskRun(
            project,
            _selectedLongTaskRunPath,
          );
    final selectedQueueRun = _selectedTaskQueueRunPath.trim().isEmpty
        ? const <String, Object?>{}
        : await _workflowRuntimeService.loadTaskQueueRun(
            project,
            _selectedTaskQueueRunPath,
          );
    _viewModel = _viewModel.copyWith(
      taskCenter: _taskCenterViewDataService.build(
        tasks: _taskCenterTasks,
        modeDefinitions: _workflowRuntimeService.listTaskRuntimeModes(),
        selectedTaskId: _selectedTaskId,
        detailBody: _taskCenterViewDataService.buildDetailBody(
          selectedTask,
          execution: execution,
        ),
        queueSummary: _taskCenterViewDataService.buildQueueSummary(preflight),
        schedulerSummary: _taskCenterViewDataService.buildSchedulerSummary(
          scheduler,
        ),
        chainMarkdown: _taskCenterViewDataService.buildChainMarkdown(chainView),
        longTaskRuns: longTaskRuns,
        taskQueueRuns: taskQueueRuns,
        selectedLongTaskRunPath: _selectedLongTaskRunPath,
        selectedTaskQueueRunPath: _selectedTaskQueueRunPath,
        longTaskRunLog: selectedLongRun.isEmpty
            ? ''
            : _workflowRuntimeService.renderLongTaskRunMarkdown(
                selectedLongRun,
              ),
        taskQueueRunLog: selectedQueueRun.isEmpty
            ? ''
            : _workflowRuntimeService.renderTaskQueueRunMarkdown(
                selectedQueueRun,
              ),
        nextTaskPath: ValueReaders.stringValue(
          ValueReaders.mapValue(chainView['next_task'])['relative_path'],
        ),
        nextPostprocessPath: ValueReaders.stringValue(
          ValueReaders.mapValue(
            chainView['next_postprocess_task'],
          )['relative_path'],
        ),
        status: _taskCenterStatusMessage,
      ),
    );
    _safeNotifyListeners();
  }

  Future<void> _refreshReviewCenter({String? status}) async {
    // 中文注释: 审稿中心刷新统一使用共享报告服务，避免 GUI 自己扫目录和手写过滤规则。
    final project = _currentProject;
    if (project == null) {
      _reviewCenterEntries = const <JsonMap>[];
      _selectedReviewEntryId = '';
      _viewModel = _viewModel.copyWith(
        reviewCenter: _reviewCenterViewDataService.build(
          entries: const <JsonMap>[],
          reviewTypeDefinitions: _reviewReportService.listReviewTypeDefs(),
          selectedEntryId: '',
          detailBody: '请先创建或打开项目。',
          reviewTypeFilter: _reviewTypeFilter,
          scopeFilter: _reviewScopeFilter,
          sourceFilter: _reviewSourceFilter,
          status: status ?? '请先创建或打开项目。',
        ),
      );
      _safeNotifyListeners();
      return;
    }
    _reviewCenterEntries = await _reviewReportService.listReports(
      project,
      filters: <String, Object?>{
        'review_type': _reviewTypeFilter,
        'scope': _reviewScopeFilter,
        'source_path': _reviewSourceFilter,
      },
      limit: 200,
    );
    if (_selectedReviewEntryId.trim().isEmpty &&
        _reviewCenterEntries.isNotEmpty) {
      _selectedReviewEntryId = ValueReaders.stringValue(
        _reviewCenterEntries.first['markdown_path'],
        ValueReaders.stringValue(_reviewCenterEntries.first['relative_path']),
      );
    }
    _reviewCenterStatusMessage = status ?? _reviewCenterStatusMessage;
    await _refreshReviewCenterView();
  }

  Future<void> _refreshReviewCenterView() async {
    // 中文注释: 审稿详情优先走结构化加载，保证 JSON+Markdown 双格式产物都能正确展示。
    final project = _currentProject;
    if (project == null) {
      return;
    }
    var detailBody = '';
    if (_selectedReviewEntryId.trim().isNotEmpty) {
      final loaded = await _reviewReportService.loadReport(
        project,
        _selectedReviewEntryId,
      );
      detailBody = _reviewCenterViewDataService.fallbackDetailBody(loaded);
    }
    _viewModel = _viewModel.copyWith(
      reviewCenter: _reviewCenterViewDataService.build(
        entries: _reviewCenterEntries,
        reviewTypeDefinitions: _reviewReportService.listReviewTypeDefs(),
        selectedEntryId: _selectedReviewEntryId,
        detailBody: detailBody,
        reviewTypeFilter: _reviewTypeFilter,
        scopeFilter: _reviewScopeFilter,
        sourceFilter: _reviewSourceFilter,
        status: _reviewCenterStatusMessage,
      ),
    );
    _safeNotifyListeners();
  }

  Future<void> _refreshPromptTemplates({String? status}) async {
    // 中文注释: 模板刷新统一读取 merged templates，这样内置模板、项目覆盖和恢复默认共用同一视图来源。
    final project = _currentProject;
    if (project == null) {
      _promptTemplates = const <JsonMap>[];
      _selectedPromptTemplate = const <String, Object?>{};
      _selectedPromptTemplateId = '';
      _viewModel = _viewModel.copyWith(
        promptTemplates: _promptTemplatesViewDataService.build(
          templates: const <JsonMap>[],
          selectedTemplate: const <String, Object?>{},
          selectedTemplateId: '',
          previewText: '',
          status: status ?? '请先创建或打开项目。',
        ),
      );
      _safeNotifyListeners();
      return;
    }
    _promptTemplates = await _promptTemplateService.listMergedTemplates(
      project,
    );
    if (_selectedPromptTemplateId.trim().isNotEmpty &&
        _selectedPromptTemplate.isEmpty) {
      _selectedPromptTemplate = _templateById(_selectedPromptTemplateId);
    }
    if (_selectedPromptTemplate.isEmpty &&
        _selectedPromptTemplateId.trim().isEmpty &&
        _promptTemplates.isNotEmpty) {
      _selectedPromptTemplate = ValueReaders.deepCopyMap(
        _promptTemplates.first,
      );
      _selectedPromptTemplateId = ValueReaders.stringValue(
        _selectedPromptTemplate['id'],
      );
    }
    _promptTemplatesStatusMessage = status ?? _promptTemplatesStatusMessage;
    _refreshPromptTemplatesView();
  }

  void _refreshPromptTemplatesView() {
    // 中文注释: 模板页视图重建只做投影，不在这里读写文件。
    _viewModel = _viewModel.copyWith(
      promptTemplates: _promptTemplatesViewDataService.build(
        templates: _promptTemplates,
        selectedTemplate: _selectedPromptTemplate,
        selectedTemplateId: _selectedPromptTemplateId,
        previewText: _promptTemplatePreviewText,
        status: _promptTemplatesStatusMessage,
      ),
    );
    _safeNotifyListeners();
  }

  Future<void> _runTaskCenterSelectorCommand({
    required String pendingMessage,
    required String successMessage,
    required Future<JsonMap> Function(
      ProjectDescriptor project,
      JsonMap selector,
      AppSettings? settings,
    )
    operation,
    bool requireSettings = false,
  }) async {
    // 中文注释: 选中任务相关动作统一经过这个薄包装，避免每个按钮重复做项目/设置检查和刷新。
    final project = _currentProject;
    if (project == null) {
      await _refreshTaskCenter(status: '请先创建或打开项目。');
      return;
    }
    final selector = _selectedTaskSelector();
    if (selector.isEmpty) {
      await _refreshTaskCenter(status: '请先选择一个任务。');
      return;
    }
    final settings = _settings;
    if (requireSettings && settings == null) {
      await _refreshTaskCenter(status: '设置尚未加载完成。');
      return;
    }
    _taskCenterStatusMessage = pendingMessage;
    await _refreshTaskCenterView();
    final result = await operation(project, selector, settings);
    await _syncWorkbenchResources();
    await _refreshTaskCenter(
      status: _resultMessage(result, success: successMessage),
    );
  }

  Future<void> _runTaskCenterProjectCommand({
    required String pendingMessage,
    required String successMessage,
    required Future<JsonMap> Function(
      ProjectDescriptor project,
      AppSettings? settings,
    )
    operation,
    bool requireSettings = false,
  }) async {
    // 中文注释: 无需显式选中任务的项目级动作也走同一刷新闭环，保证任务中心总能回到最新快照。
    final project = _currentProject;
    if (project == null) {
      await _refreshTaskCenter(status: '请先创建或打开项目。');
      return;
    }
    final settings = _settings;
    if (requireSettings && settings == null) {
      await _refreshTaskCenter(status: '设置尚未加载完成。');
      return;
    }
    _taskCenterStatusMessage = pendingMessage;
    await _refreshTaskCenterView();
    final result = await operation(project, settings);
    await _syncWorkbenchResources();
    await _refreshTaskCenter(
      status: _resultMessage(result, success: successMessage),
    );
  }

  Future<void> _runTaskCenterRecentRunCommand({
    required String pendingMessage,
    required String successMessage,
    required Future<JsonMap> Function(
      ProjectDescriptor project,
      AppSettings? settings,
      String runPath,
    )
    operation,
    bool requireSettings = false,
  }) async {
    // 中文注释: 暂停/恢复长任务依赖最近运行记录，这层帮助函数统一处理 run path 的查找与报错。
    final project = _currentProject;
    if (project == null) {
      await _refreshTaskCenter(status: '请先创建或打开项目。');
      return;
    }
    final recentRuns = await _workflowRuntimeService.listLongTaskRuns(
      project,
      limit: 1,
    );
    final runPath = recentRuns.isEmpty
        ? ''
        : ValueReaders.stringValue(recentRuns.first['relative_path']);
    if (runPath.trim().isEmpty) {
      await _refreshTaskCenter(status: '当前没有可操作的长任务运行记录。');
      return;
    }
    final settings = _settings;
    if (requireSettings && settings == null) {
      await _refreshTaskCenter(status: '设置尚未加载完成。');
      return;
    }
    _taskCenterStatusMessage = pendingMessage;
    await _refreshTaskCenterView();
    final result = await operation(project, settings, runPath);
    await _syncWorkbenchResources();
    await _refreshTaskCenter(
      status: _resultMessage(result, success: successMessage),
    );
  }

  Future<void> _syncWorkbenchResources({String selectedId = ''}) async {
    // 中文注释: 任务、审稿、模板等页面改动项目文件后，统一刷新工作台资源树，保证目录视图始终跟真实磁盘一致。
    final currentSelectedId = selectedId.trim().isEmpty
        ? _viewModel.workbench.activeDocumentPath
        : selectedId.trim();
    final entries = await _reloadResourceEntries(selectedId: currentSelectedId);
    _viewModel = _viewModel.copyWith(
      workbench: _viewModel.workbench.copyWith(resourceEntries: entries),
    );
    _safeNotifyListeners();
  }

  void _openLikelyOutlineDocument() {
    // 中文注释: “大纲”按钮优先尝试旧项目常见的大纲路径，没有则给出明确提示而不是空操作。
    const candidates = <String>[
      'outline/outline.md',
      'outline/project_outline.md',
      'volume_outlines/index.md',
      'chapter_outlines/index.md',
    ];
    final existingIds = _viewModel.workbench.resourceEntries
        .map((entry) => entry.id)
        .toSet();
    for (final candidate in candidates) {
      if (existingIds.contains(candidate)) {
        _openResource(candidate);
        return;
      }
    }
    _announce('当前项目还没有可直接打开的大纲文件。');
  }

  void _createReviewTaskForCurrentDocument() async {
    // 中文注释: 当前文档一键审稿统一先创建 review 任务，再切到任务中心等待用户执行。
    final project = _currentProject;
    if (project == null) {
      await _refreshReviewCenter(status: '请先创建或打开项目。');
      return;
    }
    final sourcePath = _viewModel.workbench.activeDocumentPath.trim();
    if (sourcePath.isEmpty) {
      await _refreshReviewCenter(status: '请先打开一个需要审稿的正文或文档。');
      return;
    }
    final reviewType = _reviewTypeFilter.trim().isEmpty
        ? ReviewTypeConstants.continuity
        : _reviewTypeFilter.trim();
    final result = await _reviewReportService.createReviewTask(
      project,
      <String, Object?>{
        'source_path': sourcePath,
        'review_type': reviewType,
        'scope': sourcePath,
      },
    );
    await _syncWorkbenchResources();
    if (ValueReaders.boolValue(result['ok'])) {
      _selectedTaskId = ValueReaders.stringValue(result['relative_path']);
      await _refreshTaskCenter(
        status:
            '已为当前文档创建${ReviewTypeCatalogService().reviewTypeLabel(reviewType)}任务。',
      );
      _viewModel = _viewModel.copyWith(destination: AppDestination.taskCenter);
      _safeNotifyListeners();
      return;
    }
    await _refreshReviewCenter(
      status: _resultMessage(result, success: '已创建审稿任务。'),
    );
  }

  JsonMap _selectedTaskSelector() {
    final selected = _taskByPath(_selectedTaskId);
    return _taskSelector(selected);
  }

  JsonMap _taskSelector(JsonMap task) {
    return <String, Object?>{
      'relative_path': ValueReaders.stringValue(task['relative_path']),
      'task_id': ValueReaders.stringValue(task['id']),
    };
  }

  JsonMap _taskByPath(String taskPath) {
    for (final task in _taskCenterTasks) {
      if (ValueReaders.stringValue(task['relative_path']) == taskPath) {
        return task;
      }
    }
    return <String, Object?>{};
  }

  JsonMap _templateById(String templateId) {
    for (final template in _promptTemplates) {
      if (ValueReaders.stringValue(template['id']) == templateId.trim()) {
        return ValueReaders.deepCopyMap(template);
      }
    }
    return <String, Object?>{};
  }

  JsonMap _templateRequestToMap(PromptTemplateEditorRequestViewData request) {
    // 中文注释: 模板表单请求在进入共享服务前统一规范化，保持 GUI/CLI 的模板结构同源。
    final currentRelativePath = ValueReaders.stringValue(
      _selectedPromptTemplate['relative_path'],
    );
    final normalized = _promptTemplateNormalizerService
        .normalizeTemplate(<String, Object?>{
          'id': request.id,
          'name': request.name,
          'scope': request.scope,
          'description': request.description,
          'content': request.content,
          'relative_path': currentRelativePath,
          'locked_core': ValueReaders.boolValue(
            _selectedPromptTemplate['locked_core'],
          ),
        });
    return normalized;
  }

  JsonMap? _jsonMapFromText(String rawText) {
    // 中文注释: 模板预览变量只接受 JSON 对象，解析失败时返回 null，让上层给出清晰提示。
    final text = rawText.trim();
    if (text.isEmpty) {
      return <String, Object?>{};
    }
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, Object?>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {}
    return null;
  }

  String _resultMessage(JsonMap result, {required String success}) {
    // 中文注释: 共享服务返回仍是字典风格，这里统一提炼一条用户可读状态文案。
    if (ValueReaders.boolValue(result['ok'])) {
      final warning = ValueReaders.stringValue(result['warning']).trim();
      return warning.isEmpty ? success : '$success $warning';
    }
    final error = ValueReaders.stringValue(result['error']).trim();
    return error.isEmpty ? '操作失败。' : '操作失败：$error';
  }

  Map<String, String> _nextEcosystemSelections({
    required String activeTabId,
    required String? selectedEntryId,
    required List<JsonMap> agents,
    required List<JsonMap> skills,
    required List<JsonMap> skillGroups,
    required List<JsonMap> agentGroups,
  }) {
    // 中文注释: 刷新后选中态集中在这里修正，避免新增或覆盖条目后指向已失效的 id。
    final nextSelections = Map<String, String>.from(
      _agentEcosystemSnapshot.selectedEntryIds,
    );
    if (selectedEntryId != null && selectedEntryId.trim().isNotEmpty) {
      nextSelections[activeTabId] = selectedEntryId;
    }
    final entriesByTab = <String, List<JsonMap>>{
      'agents': agents,
      'skills': skills,
      'skill-groups': skillGroups,
      'agent-groups': agentGroups,
    };
    for (final record in entriesByTab.entries) {
      nextSelections[record.key] = _resolvedEcosystemSelection(
        entries: record.value,
        selectedEntryId: nextSelections[record.key] ?? '',
      );
    }
    return nextSelections;
  }

  String _resolvedEcosystemSelection({
    required List<JsonMap> entries,
    required String selectedEntryId,
  }) {
    // 中文注释: 当前选中 id 不存在时自动回退到首条，保持生态页列表和详情区同步。
    final cleanSelectedId = selectedEntryId.trim();
    for (final entry in entries) {
      if (_stringValue(entry['id']) == cleanSelectedId) {
        return cleanSelectedId;
      }
    }
    if (entries.isEmpty) {
      return '';
    }
    return _stringValue(entries.first['id']);
  }

  List<JsonMap> _withProjectRelativePaths(
    List<JsonMap> entries,
    ProjectDescriptor project,
  ) {
    // 中文注释: 生态条目与项目目录的关联关系在这里统一补齐，展示层和运行层都只消费标准字段。
    return entries
        .map((entry) => _withProjectRelativePath(entry, project))
        .toList(growable: false);
  }

  JsonMap _withProjectRelativePath(JsonMap entry, ProjectDescriptor project) {
    final sourcePath = _stringValue(entry['entry_file_path']).trim();
    if (sourcePath.isEmpty) {
      return entry;
    }
    final projectRelativePath = _projectRelativePathOf(
      project.rootPath,
      sourcePath,
    );
    if (projectRelativePath.isEmpty) {
      return entry;
    }
    return <String, Object?>{
      ...entry,
      'project_relative_path': projectRelativePath,
    };
  }

  String _projectRelativePathOf(String rootPath, String sourcePath) {
    // 中文注释: 这里把项目内绝对路径映射为相对路径，确保 UI 和保存链只处理项目内地址。
    final cleanSourcePath = sourcePath.trim();
    if (cleanSourcePath.isEmpty) {
      return '';
    }
    final root = Directory(rootPath).absolute.path;
    final target = File(cleanSourcePath).absolute.path;
    final normalizedRoot = _normalizePathForCompare(root);
    final normalizedTarget = _normalizePathForCompare(target);
    if (normalizedTarget == normalizedRoot) {
      return '';
    }
    final prefix = '$normalizedRoot/';
    if (!normalizedTarget.startsWith(prefix)) {
      return '';
    }
    return target.substring(root.length + 1).replaceAll('\\', '/');
  }

  String _normalizePathForCompare(String value) {
    // 中文注释: Windows 和类 Unix 的路径比较统一落到这里，避免生态路径判断在多平台上分叉。
    final normalized = value.replaceAll('\\', '/');
    return Platform.isWindows ? normalized.toLowerCase() : normalized;
  }

  JsonMap? _selectedEcosystemSnapshotEntry(String entryId) {
    // 中文注释: 详情动作统一从快照中查条目，保持回调只携带轻量 id。
    final activeEntries = _agentEcosystemSnapshot.entriesForTab(
      _agentEcosystemSnapshot.activeTabId,
    );
    for (final entry in activeEntries) {
      if (_stringValue(entry['id']) == entryId.trim()) {
        return entry;
      }
    }
    return null;
  }

  String _ecosystemKindLabel(String kind) {
    // 中文注释: 创建成功提示统一使用中文名称，避免界面文案暴露内部 tab 标识。
    switch (kind) {
      case 'skills':
        return '技能';
      case 'skill-groups':
        return '技能组';
      case 'agent-groups':
        return '智能体组';
      case 'agents':
      default:
        return '智能体';
    }
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
    _resourceSnapshotEntries = snapshot.entries;
    _expandedResourceDirectories = _defaultExpandedDirectories(
      snapshot.entries,
    );
    _openDocuments = const <OpenDocumentState>[];
    _activeOpenDocumentId = '';
    _resetConversationSessions();
    var workbench = _viewModel.workbench.copyWith(
      projectName: snapshot.project.name,
      projectSubtitle: _projectSubtitleFor(snapshot.project.projectType),
      projectPath: snapshot.project.rootPath,
      toolCoreStatus: '',
      modelOptions: _settings == null
          ? _viewModel.workbench.modelOptions
          : _modelSelectorOptions(_settings!),
      agentOptions: _agentSelectorOptions(),
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
      activeDocumentDirty: false,
      conversationEntries: const [],
      pendingOptions: const [],
      subAgentRuns: const [],
      sessionHistoryEntries: const [],
      activeSessionId: '',
      showSessionHistory: false,
      isDocumentsWorkspaceVisible: false,
      projectLauncher: null,
      workspaceCommand: null,
      isGenerating: false,
    );
    final firstOpenable = _firstOpenablePath(snapshot.entries);
    if (firstOpenable.trim().isNotEmpty) {
      _expandResourceAncestors(firstOpenable);
      final content = await _readProjectFileUseCase.execute(
        snapshot.project,
        firstOpenable,
      );
      if (content != null && content.trim().isNotEmpty) {
        _openOrActivateDocument(
          relativePath: firstOpenable,
          title: _displayNameOf(firstOpenable),
          content: content,
        );
        workbench = _applyOpenDocuments(
          workbench.copyWith(
            resourceEntries: _markResourceSelection(
              workbench.resourceEntries,
              selectedId: firstOpenable,
            ),
            generationStatus: '已打开 $firstOpenable',
          ),
        );
      }
    }
    _replaceConversationSession(_createConversationSession(), activate: true);
    _refreshSettingsViewData();
    _updateWorkbench(_withConversationState(workbench));
    await _persistLastProjectPath(snapshot.project.rootPath);
    await _refreshAgentEcosystem();
    await _restoreWorkbenchSnapshot(snapshot.project);
    await _refreshActiveDestinationAfterProjectLoad();
  }

  Future<void> _openResource(String relativePath) async {
    // 中文注释: 资源点击会先判断目录折叠状态；只有文本文件才进入真正的打开逻辑。
    final project = _currentProject;
    if (project == null) {
      _announce('项目尚未加载完成。');
      return;
    }
    final selectedEntry = _resourceEntryById(relativePath);
    if (selectedEntry != null && selectedEntry.isDirectory) {
      _toggleResourceDirectory(relativePath);
      return;
    }
    _expandResourceAncestors(relativePath);
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
    _openOrActivateDocument(
      relativePath: relativePath,
      title: _displayNameOf(relativePath),
      content: content,
    );
    _updateWorkbench(
      _applyOpenDocuments(
        _viewModel.workbench.copyWith(
          resourceEntries: _markResourceSelection(
            _viewModel.workbench.resourceEntries,
            selectedId: relativePath,
          ),
          generationStatus: '已打开 $relativePath',
        ),
      ),
    );
    _persistWorkbenchSnapshot();
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
      final activeDocument = _activeOpenDocument();
      if (activeDocument != null) {
        _replaceOpenDocument(
          activeDocument.copyWith(
            id: savedPath,
            title: _viewModel.workbench.activeDocumentTitle,
            relativePath: savedPath,
            content: _viewModel.workbench.activeDocumentBody,
            isDirty: false,
          ),
        );
        _activeOpenDocumentId = savedPath;
      }
      _updateWorkbench(
        _applyOpenDocuments(
          _viewModel.workbench.copyWith(
            resourceEntries: resourceEntries,
            generationStatus: '已保存到 $savedPath',
          ),
        ),
      );
      _persistWorkbenchSnapshot();
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
    _resourceSnapshotEntries = snapshot.entries;
    _expandedResourceDirectories = _mergedExpandedDirectories(
      entries: snapshot.entries,
      selectedId: selectedId,
    );
    return _markResourceSelection(
      _resourceEntriesFrom(snapshot.entries),
      selectedId: selectedId,
    );
  }

  Future<void> _refreshActiveDestinationAfterProjectLoad() async {
    // 中文注释: 切换项目后，如果当前正停留在任务/审稿/模板页，就把这些页面一并刷新到新项目上下文。
    switch (_viewModel.destination) {
      case AppDestination.taskCenter:
        await _refreshTaskCenter();
        return;
      case AppDestination.reviewCenter:
        await _refreshReviewCenter();
        return;
      case AppDestination.promptTemplates:
        await _refreshPromptTemplates();
        return;
      case AppDestination.workbench:
      case AppDestination.settings:
      case AppDestination.agentEcosystem:
      case AppDestination.projectCollection:
        return;
    }
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
    final modelSettings = _modelSettingsOf(settings);
    final providers = settings.providers
        .map(
          (provider) => ProviderEndpointViewData(
            id: provider.id,
            title: provider.title,
            protocol: provider.protocol,
            baseUrl: provider.baseUrl,
            rawApiKey: provider.apiKey,
            apiKeyState: provider.apiKey.trim().isEmpty ? '未配置密钥' : '已配置密钥',
            description: provider.description,
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
      defaultModelId: settings.defaultModelId,
      modelSettings: modelSettings,
      modelEditor: _modelSettingsViewDataService.build(settings, modelSettings),
      defaultProjectPath: settings.defaultProjectPath,
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
    // 中文注释: 当前选中的 provider 优先沿用模型设置里的选择，没有时再退回设置页暂存状态。
    final modelProviderId = _stringValue(
      _modelSettingsOf(settings)['provider_id'],
      settings.defaultProviderId,
    );
    if (modelProviderId.isNotEmpty) {
      return modelProviderId;
    }
    for (final provider in _viewModel.settings.providers) {
      if (provider.isSelected) {
        return provider.id;
      }
    }
    return '';
  }

  Map<String, List<SettingsSectionViewData>> _settingsSections(
    AppSettings settings,
  ) {
    // 中文注释: 各 tab 的展示信息在这里按主题分组，后续某个 tab 变成可编辑面板时可以单独替换这一段映射。
    final provider = settings.defaultProvider();
    final modelSettings = _modelSettingsOf(settings);
    final providerLabel = provider == null ? '未选择' : provider.title;
    final providerBaseUrl = provider == null || provider.baseUrl.trim().isEmpty
        ? '未配置接口地址'
        : provider.baseUrl;
    final modelLabel = settings.defaultModelId.trim().isEmpty
        ? '未配置模型'
        : settings.defaultModelId;
    final currentProjectPath =
        _currentProject?.rootPath.trim().isNotEmpty == true
        ? _currentProject!.rootPath
        : settings.defaultProjectPath;
    final searchRoots = _settingsSearchRoots.isEmpty
        ? '未配置搜索根'
        : _settingsSearchRoots.join('\n');
    return <String, List<SettingsSectionViewData>>{
      'models': [
        SettingsSectionViewData(
          title: '默认推理入口',
          description: '这里反映当前 GUI / CLI 会读取的接口选择、模型 ID 与运行参数。',
          items: [
            SettingsItemViewData(label: '默认接口', value: providerLabel),
            SettingsItemViewData(label: '默认模型', value: modelLabel),
            SettingsItemViewData(
              label: '兼容上下文长度',
              value: _stringValue(
                modelSettings['compatible_context_window'],
                '未设置',
              ),
            ),
            SettingsItemViewData(
              label: '应用上下文长度',
              value: _stringValue(modelSettings['app_context_window'], '未设置'),
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
            SettingsItemViewData(label: '外部权限', value: '未启用额外外部存储权限'),
          ],
        ),
      ],
      'tooling': [
        SettingsSectionViewData(
          title: '共享运行链路',
          description: 'GUI 与 CLI 共用同一套 core 调度与工具执行入口，宿主层只负责界面与平台适配。',
          items: const [
            SettingsItemViewData(label: '文件访问', value: 'ProjectWorkspacePort'),
            SettingsItemViewData(
              label: '工具调度',
              value: 'ToolExecutionService / ProjectToolDispatcher',
            ),
            SettingsItemViewData(
              label: '交互回流',
              value: '会话、选项、子智能体运行都会回写同一条会话状态链',
            ),
          ],
        ),
      ],
      'network': [
        SettingsSectionViewData(
          title: '网络与接口',
          description: '模型网络入口来自 provider 配置；代理行为由网络设置统一控制。',
          items: [
            SettingsItemViewData(label: '默认接口地址', value: providerBaseUrl),
            SettingsItemViewData(
              label: '代理策略',
              value: '可跟随系统网络环境，也可填写自定义代理地址。',
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
            SettingsItemViewData(
              label: '默认项目',
              value: settings.defaultProjectPath,
            ),
            SettingsItemViewData(
              label: '当前项目',
              value: currentProjectPath.trim().isEmpty
                  ? '未加载项目'
                  : currentProjectPath,
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
            SettingsItemViewData(
              label: '默认项目根',
              value: _defaultProjectsRootPath,
            ),
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
          modelOptions: _modelSelectorOptions(savedSettings),
          agentLabel: _agentLabel(savedSettings),
          agentOptions: _agentSelectorOptions(),
        ),
      );
      _announce(successMessage);
    } catch (error) {
      _announce('保存设置失败：$error');
    }
  }

  Future<void> _saveSettingsSilently(AppSettings nextSettings) async {
    // 中文注释: 工作台记忆这类背景状态更新不应打断用户，因此单独走静默保存链。
    if (_savingWorkbenchSnapshot) {
      return;
    }
    try {
      _savingWorkbenchSnapshot = true;
      final savedSettings = await _settingsRepository.save(nextSettings);
      _settings = savedSettings;
      _themeMode = _themeModeFromSettings(savedSettings);
      _refreshSettingsViewData();
      _viewModel = _viewModel.copyWith(
        workbench: _viewModel.workbench.copyWith(
          modelLabel: _defaultModelLabel(savedSettings),
          modelOptions: _modelSelectorOptions(savedSettings),
          agentLabel: _agentLabel(savedSettings),
          agentOptions: _agentSelectorOptions(),
        ),
      );
    } catch (_) {
      // 中文注释: 记忆保存失败不影响主流程，因此这里静默吞掉。
    } finally {
      _savingWorkbenchSnapshot = false;
    }
  }

  Future<void> _persistLastProjectPath(String rootPath) async {
    // 中文注释: 上次打开项目属于明确的用户便利记忆，应与工作台快照一起落到设置层。
    final settings = _settings;
    if (settings == null || rootPath.trim().isEmpty) {
      return;
    }
    if (_normalizePathForCompare(settings.defaultProjectPath) ==
        _normalizePathForCompare(rootPath)) {
      await _persistWorkbenchSnapshot();
      return;
    }
    await _saveSettingsSilently(
      settings.copyWith(defaultProjectPath: rootPath),
    );
    await _persistWorkbenchSnapshot();
  }

  Future<void> _persistWorkbenchSnapshot() async {
    // 中文注释: 工作台快照只保存可恢复现场所需的轻量字段，不写入临时正文内容。
    final settings = _settings;
    final project = _currentProject;
    if (settings == null || project == null) {
      return;
    }
    final snapshot = <String, Object?>{
      'project_root_path': project.rootPath,
      'active_document_path': _viewModel.workbench.activeDocumentPath,
      'expanded_directories': _expandedResourceDirectories.toList(
        growable: false,
      ),
    };
    final currentSnapshot = _mapValue(
      settings.extraSettings['workbench_state'],
    );
    final unchanged =
        _normalizePathForCompare(
              ValueReaders.stringValue(currentSnapshot['project_root_path']),
            ) ==
            _normalizePathForCompare(project.rootPath) &&
        ValueReaders.stringValue(currentSnapshot['active_document_path']) ==
            _viewModel.workbench.activeDocumentPath &&
        _stringListsEqual(
          ValueReaders.stringList(currentSnapshot['expanded_directories']),
          _expandedResourceDirectories.toList(growable: false),
        );
    if (unchanged &&
        _normalizePathForCompare(settings.defaultProjectPath) ==
            _normalizePathForCompare(project.rootPath)) {
      return;
    }
    await _saveSettingsSilently(
      settings.copyWith(
        defaultProjectPath: project.rootPath,
        extraSettings: <String, Object?>{
          ...settings.extraSettings,
          'workbench_state': snapshot,
        },
      ),
    );
  }

  Future<void> _restoreWorkbenchSnapshot(ProjectDescriptor project) async {
    // 中文注释: 工作台恢复只恢复目录展开与最后打开文档，避免把一次性视图状态强行带回新会话。
    final settings = _settings;
    if (settings == null) {
      return;
    }
    final snapshot = _mapValue(settings.extraSettings['workbench_state']);
    if (_normalizePathForCompare(
          ValueReaders.stringValue(snapshot['project_root_path']),
        ) !=
        _normalizePathForCompare(project.rootPath)) {
      return;
    }
    final knownDirectoryPaths = _resourceSnapshotEntries
        .where((entry) => _boolValue(entry['is_dir']))
        .map((entry) => _stringValue(entry['relative_path']))
        .toSet();
    _expandedResourceDirectories = ValueReaders.stringList(
      snapshot['expanded_directories'],
    ).where(knownDirectoryPaths.contains).toSet();
    final activeDocumentPath = _stringValue(
      snapshot['active_document_path'],
    ).trim();
    if (activeDocumentPath.isEmpty) {
      _updateWorkbench(
        _viewModel.workbench.copyWith(
          resourceEntries: _markResourceSelection(
            _resourceEntriesFrom(_resourceSnapshotEntries),
            selectedId: '',
          ),
        ),
      );
      return;
    }
    final content = await _readProjectFileUseCase.execute(
      project,
      activeDocumentPath,
    );
    if (content == null || content.trim().isEmpty) {
      _updateWorkbench(
        _viewModel.workbench.copyWith(
          resourceEntries: _markResourceSelection(
            _resourceEntriesFrom(_resourceSnapshotEntries),
            selectedId: '',
          ),
        ),
      );
      return;
    }
    _expandResourceAncestors(activeDocumentPath);
    _openOrActivateDocument(
      relativePath: activeDocumentPath,
      title: _displayNameOf(activeDocumentPath),
      content: content,
    );
    _updateWorkbench(
      _applyOpenDocuments(
        _viewModel.workbench.copyWith(
          resourceEntries: _markResourceSelection(
            _resourceEntriesFrom(_resourceSnapshotEntries),
            selectedId: activeDocumentPath,
          ),
          generationStatus: '已恢复上次打开的项目现场。',
        ),
      ),
    );
  }

  bool _stringListsEqual(List<String> left, List<String> right) {
    if (left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        return false;
      }
    }
    return true;
  }

  ThemeMode _themeModeFromSettings(AppSettings settings) {
    // 中文注释: 主题模式优先从设置文档读取，保证重启应用后仍能回到用户保存的模式。
    return _themeModeFromValue(
      _stringValue(settings.themeSettings['mode'], 'light'),
    );
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
    // 中文注释: 资源树在这里转换成“可展开目录 + 可见文件”的视图层结构，并隐藏不该直接暴露给用户的 JSON。
    final visibleEntries = entries
        .where(
          (entry) =>
              !_shouldHideResourcePath(_stringValue(entry['relative_path'])),
        )
        .toList(growable: false);
    final byParent = <String, List<JsonMap>>{};
    for (final entry in visibleEntries) {
      final relativePath = _stringValue(entry['relative_path']);
      final parentPath = _parentPathOf(relativePath);
      byParent.putIfAbsent(parentPath, () => <JsonMap>[]).add(entry);
    }
    final results = <ResourceEntryViewData>[];

    void visit(String parentPath, int depth) {
      final siblings = byParent[parentPath];
      if (siblings == null || siblings.isEmpty) {
        return;
      }
      final orderedSiblings = siblings.toList(growable: true)
        ..sort((left, right) => _compareResourceEntries(left, right));
      for (final entry in orderedSiblings) {
        final relativePath = _stringValue(entry['relative_path']);
        final isDirectory = _boolValue(entry['is_dir']);
        final hasChildren =
            (byParent[relativePath] ?? const <JsonMap>[]).isNotEmpty;
        final childCount = (byParent[relativePath] ?? const <JsonMap>[])
            .where(
              (child) => !_shouldHideResourcePath(
                _stringValue(child['relative_path']),
              ),
            )
            .length;
        final isExpanded =
            !isDirectory || _expandedResourceDirectories.contains(relativePath);
        results.add(
          ResourceEntryViewData(
            id: relativePath,
            title: _resourceTitleOf(relativePath, isDirectory: isDirectory),
            depth: depth,
            isDirectory: isDirectory,
            childCount: childCount,
            hasChildren: hasChildren,
            isExpanded: isExpanded,
          ),
        );
        if (isDirectory && isExpanded) {
          visit(relativePath, depth + 1);
        }
      }
    }

    visit('', 0);
    return results;
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
            childCount: entry.childCount,
            hasChildren: entry.hasChildren,
            isExpanded: entry.isExpanded,
            isSelected: entry.id == selectedId,
          ),
        )
        .toList(growable: false);
  }

  void _openOrActivateDocument({
    required String relativePath,
    required String title,
    required String content,
  }) {
    // 中文注释: 打开文档时优先复用已有标签，避免同一路径反复堆出重复标签。
    final documentId = relativePath.trim().isEmpty ? title : relativePath;
    final existingIndex = _openDocuments.indexWhere(
      (document) => document.id == documentId,
    );
    final nextDocument = OpenDocumentState(
      id: documentId,
      title: title.trim().isEmpty ? '未命名草稿' : title,
      relativePath: relativePath,
      content: content,
    );
    final nextDocuments = List<OpenDocumentState>.from(_openDocuments);
    if (existingIndex >= 0) {
      nextDocuments[existingIndex] = nextDocument;
    } else {
      nextDocuments.add(nextDocument);
    }
    _openDocuments = nextDocuments;
    _activeOpenDocumentId = documentId;
  }

  void _replaceOpenDocument(OpenDocumentState document) {
    // 中文注释: 已打开文档内容变更统一通过这里回写，避免多个回调各自维护列表替换逻辑。
    final index = _openDocuments.indexWhere((item) => item.id == document.id);
    if (index < 0) {
      return;
    }
    final nextDocuments = List<OpenDocumentState>.from(_openDocuments);
    nextDocuments[index] = document;
    _openDocuments = nextDocuments;
  }

  OpenDocumentState? _activeOpenDocument() {
    for (final document in _openDocuments) {
      if (document.id == _activeOpenDocumentId) {
        return document;
      }
    }
    return _openDocuments.isEmpty ? null : _openDocuments.last;
  }

  void _toggleActiveDocumentRenderMode() {
    // 中文注释: 渲染只对当前活动 Markdown 文档生效，不再挟持整个工作台进入专门布局。
    final active = _activeOpenDocument();
    if (active == null) {
      _announce('当前没有可渲染的文档。');
      return;
    }
    if (!active.canRender) {
      _announce('只有 Markdown 文档支持渲染。');
      return;
    }
    _replaceOpenDocument(active.copyWith(isRendered: !active.isRendered));
    _updateWorkbench(
      _applyOpenDocuments(
        _viewModel.workbench.copyWith(
          generationStatus: active.isRendered ? '已返回编辑视图。' : '已切到渲染视图。',
        ),
      ),
    );
  }

  WorkbenchViewData _applyOpenDocuments(WorkbenchViewData base) {
    // 中文注释: 打开文档集合到工作台展示态的投影统一收口，避免多处手拼 active 文档字段。
    final active = _activeOpenDocument();
    if (active == null) {
      return base.copyWith(
        documents: const <DocumentTabViewData>[],
        activeDocumentTitle: '',
        activeDocumentPath: '',
        activeDocumentBody: '',
        activeDocumentDirty: false,
        activeDocumentCanRender: false,
        isActiveDocumentRendered: false,
      );
    }
    return base.copyWith(
      documents: _openDocuments
          .map(
            (document) => DocumentTabViewData(
              id: document.id,
              title: document.title,
              isActive: document.id == active.id,
              isDirty: document.isDirty,
            ),
          )
          .toList(growable: false),
      activeDocumentTitle: active.title,
      activeDocumentPath: active.relativePath,
      activeDocumentBody: active.content,
      activeDocumentDirty: active.isDirty,
      activeDocumentCanRender: active.canRender,
      isActiveDocumentRendered: active.isRendered,
    );
  }

  List<SelectorOptionViewData> _modelSelectorOptions(AppSettings settings) {
    // 中文注释: 会话栏模型下拉沿用共享目录与当前设置计算结果，不再额外维护一套前端专用列表。
    final editor = _modelSettingsViewDataService.build(
      settings,
      _modelSettingsOf(settings),
    );
    final options = <SelectorOptionViewData>[];
    final seen = <String>{};
    final currentModelId = settings.defaultModelId.trim();
    void addOption(String id, {String note = ''}) {
      final cleanId = id.trim();
      if (cleanId.isEmpty || !seen.add(cleanId)) {
        return;
      }
      options.add(
        SelectorOptionViewData(id: cleanId, label: cleanId, note: note),
      );
    }

    addOption(
      currentModelId,
      note: editor.providerLabel.trim().isEmpty ? '当前模型' : editor.providerLabel,
    );
    for (final suggestion in editor.modelSuggestions) {
      addOption(suggestion.value, note: suggestion.note);
    }
    return options;
  }

  List<SelectorOptionViewData> _agentSelectorOptions() {
    // 中文注释: 会话栏智能体下拉优先展示已加载生态条目，没有项目时仍保留内置默认智能体兜底。
    final options = <SelectorOptionViewData>[
      const SelectorOptionViewData(
        id: 'default_generalist',
        label: '综合创作智能体',
        note: '内置',
      ),
    ];
    final seen = <String>{'default_generalist'};
    for (final agent in _agentEcosystemSnapshot.agents) {
      final id = _stringValue(agent['id']);
      if (id.trim().isEmpty || !seen.add(id)) {
        continue;
      }
      options.add(
        SelectorOptionViewData(
          id: id,
          label: _stringValue(agent['name'], id),
          note: _stringValue(agent['source']),
        ),
      );
    }
    return options;
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

  String _joinedProjectPath(
    String directoryPath,
    String entryName, {
    required String defaultFileName,
  }) {
    // 中文注释: 项目相对路径拼接统一收口，避免创建文件、目录和导入动作各自处理斜杠细节。
    final cleanDirectory = directoryPath.replaceAll('\\', '/').trim();
    final cleanEntryName = entryName.trim().isEmpty
        ? defaultFileName
        : entryName.trim();
    if (cleanDirectory.isEmpty) {
      return cleanEntryName;
    }
    final normalizedDirectory = cleanDirectory.replaceAll(RegExp(r'/+$'), '');
    final normalizedEntry = cleanEntryName.replaceAll(RegExp(r'^/+'), '');
    return '$normalizedDirectory/$normalizedEntry';
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
      if (isDir || _shouldHideResourcePath(path)) {
        continue;
      }
      final normalized = path.toLowerCase();
      if (normalized.endsWith('.md') ||
          normalized.endsWith('.txt') ||
          normalized.endsWith('.yaml') ||
          normalized.endsWith('.yml')) {
        return path;
      }
    }
    return '';
  }

  String _defaultModelLabel(AppSettings settings) {
    // 中文注释: 模型展示文案统一从设置推导，避免 UI 自己拼接 provider 与模型字段。
    final provider = _selectedModelProvider(settings);
    if (provider == null) {
      return settings.defaultModelId.trim().isEmpty
          ? '未配置模型'
          : settings.defaultModelId;
    }
    final modelId = settings.defaultModelId.trim();
    if (provider.baseUrl.trim().isEmpty || modelId.trim().isEmpty) {
      return '未配置模型';
    }
    return '${provider.title} · $modelId';
  }

  JsonMap _modelSettingsOf(AppSettings settings) {
    // 中文注释: 模型运行参数从 extraSettings 中单独收口，避免继续污染 provider 和通用上下文字段。
    return _mapValue(settings.extraSettings['model_settings']);
  }

  ProviderEndpointSettings? _selectedModelProvider(AppSettings settings) {
    // 中文注释: 模型运行使用的接口优先按模型设置选择；未选中时才回退到兼容默认解析。
    final selectedId = _stringValue(
      _modelSettingsOf(settings)['provider_id'],
      settings.defaultProviderId,
    );
    if (selectedId.isNotEmpty) {
      for (final provider in settings.providers) {
        if (provider.id == selectedId) {
          return provider;
        }
      }
    }
    return settings.defaultProvider();
  }

  String _nextProviderId(
    List<ProviderEndpointSettings> providers,
    String title,
  ) {
    // 中文注释: 接口内部 ID 由标题派生并自动去重，用户看不到也不需要手动维护。
    final baseId = _slugFromTitle(title);
    final existingIds = providers
        .map((provider) => provider.id.trim().toLowerCase())
        .where((id) => id.isNotEmpty)
        .toSet();
    if (!existingIds.contains(baseId.toLowerCase())) {
      return baseId;
    }
    var suffix = 1;
    while (existingIds.contains('${baseId}_$suffix'.toLowerCase())) {
      suffix += 1;
    }
    return '${baseId}_$suffix';
  }

  String _slugFromTitle(String title) {
    // 中文注释: 标题转内部 ID 时只保留稳定的英文数字和下划线，空结果则退回 interface。
    var result = title.trim().toLowerCase();
    result = result.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    result = result.replaceAll(RegExp(r'_+'), '_');
    result = result.replaceAll(RegExp(r'^_+|_+$'), '');
    return result.isEmpty ? 'interface' : result;
  }

  ResourceEntryViewData? _resourceEntryById(String entryId) {
    // 中文注释: 当前可见资源项查询集中在这里，避免目录点击和文件打开逻辑各自重复遍历视图列表。
    for (final entry in _viewModel.workbench.resourceEntries) {
      if (entry.id == entryId) {
        return entry;
      }
    }
    return null;
  }

  void _toggleResourceDirectory(String relativePath) {
    // 中文注释: 目录展开状态由控制器统一维护，这样资源树控件保持纯展示而不私藏结构状态。
    final nextExpanded = Set<String>.from(_expandedResourceDirectories);
    if (nextExpanded.contains(relativePath)) {
      nextExpanded.remove(relativePath);
    } else {
      nextExpanded.add(relativePath);
    }
    _expandedResourceDirectories = nextExpanded;
    _updateWorkbench(
      _viewModel.workbench.copyWith(
        resourceEntries: _resourceEntriesFrom(_resourceSnapshotEntries),
        generationStatus: '已切换目录：$relativePath',
      ),
    );
    _persistWorkbenchSnapshot();
  }

  Set<String> _defaultExpandedDirectories(List<JsonMap> entries) {
    // 中文注释: 默认资源树保持全部折叠，只在用户展开或打开文档时补齐祖先链。
    return <String>{};
  }

  Set<String> _mergedExpandedDirectories({
    required List<JsonMap> entries,
    required String selectedId,
  }) {
    // 中文注释: 刷新资源树后保留用户当前展开状态，同时补齐新目录和选中文档祖先的展开链。
    final existingDirectoryPaths = entries
        .where(
          (entry) =>
              _boolValue(entry['is_dir']) &&
              !_shouldHideResourcePath(_stringValue(entry['relative_path'])),
        )
        .map((entry) => _stringValue(entry['relative_path']))
        .toSet();
    final nextExpanded = _expandedResourceDirectories
        .where(existingDirectoryPaths.contains)
        .toSet();
    if (selectedId.trim().isNotEmpty) {
      nextExpanded.addAll(_ancestorDirectoryPathsOf(selectedId));
    }
    return nextExpanded;
  }

  void _expandResourceAncestors(String relativePath) {
    // 中文注释: 打开文件时自动展开祖先目录，保证当前选中文档在资源树中始终可见。
    _expandedResourceDirectories = <String>{
      ..._expandedResourceDirectories,
      ..._ancestorDirectoryPathsOf(relativePath),
    };
  }

  Set<String> _ancestorDirectoryPathsOf(String relativePath) {
    final ancestors = <String>{};
    var current = _parentPathOf(relativePath);
    while (current.isNotEmpty) {
      ancestors.add(current);
      current = _parentPathOf(current);
    }
    return ancestors;
  }

  String _parentPathOf(String relativePath) {
    final cleanPath = relativePath.replaceAll('\\', '/').trim();
    final slashIndex = cleanPath.lastIndexOf('/');
    if (slashIndex <= 0) {
      return '';
    }
    return cleanPath.substring(0, slashIndex);
  }

  bool _shouldHideResourcePath(String relativePath) {
    // 中文注释: 普通用户资源树默认隐藏 JSON/JSONL 和内部元数据目录，减少误改后项目不可用的风险。
    final cleanPath = relativePath.trim().toLowerCase();
    if (cleanPath.isEmpty) {
      return false;
    }
    if (cleanPath.startsWith('.novel_agent/')) {
      return true;
    }
    if (cleanPath.endsWith('.json') || cleanPath.endsWith('.jsonl')) {
      return true;
    }
    if (cleanPath == 'readme.md') {
      return true;
    }
    if (RegExp(r'^[^/]+/readme\.md$').hasMatch(cleanPath)) {
      return true;
    }
    return false;
  }

  int _compareResourceEntries(JsonMap left, JsonMap right) {
    // 中文注释: 资源树排序先尊重目录优先和顶层工作区认知顺序，再回退到稳定字典序。
    final leftPath = _stringValue(left['relative_path']);
    final rightPath = _stringValue(right['relative_path']);
    final leftIsDirectory = _boolValue(left['is_dir']);
    final rightIsDirectory = _boolValue(right['is_dir']);
    final leftParent = _parentPathOf(leftPath);
    final rightParent = _parentPathOf(rightPath);
    if (leftParent.isEmpty && rightParent.isEmpty) {
      final topLevelOrder = _topLevelWorkspaceOrder();
      final leftRank = topLevelOrder.indexOf(leftPath.split('/').first);
      final rightRank = topLevelOrder.indexOf(rightPath.split('/').first);
      if (leftRank >= 0 || rightRank >= 0) {
        if (leftRank < 0) {
          return 1;
        }
        if (rightRank < 0) {
          return -1;
        }
        final compareRank = leftRank.compareTo(rightRank);
        if (compareRank != 0) {
          return compareRank;
        }
      }
    }
    if (leftIsDirectory != rightIsDirectory) {
      return leftIsDirectory ? -1 : 1;
    }
    return leftPath.compareTo(rightPath);
  }

  List<String> _topLevelWorkspaceOrder() {
    // 中文注释: 顶层目录顺序按用户常见创作流程排列，而不是简单字典序。
    return const <String>[
      'outline',
      'volume_outlines',
      'chapter_outlines',
      'chapters',
      'drafts',
      'world',
      'characters',
      'styles',
      'summaries',
      'knowledge',
      'inspiration',
      'assets',
      'tasks',
      'reviews',
      'prompts',
      'agents',
      'agent_groups',
      'skills',
      'skill_groups',
      'specs',
      'tracking',
      'runs',
      'backups',
      'exports',
      'README.md',
    ];
  }

  String _agentLabel(AppSettings settings) {
    // 中文注释: 默认智能体标签优先使用已加载生态名称，避免会话栏直接暴露内部 id。
    if (settings.defaultAgentId == 'default_generalist' ||
        settings.defaultAgentId.trim().isEmpty) {
      return '综合创作智能体';
    }
    for (final agent in _agentEcosystemSnapshot.agents) {
      if (_stringValue(agent['id']) == settings.defaultAgentId) {
        return _stringValue(agent['name'], settings.defaultAgentId);
      }
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

  JsonMap _contextStrategySettingsOf(AppSettings settings) {
    // 中文注释: 控制器只负责收集上下文策略配置，不解释具体策略含义。
    final context = settings.contextSettings;
    return <String, Object?>{
      'compression_threshold_percent': context['compression_threshold_percent'],
      'context_pack_budget_percent': context['context_pack_budget_percent'],
      'max_context_file_chars': context['max_context_file_chars'],
      'max_context_files_per_kind': context['max_context_files_per_kind'],
      'reserved_output_chars': context['reserved_output_chars'],
    };
  }

  Future<void> _startPrimaryActionPrompt(
    WorkbenchPrimaryActionPlan plan, {
    String userVisibleText = '',
  }) async {
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
    await _sendPrompt(plan.prompt, visibleText: userVisibleText);
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
    final contextPackSummary = _stringValue(result.contextPack['summary'], '上下文已更新');
    return '$sessionSummary · $contextPackSummary · 读取 ${result.selectedPaths.length} 个文件 · 工具 ${result.executedTools.length} 次';
  }

  String _generationStatusFor(DraftGenerationResult result, String savedPath) {
    // 中文注释: 生成状态文案集中在这里，避免不同完成分支手写出不一致的提示语。
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
    // 中文注释: 流式阶段状态只描述当前进度，不提前承诺最终结果，避免把中间态说成已经完成。
    if (progress.pendingToolCalls.isNotEmpty) {
      return '正在通过 ${provider.title} 组织工具调用...';
    }
    if (progress.executedTools.isNotEmpty &&
        progress.draftMarkdown.trim().isEmpty) {
      return '正在通过 ${provider.title} 处理工具结果...';
    }
    return '正在通过 ${provider.title} 接收流式内容...';
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

  JsonMap _mapValue(Object? value) {
    // 中文注释: 控制器偶尔需要从 extraSettings 投影字典结构，这里做轻量归一化即可。
    if (value is Map<String, Object?>) {
      return Map<String, Object?>.from(value);
    }
    if (value is Map) {
      return value.map((key, entry) => MapEntry(key.toString(), entry));
    }
    return <String, Object?>{};
  }
}
