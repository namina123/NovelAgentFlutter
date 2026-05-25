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
import '../../features/project_creation/application/controllers/project_creation_controller.dart';
import '../../features/long_task_station/application/controllers/long_task_station_controller.dart';
import '../../features/project_assets/application/models/project_assets_snapshot.dart';
import '../../features/project_assets/application/services/project_assets_view_data_service.dart';
import '../../features/project_assets/presentation/contracts/project_assets_action_handler.dart';
import '../../features/project_assets/presentation/models/project_assets_view_data.dart';
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
import '../../features/task_center/application/services/task_center_guidance_revisit_markdown_service.dart';
import '../../features/task_center/presentation/contracts/task_center_action_handler.dart';
import '../../features/task_center/presentation/models/task_center_contract_action_view_data.dart';
import '../../features/task_center/presentation/models/task_center_view_data.dart';
import '../../features/workbench/application/controllers/generate_draft_use_case_factory.dart';
import '../../features/workbench/application/controllers/workbench_conversation_controller.dart';
import '../../features/workbench/application/controllers/workbench_workspace_controller.dart';
import '../../features/workbench/application/models/workbench_conversation_runtime_state.dart';
import '../../features/workbench/application/models/workbench_project_runtime_state.dart';
import '../../features/workbench/application/services/conversation_session_state_service.dart';
import '../../features/workbench/application/services/conversation_streaming_state_service.dart';
import '../../features/workbench/application/services/conversation_guide_view_data_service.dart';
import '../../features/workbench/application/services/desktop_project_directory_picker_service.dart';
import '../../features/workbench/application/services/project_launcher_view_data_service.dart';
import '../../features/workbench/application/services/workbench_primary_action_service.dart';
import '../../features/workbench/application/services/conversation_user_visible_text_service.dart';
import '../../features/workbench/presentation/contracts/conversation_action_handler.dart';
import '../../features/workbench/presentation/contracts/document_workspace_action_handler.dart';
import '../../features/workbench/presentation/contracts/resource_manager_action_handler.dart';
import '../../features/workbench/presentation/models/project_create_request_view_data.dart';
import '../../features/workbench/presentation/models/selector_option_view_data.dart';
import '../../features/workbench/presentation/models/user_option_view_data.dart';
import '../../features/workbench/presentation/models/workbench_view_data.dart';
import '../../shared/view_models/app_shell_view_model.dart';
import '../routing/app_destination.dart';
import 'app_shell_destination_controller.dart';
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
        SettingsActionHandler,
        AgentEcosystemActionHandler,
        ProjectCollectionActionHandler,
        TaskCenterActionHandler,
        ReviewCenterActionHandler,
        PromptTemplatesActionHandler,
        ProjectAssetsActionHandler {
  AppShellController({
    required SettingsRepository settingsRepository,
    required LoadProjectWorkspaceUseCase loadProjectWorkspaceUseCase,
    required LoadModeGuidanceStateUseCase loadModeGuidanceStateUseCase,
    required AnswerModeGuidanceStageUseCase answerModeGuidanceStageUseCase,
    required BuildModeGuidancePlanInputUseCase
    buildModeGuidancePlanInputUseCase,
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
    required ProjectAssetLibraryService projectAssetLibraryService,
    required LongTaskStationController longTaskStationController,
    ConversationSessionStateService? conversationSessionStateService,
    ConversationStreamingStateService? conversationStreamingStateService,
    ConversationGuideViewDataService? conversationGuideViewDataService,
    ConversationUserVisibleTextService? conversationUserVisibleTextService,
    DesktopProjectDirectoryPickerService? desktopProjectDirectoryPickerService,
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
    TaskCenterGuidanceRevisitMarkdownService?
    taskCenterGuidanceRevisitMarkdownService,
    ReviewCenterViewDataService? reviewCenterViewDataService,
    PromptTemplatesViewDataService? promptTemplatesViewDataService,
    ProjectAssetsViewDataService? projectAssetsViewDataService,
    PromptTemplatePreviewService? promptTemplatePreviewService,
    PromptTemplateNormalizerService? promptTemplateNormalizerService,
    ModelSettingsViewDataService? modelSettingsViewDataService,
    ModelExecutionProfileService? modelExecutionProfileService,
    ModeGuidanceTransitionService? modeGuidanceTransitionService,
  }) : _settingsRepository = settingsRepository,
       _loadProjectWorkspaceUseCase = loadProjectWorkspaceUseCase,
       _loadModeGuidanceStateUseCase = loadModeGuidanceStateUseCase,
       _answerModeGuidanceStageUseCase = answerModeGuidanceStageUseCase,
       _buildModeGuidancePlanInputUseCase = buildModeGuidancePlanInputUseCase,
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
       _projectAssetLibraryService = projectAssetLibraryService,
       _longTaskStationController = longTaskStationController,
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
       _desktopProjectDirectoryPickerService =
           desktopProjectDirectoryPickerService ??
           const DesktopProjectDirectoryPickerService(),
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
       _taskCenterGuidanceRevisitMarkdownService =
           taskCenterGuidanceRevisitMarkdownService ??
           const TaskCenterGuidanceRevisitMarkdownService(),
       _reviewCenterViewDataService =
           reviewCenterViewDataService ?? const ReviewCenterViewDataService(),
       _promptTemplatesViewDataService =
           promptTemplatesViewDataService ??
           const PromptTemplatesViewDataService(),
       _projectAssetsViewDataService =
           projectAssetsViewDataService ?? const ProjectAssetsViewDataService(),
       _promptTemplatePreviewService =
           promptTemplatePreviewService ?? PromptTemplatePreviewService(),
       _promptTemplateNormalizerService =
           promptTemplateNormalizerService ?? PromptTemplateNormalizerService(),
       _modelSettingsViewDataService =
           modelSettingsViewDataService ?? ModelSettingsViewDataService(),
       _modelExecutionProfileService =
           modelExecutionProfileService ?? ModelExecutionProfileService(),
       _modeGuidanceTransitionService =
           modeGuidanceTransitionService ?? ModeGuidanceTransitionService(),
       _viewModel = AppShellViewModel.initial() {
    _destinationController = AppShellDestinationController(
      changeDestination: _changeDestination,
      refreshAgentEcosystem: _refreshAgentEcosystem,
      refreshTaskCenter: _refreshTaskCenter,
      refreshReviewCenter: _refreshReviewCenter,
      refreshPromptTemplates: _refreshPromptTemplates,
      refreshProjectAssets: _refreshProjectAssets,
      longTaskStationController: _longTaskStationController,
    );
    _workbenchWorkspaceController = WorkbenchWorkspaceController(
      loadProjectWorkspaceUseCase: _loadProjectWorkspaceUseCase,
      readProjectFileUseCase: _readProjectFileUseCase,
      saveDraftUseCase: _saveDraftUseCase,
      createProjectEntryUseCase: _createProjectEntryUseCase,
      importProjectFilesUseCase: _importProjectFilesUseCase,
      updateProjectManifestUseCase: _updateProjectManifestUseCase,
      reviewReportService: _reviewReportService,
      readProjectState: () => _workbenchProjectRuntimeState,
      writeProjectState: (state) {
        _workbenchProjectRuntimeState = state;
      },
      resetConversationRuntimeState: () {
        _workbenchConversationRuntimeState =
            const WorkbenchConversationRuntimeState();
      },
      readWorkbench: () => _viewModel.workbench,
      mutateWorkbench: _mutateWorkbench,
      applyConversationState: (base) =>
          _workbenchConversationController.applyConversationState(base),
      readSettings: () => _settings,
      saveSettingsSilently: _saveSettingsSilently,
      refreshSettingsViewData: _refreshSettingsViewData,
      refreshAgentEcosystem: _refreshAgentEcosystem,
      refreshActiveDestinationAfterProjectLoad:
          _refreshActiveDestinationAfterProjectLoad,
      modelOptionsBuilder: _modelSelectorOptions,
      agentOptionsBuilder: _agentSelectorOptions,
      projectSubtitleFor: _projectSubtitleFor,
      showSettings: () async => _destinationController.showSettings(),
      showAgentEcosystem: _destinationController.showAgentEcosystem,
      showTaskCenter: _destinationController.showTaskCenter,
      showLongTaskStation: _destinationController.showLongTaskStation,
      showReviewCenter: _destinationController.showReviewCenter,
      showPromptTemplates: _destinationController.showPromptTemplates,
      showProjectAssets: _destinationController.showProjectAssets,
      announce: _announce,
    );
    _workbenchConversationController = WorkbenchConversationController(
      saveDraftUseCase: _saveDraftUseCase,
      generateDraftUseCaseFactory: _generateDraftUseCaseFactory,
      modelExecutionProfileService: _modelExecutionProfileService,
      conversationSessionStateService: _conversationSessionStateService,
      conversationStreamingStateService: _conversationStreamingStateService,
      conversationGuideViewDataService: _conversationGuideViewDataService,
      conversationUserVisibleTextService: _conversationUserVisibleTextService,
      workbenchPrimaryActionService: _workbenchPrimaryActionService,
      userOptionPromptBuilderService: _userOptionPromptBuilderService,
      loadModeGuidanceStateUseCase: _loadModeGuidanceStateUseCase,
      answerModeGuidanceStageUseCase: _answerModeGuidanceStageUseCase,
      buildModeGuidancePlanInputUseCase: _buildModeGuidancePlanInputUseCase,
      modeGuidanceTransitionService: _modeGuidanceTransitionService,
      workflowRuntimeService: _workflowRuntimeService,
      workspaceController: _workbenchWorkspaceController,
      readRuntimeState: () => _workbenchConversationRuntimeState,
      writeRuntimeState: (state) {
        _workbenchConversationRuntimeState = state;
      },
      readWorkbench: () => _viewModel.workbench,
      mutateWorkbench: _mutateWorkbench,
      readSettings: () => _settings,
      persistSettings: _persistSettings,
      refreshSettingsViewData: _refreshSettingsViewData,
      readThemeMode: () => _themeMode,
      writeThemeMode: (themeMode) {
        _themeMode = themeMode;
      },
      notifyShell: _safeNotifyListeners,
      showSettings: () async => _destinationController.showSettings(),
      contextStrategySettingsOf: _contextStrategySettingsOf,
      selectedModelProvider: _selectedModelProvider,
      agentLabel: _agentLabel,
      announce: _announce,
    );
    _projectCreationController = ProjectCreationController(
      loadProjectWorkspaceUseCase: _loadProjectWorkspaceUseCase,
      createProjectWorkspaceUseCase: _createProjectWorkspaceUseCase,
      discoverProjectsUseCase: _discoverProjectsUseCase,
      desktopProjectDirectoryPickerService: _desktopProjectDirectoryPickerService,
      projectLauncherViewDataService: _projectLauncherViewDataService,
      readWorkbench: () => _viewModel.workbench,
      mutateWorkbench: _mutateWorkbench,
      readCurrentProject: () => _workbenchWorkspaceController.currentProject,
      loadProject: _workbenchWorkspaceController.loadProject,
      resetToProjectlessWorkbench: _workbenchWorkspaceController.resetToProjectlessWorkbench,
      announce: _announce,
      readSettings: () => _settings,
      defaultProjectsRootPath: _defaultProjectsRootPath,
      settingsSearchRoots: _settingsSearchRoots,
      isMobileProjectRootLocked: _isMobileProjectRootLocked,
    );
    _workbenchWorkspaceController.attachProjectCreationController(
      _projectCreationController,
    );
  }

  final SettingsRepository _settingsRepository;
  final LoadProjectWorkspaceUseCase _loadProjectWorkspaceUseCase;
  final LoadModeGuidanceStateUseCase _loadModeGuidanceStateUseCase;
  final AnswerModeGuidanceStageUseCase _answerModeGuidanceStageUseCase;
  final BuildModeGuidancePlanInputUseCase _buildModeGuidancePlanInputUseCase;
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
  final ProjectAssetLibraryService _projectAssetLibraryService;
  final LongTaskStationController _longTaskStationController;
  final ConversationSessionStateService _conversationSessionStateService;
  final ConversationStreamingStateService _conversationStreamingStateService;
  final ConversationGuideViewDataService _conversationGuideViewDataService;
  final ConversationUserVisibleTextService _conversationUserVisibleTextService;
  final DesktopProjectDirectoryPickerService
  _desktopProjectDirectoryPickerService;
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
  final TaskCenterGuidanceRevisitMarkdownService
  _taskCenterGuidanceRevisitMarkdownService;
  final ReviewCenterViewDataService _reviewCenterViewDataService;
  final PromptTemplatesViewDataService _promptTemplatesViewDataService;
  final ProjectAssetsViewDataService _projectAssetsViewDataService;
  final PromptTemplatePreviewService _promptTemplatePreviewService;
  final PromptTemplateNormalizerService _promptTemplateNormalizerService;
  final ModelSettingsViewDataService _modelSettingsViewDataService;
  final ModelExecutionProfileService _modelExecutionProfileService;
  final ModeGuidanceTransitionService _modeGuidanceTransitionService;
  late final AppShellDestinationController _destinationController;
  late final WorkbenchWorkspaceController _workbenchWorkspaceController;
  late final WorkbenchConversationController _workbenchConversationController;
  late final ProjectCreationController _projectCreationController;

  AppShellViewModel _viewModel;
  AppSettings? _settings;
  WorkbenchProjectRuntimeState _workbenchProjectRuntimeState =
      const WorkbenchProjectRuntimeState();
  WorkbenchConversationRuntimeState _workbenchConversationRuntimeState =
      const WorkbenchConversationRuntimeState();
  ThemeMode _themeMode = ThemeMode.light;
  bool _disposed = false;
  bool _initialized = false;
  AgentEcosystemSnapshot _agentEcosystemSnapshot =
      AgentEcosystemSnapshot.initial();
  ProjectAssetsSnapshot _projectAssetsSnapshot =
      ProjectAssetsSnapshot.initial();
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
  String _projectAssetsStatusMessage = '';

  AppShellViewModel get viewModel => _viewModel;
  ThemeMode get themeMode => _themeMode;
  LongTaskStationController get longTaskStationController =>
      _longTaskStationController;
  ResourceManagerActionHandler get resourceManagerHandler =>
      _workbenchWorkspaceController;
  DocumentWorkspaceActionHandler get documentWorkspaceHandler =>
      _workbenchWorkspaceController;
  ConversationActionHandler get conversationHandler =>
      _workbenchConversationController;
  ProjectDescriptor? get _currentProject => _workbenchWorkspaceController.currentProject;

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
      await _projectCreationController.loadDefaultProject();
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
    _destinationController.showWorkbench();
  }

  void showSettings() {
    // 中文注释: 该方法统一负责切换到设置页，让设置入口不再分散在多个组件内部。
    _destinationController.showSettings();
  }

  void showAgentEcosystem() {
    // 中文注释: 该方法统一负责切换到智能体生态页，避免资源面板和会话面板各自维护路由。
    _destinationController.showAgentEcosystem();
  }

  void showTaskCenter() {
    // 中文注释: 长任务中心导航和数据刷新统一收口，避免资源栏与会话动作各自重复读任务目录。
    _destinationController.showTaskCenter();
  }

  void showLongTaskStation() {
    // 中文注释: 全局长任务总站只在壳层完成路由切换，真正的运行列表与动作逻辑交给独立子域控制器。
    _destinationController.showLongTaskStation();
  }

  void showReviewCenter() {
    // 中文注释: 审稿中心切换后立即刷新报告列表，让文档工具栏和左栏入口共用同一页面状态。
    _destinationController.showReviewCenter();
  }

  void showPromptTemplates() {
    // 中文注释: 模板页导航与数据刷新统一收口，避免后续从设置页或任务页进入时出现两套状态来源。
    _destinationController.showPromptTemplates();
  }

  void showProjectAssets() {
    // 中文注释: 项目资产页统一负责风格、伏笔与资产包入口，不把资产逻辑散回工作台。
    _destinationController.showProjectAssets();
  }

  void onModelSettingsRequested() => _workbenchWorkspaceController.onModelSettingsRequested();

  void onCreateProjectRequested() => _projectCreationController.onCreateProjectRequested();

  void onOpenProjectRequested() => _projectCreationController.onOpenProjectRequested();

  void onProjectLauncherDismissed() =>
      _projectCreationController.onProjectLauncherDismissed();

  void onProjectLauncherRefreshRequested() =>
      _projectCreationController.onProjectLauncherRefreshRequested();

  void onProjectEntryOpened(String projectPath) =>
      _projectCreationController.onProjectEntryOpened(projectPath);

  void onProjectCreationSubmitted(ProjectCreateRequestViewData request) =>
      _projectCreationController.onProjectCreationSubmitted(request);

  void onEditProjectInfoRequested() =>
      _workbenchWorkspaceController.onEditProjectInfoRequested();

  void onRefreshFilesRequested() =>
      _workbenchWorkspaceController.onRefreshFilesRequested();

  void onCreateFileRequested() =>
      _workbenchWorkspaceController.onCreateFileRequested();

  void onCreateFolderRequested() =>
      _workbenchWorkspaceController.onCreateFolderRequested();

  void onImportRequested() => _workbenchWorkspaceController.onImportRequested();

  void onCreateChapterRequested() =>
      _workbenchWorkspaceController.onCreateChapterRequested();

  void onSaveCurrentRequested() =>
      _workbenchWorkspaceController.onSaveCurrentRequested();

  void onAgentEcosystemRequested() =>
      _workbenchWorkspaceController.onAgentEcosystemRequested();

  void onTasksRequested() => _workbenchWorkspaceController.onTasksRequested();

  void onLongTaskStationRequested() =>
      _workbenchWorkspaceController.onLongTaskStationRequested();

  void onReviewsRequested() => _workbenchWorkspaceController.onReviewsRequested();

  void onTemplatesRequested() =>
      _workbenchWorkspaceController.onTemplatesRequested();

  void onProjectAssetsRequested() =>
      _workbenchWorkspaceController.onProjectAssetsRequested();

  void onResourceEntrySelected(String entryId) =>
      _workbenchWorkspaceController.onResourceEntrySelected(entryId);

  void onWorkspaceCommandDismissed() =>
      _workbenchWorkspaceController.onWorkspaceCommandDismissed();

  void onWorkspaceCommandSubmitted(WorkspaceCommandRequestViewData request) =>
      _workbenchWorkspaceController.onWorkspaceCommandSubmitted(request);

  void onDocumentActionRequested(DocumentToolbarAction action) =>
      _workbenchWorkspaceController.onDocumentActionRequested(action);

  void onDocumentSelected(String documentId) =>
      _workbenchWorkspaceController.onDocumentSelected(documentId);

  void onDocumentClosed(String documentId) =>
      _workbenchWorkspaceController.onDocumentClosed(documentId);

  void onDocumentBodyChanged(String value) =>
      _workbenchWorkspaceController.onDocumentBodyChanged(value);

  void onModelSelected(String modelId) =>
      _workbenchConversationController.onModelSelected(modelId);

  void onAgentSelected(String agentId) =>
      _workbenchConversationController.onAgentSelected(agentId);

  void onQuickThemeRequested() =>
      _workbenchConversationController.onQuickThemeRequested();

  void onScreenModeRequested() =>
      _workbenchConversationController.onScreenModeRequested();

  void onDocumentsWorkspaceRequested() =>
      _workbenchConversationController.onDocumentsWorkspaceRequested();

  void onDocumentsWorkspaceDismissRequested() =>
      _workbenchConversationController.onDocumentsWorkspaceDismissRequested();

  void onHistoryRequested() =>
      _workbenchConversationController.onHistoryRequested();

  void onNewSessionRequested() =>
      _workbenchConversationController.onNewSessionRequested();

  void onSessionHistorySelected(String sessionId) =>
      _workbenchConversationController.onSessionHistorySelected(sessionId);

  void onUserOptionSelected(UserOptionViewData option) =>
      _workbenchConversationController.onUserOptionSelected(option);

  void onConversationSettingsRequested() =>
      _workbenchConversationController.onConversationSettingsRequested();

  void onPrimaryActionRequested(String actionId) =>
      _workbenchConversationController.onPrimaryActionRequested(actionId);

  void onRetryLastFailedRequested() =>
      _workbenchConversationController.onRetryLastFailedRequested();

  void onOptimizeRequested() =>
      _workbenchConversationController.onOptimizeRequested();

  void onToolOptionsRequested() =>
      _workbenchConversationController.onToolOptionsRequested();

  void onSendRequested(String text) =>
      _workbenchConversationController.onSendRequested(text);

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
    final selectedTask = _taskByPath(_selectedTaskId);
    onTaskCenterSharedActionRequested(
      TaskCenterContractActionViewData(
        id: 'accept_revision',
        label: '接受修复',
        note: '',
        tone: 'success',
        invocationKind: 'revision_resolution',
        enabled: true,
        disabledReason: '',
        ownerTaskPath: ValueReaders.stringValue(selectedTask['relative_path']),
        checkpointReviewPath: '',
      ),
    );
  }

  @override
  void onTaskCenterRollbackRevisionRequested() {
    final selectedTask = _taskByPath(_selectedTaskId);
    onTaskCenterSharedActionRequested(
      TaskCenterContractActionViewData(
        id: 'rollback_revision',
        label: '回滚修复',
        note: '',
        tone: 'danger',
        invocationKind: 'revision_resolution',
        enabled: true,
        disabledReason: '',
        ownerTaskPath: ValueReaders.stringValue(selectedTask['relative_path']),
        checkpointReviewPath: '',
      ),
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
  void onTaskCenterSharedActionRequested(
    TaskCenterContractActionViewData action,
  ) {
    if (!action.enabled) {
      return;
    }
    switch (action.invocationKind) {
      case 'checkpoint_review':
        _runTaskCenterCheckpointAction(action);
        return;
      case 'revision_resolution':
        _runTaskCenterRevisionResolutionAction(action);
        return;
      default:
        _announce('当前动作类型尚未支持。');
    }
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

  @override
  void onProjectAssetsBackRequested() {
    // 中文注释: 资产页返回只切回工作台，资产快照仍留在控制器里供下次直接恢复。
    showWorkbench();
  }

  @override
  void onProjectAssetsRefreshRequested() {
    // 中文注释: 资产刷新统一重读 styles/ 与 world/foreshadows/，避免页面直接扫目录。
    _refreshProjectAssets();
  }

  @override
  void onProjectAssetsTabSelected(String tabId) {
    _projectAssetsSnapshot = _projectAssetsSnapshot.copyWith(
      activeTabId: tabId,
    );
    _refreshProjectAssetsView();
  }

  @override
  void onProjectAssetsEntrySelected(String entryId) {
    if (_projectAssetsSnapshot.activeTabId == 'foreshadows') {
      _projectAssetsSnapshot = _projectAssetsSnapshot.copyWith(
        selectedForeshadowId: entryId,
      );
    } else {
      _projectAssetsSnapshot = _projectAssetsSnapshot.copyWith(
        selectedStyleId: entryId,
      );
    }
    _refreshProjectAssetsView();
  }

  @override
  void onProjectAssetsNewRequested() {
    if (_projectAssetsSnapshot.activeTabId == 'foreshadows') {
      _projectAssetsSnapshot = _projectAssetsSnapshot.copyWith(
        selectedForeshadowId: '',
      );
      _projectAssetsStatusMessage = '正在创建新的伏笔资产。';
    } else {
      _projectAssetsSnapshot = _projectAssetsSnapshot.copyWith(
        selectedStyleId: '',
      );
      _projectAssetsStatusMessage = '正在创建新的风格资产。';
    }
    _refreshProjectAssetsView();
  }

  @override
  void onProjectAssetsSaveStyleRequested(
    StyleProfileEditorRequestViewData request,
  ) async {
    final project = _currentProject;
    if (project == null) {
      await _refreshProjectAssets(status: '请先创建或打开项目。');
      return;
    }
    final result = await _projectAssetLibraryService
        .saveStyle(project, <String, Object?>{
          'id': request.id.trim(),
          'display_name': request.displayName.trim(),
          'summary': request.summary,
          'genre': request.genre.trim(),
          'tone': request.tone.trim(),
          'audience': request.audience.trim(),
          'tags': _csvList(request.tagsText),
          'guardrails': _csvList(request.guardrailsText),
          'example_paths': _csvList(request.examplePathsText),
          'inherited_from_ids': _csvList(request.inheritedIdsText),
          'default_for_project': request.defaultForProject,
        });
    await _syncWorkbenchResources();
    if (ValueReaders.boolValue(result['ok'])) {
      _projectAssetsSnapshot = _projectAssetsSnapshot.copyWith(
        activeTabId: 'styles',
        selectedStyleId: ValueReaders.stringValue(
          ValueReaders.mapValue(result['asset'])['id'],
        ),
      );
    }
    await _refreshProjectAssets(
      status: _resultMessage(result, success: '风格资产已保存。'),
    );
  }

  @override
  void onProjectAssetsSaveForeshadowRequested(
    ForeshadowRecordEditorRequestViewData request,
  ) async {
    final project = _currentProject;
    if (project == null) {
      await _refreshProjectAssets(status: '请先创建或打开项目。');
      return;
    }
    final result = await _projectAssetLibraryService
        .saveForeshadow(project, <String, Object?>{
          'id': request.id.trim(),
          'title': request.title.trim(),
          'status': request.status.trim(),
          'summary': request.summary,
          'planted_chapter_path': request.plantedChapterPath.trim(),
          'target_payoff_path': request.targetPayoffPath.trim(),
          'related_entity_ids': _csvList(request.relatedEntityIdsText),
          'related_paths': _csvList(request.relatedPathsText),
          'trigger_conditions': _csvList(request.triggerConditionsText),
          'payoff_expectations': _csvList(request.payoffExpectationsText),
          'tags': _csvList(request.tagsText),
          'notes': request.notes,
        });
    await _syncWorkbenchResources();
    if (ValueReaders.boolValue(result['ok'])) {
      _projectAssetsSnapshot = _projectAssetsSnapshot.copyWith(
        activeTabId: 'foreshadows',
        selectedForeshadowId: ValueReaders.stringValue(
          ValueReaders.mapValue(result['asset'])['id'],
        ),
      );
    }
    await _refreshProjectAssets(
      status: _resultMessage(result, success: '伏笔资产已保存。'),
    );
  }

  @override
  void onProjectAssetsDeleteRequested({
    required String kind,
    required String id,
  }) async {
    final project = _currentProject;
    if (project == null) {
      await _refreshProjectAssets(status: '请先创建或打开项目。');
      return;
    }
    if (id.trim().isEmpty) {
      await _refreshProjectAssets(status: '请先选择一个资产。');
      return;
    }
    final result = kind == 'foreshadow'
        ? await _projectAssetLibraryService.deleteForeshadow(project, id.trim())
        : await _projectAssetLibraryService.deleteStyle(project, id.trim());
    await _syncWorkbenchResources();
    if (ValueReaders.boolValue(result['ok'])) {
      if (kind == 'foreshadow') {
        _projectAssetsSnapshot = _projectAssetsSnapshot.copyWith(
          selectedForeshadowId: '',
        );
      } else {
        _projectAssetsSnapshot = _projectAssetsSnapshot.copyWith(
          selectedStyleId: '',
        );
      }
    }
    await _refreshProjectAssets(
      status: _resultMessage(result, success: '资产已删除。'),
    );
  }

  @override
  void onProjectAssetsImportBundleRequested(
    ProjectAssetBundleImportRequestViewData request,
  ) async {
    final project = _currentProject;
    if (project == null) {
      await _refreshProjectAssets(status: '请先创建或打开项目。');
      return;
    }
    if (request.absolutePath.trim().isEmpty) {
      await _refreshProjectAssets(status: '请提供资产包绝对路径。');
      return;
    }
    final bundleContent = await _projectAssetLibraryService.readExternalBundle(
      request.absolutePath.trim(),
    );
    if ((bundleContent ?? '').trim().isEmpty) {
      await _refreshProjectAssets(status: '资产包文件不存在或不可读。');
      return;
    }
    final preview = _projectAssetLibraryService.previewImportBundle(
      project,
      bundleContent: bundleContent!,
      currentStyles: _projectAssetsSnapshot.styles,
      currentForeshadows: _projectAssetsSnapshot.foreshadows,
      overwrite: request.overwrite,
    );
    if (!ValueReaders.boolValue(preview['ok'])) {
      await _refreshProjectAssets(status: '资产包预检失败。');
      return;
    }
    final result = await _projectAssetLibraryService.importBundle(
      project,
      bundleContent: bundleContent,
      overwrite: request.overwrite,
    );
    await _syncWorkbenchResources();
    await _refreshProjectAssets(
      status:
          '${_resultMessage(result, success: '资产包已导入。')} 预检条目 ${ValueReaders.objectList(preview['items']).length} 个。',
    );
  }

  @override
  void onProjectAssetsExportBundleRequested(
    ProjectAssetBundleExportRequestViewData request,
  ) async {
    final project = _currentProject;
    if (project == null) {
      await _refreshProjectAssets(status: '请先创建或打开项目。');
      return;
    }
    final result = await _projectAssetLibraryService.exportBundle(
      project,
      title: request.title.trim(),
      description: request.description.trim(),
    );
    await _syncWorkbenchResources();
    await _refreshProjectAssets(
      status: _resultMessage(result, success: '资产包已导出。'),
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
    final checkpointActionPackage = selectedTask.isEmpty
        ? const <String, Object?>{}
        : await _loadTaskCenterCheckpointActionPackage(
            project,
            selectedTask,
            execution,
          );
    final guidanceRevisitPackage = checkpointActionPackage.isEmpty
        ? const <String, Object?>{}
        : await _loadTaskCenterGuidanceRevisitPackage(
            project,
            checkpointActionPackage,
          );
    final revisionResolution = selectedTask.isEmpty
        ? const <String, Object?>{}
        : await _loadTaskCenterRevisionResolution(project, selectedTask);
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
        checkpointActionPackage: checkpointActionPackage,
        revisionResolution: revisionResolution,
        guidanceRevisitBody: _taskCenterGuidanceRevisitMarkdownService.render(
          guidanceRevisitPackage,
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

  Future<void> _refreshProjectAssets({String? status}) async {
    // 中文注释: 资产页刷新统一走资产服务，GUI 不直接操作 frontmatter 和项目目录规则。
    final project = _currentProject;
    if (project == null) {
      _projectAssetsSnapshot = ProjectAssetsSnapshot.initial();
      _projectAssetsStatusMessage = status ?? '请先创建或打开项目。';
      _refreshProjectAssetsView();
      return;
    }
    final styles = await _projectAssetLibraryService.listStyles(project);
    final foreshadows = await _projectAssetLibraryService.listForeshadows(
      project,
    );
    _projectAssetsSnapshot = _projectAssetsSnapshot.copyWith(
      styles: styles,
      foreshadows: foreshadows,
      selectedStyleId: _selectedAssetIdOrFallback(
        currentId: _projectAssetsSnapshot.selectedStyleId,
        entries: styles,
      ),
      selectedForeshadowId: _selectedAssetIdOrFallback(
        currentId: _projectAssetsSnapshot.selectedForeshadowId,
        entries: foreshadows,
      ),
    );
    _projectAssetsStatusMessage = status ?? _projectAssetsStatusMessage;
    _refreshProjectAssetsView();
  }

  void _refreshProjectAssetsView() {
    // 中文注释: 资产页视图重建只做快照到表单的投影，不在这里碰文件系统。
    _viewModel = _viewModel.copyWith(
      projectAssets: _projectAssetsViewDataService.build(
        snapshot: _projectAssetsSnapshot,
        status: _projectAssetsStatusMessage,
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

  Future<JsonMap> _loadTaskCenterCheckpointActionPackage(
    ProjectDescriptor project,
    JsonMap task,
    JsonMap execution,
  ) async {
    // 中文注释: 普通任务优先显示检查点动作，revision 任务则交给修订收口合同单独处理。
    if (ValueReaders.stringValue(task['task_type']) == 'revision') {
      return const <String, Object?>{};
    }
    final checkpointReviewPath = _taskCenterCheckpointReviewPath(
      task,
      execution,
    );
    if (checkpointReviewPath.isEmpty) {
      return const <String, Object?>{};
    }
    return _workflowRuntimeService.buildCheckpointReviewActionPackage(
      project,
      checkpointReviewPath,
    );
  }

  Future<JsonMap> _loadTaskCenterRevisionResolution(
    ProjectDescriptor project,
    JsonMap task,
  ) {
    // 中文注释: revision 专属的收口动作直接复用共享 runtime 合同，不在控制器里重写判断规则。
    if (ValueReaders.stringValue(task['task_type']) != 'revision') {
      return Future<JsonMap>.value(const <String, Object?>{});
    }
    return _workflowRuntimeService.buildRevisionResolution(
      project,
      _taskSelector(task),
    );
  }

  Future<JsonMap> _loadTaskCenterGuidanceRevisitPackage(
    ProjectDescriptor project,
    JsonMap checkpointActionPackage,
  ) {
    // 中文注释: 只有当前 checkpoint 动作已经建议“回看长期约束”时，详情区才去加载对应回看包。
    for (final action in ValueReaders.mapList(
      checkpointActionPackage['actions'],
    )) {
      if (ValueReaders.stringValue(action['id']) == 'revisit_mode_guidance' &&
          ValueReaders.boolValue(action['enabled'])) {
        final checkpointReviewPath = ValueReaders.stringValue(
          checkpointActionPackage['checkpoint_review_path'],
        ).trim();
        if (checkpointReviewPath.isEmpty) {
          return Future<JsonMap>.value(const <String, Object?>{});
        }
        return _workflowRuntimeService.buildCheckpointGuidanceRevisitPackage(
          project,
          checkpointReviewPath,
        );
      }
    }
    return Future<JsonMap>.value(const <String, Object?>{});
  }

  String _taskCenterCheckpointReviewPath(JsonMap task, JsonMap execution) {
    // 中文注释: 旧记录可能只在 execution 上有检查点路径，因此这里做一次统一兜底。
    for (final candidate in <String>[
      ValueReaders.stringValue(task['checkpoint_review_path']),
      ValueReaders.stringValue(execution['checkpoint_review_path']),
    ]) {
      final clean = candidate.trim();
      if (clean.isNotEmpty) {
        return clean;
      }
    }
    return '';
  }

  void _runTaskCenterCheckpointAction(TaskCenterContractActionViewData action) {
    _runTaskCenterProjectCommand(
      pendingMessage: action.id == 'revisit_mode_guidance'
          ? '正在载入长期约束回看...'
          : '正在执行${action.label}...',
      successMessage: action.id == 'revisit_mode_guidance'
          ? '已载入长期约束回看。'
          : '${action.label}已完成。',
      operation: (project, settings) {
        return _workflowRuntimeService.applyCheckpointReviewAction(
          project,
          action.checkpointReviewPath,
          action.id,
        );
      },
    );
  }

  void _runTaskCenterRevisionResolutionAction(
    TaskCenterContractActionViewData action,
  ) {
    _runTaskCenterProjectCommand(
      pendingMessage: '正在执行${action.label}...',
      successMessage: '${action.label}已完成。',
      operation: (project, settings) {
        return _workflowRuntimeService.applyRevisionResolutionAction(
          project,
          <String, Object?>{'relative_path': action.ownerTaskPath},
          action.id,
        );
      },
    );
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

  List<String> _csvList(String rawText) {
    // 中文注释: 资产编辑器里的轻量列表字段统一按逗号切分，避免每个保存动作重复做同样转换。
    return rawText
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
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

  String _selectedAssetIdOrFallback({
    required String currentId,
    required List<JsonMap> entries,
  }) {
    // 中文注释: 资产刷新后统一修正选中态，避免新增、删除或导入后仍指向失效条目。
    final cleanCurrentId = currentId.trim();
    for (final entry in entries) {
      if (_stringValue(entry['id']) == cleanCurrentId) {
        return cleanCurrentId;
      }
    }
    if (entries.isEmpty) {
      return '';
    }
    return _stringValue(entries.first['id']);
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
    _longTaskStationController.dispose();
    super.dispose();
  }

  Future<void> _openResource(String relativePath) async {
    // 中文注释: 资源打开统一委派给工作区控制器，壳层不再直接读盘或维护文档标签。
    await _workbenchWorkspaceController.openResource(relativePath);
  }

  Future<List<ResourceEntryViewData>> _reloadResourceEntries({
    required String selectedId,
  }) async {
    // 中文注释: 资源树重载统一从工作区控制器获取，避免壳层继续维护目录快照细节。
    return _workbenchWorkspaceController.reloadResourceEntries(
      selectedId: selectedId,
    );
  }

  Future<void> _refreshActiveDestinationAfterProjectLoad() async {
    // 中文注释: 切换项目后，如果当前正停留在任务/审稿/模板页，就把这些页面一并刷新到新项目上下文。
    switch (_viewModel.destination) {
      case AppDestination.longTaskStation:
        await _longTaskStationController.refresh();
        return;
      case AppDestination.taskCenter:
        await _refreshTaskCenter();
        return;
      case AppDestination.reviewCenter:
        await _refreshReviewCenter();
        return;
      case AppDestination.promptTemplates:
        await _refreshPromptTemplates();
        return;
      case AppDestination.projectAssets:
        await _refreshProjectAssets();
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
    try {
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
    }
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

  String _projectSubtitleFor(String projectType) {
    // 中文注释: 项目副标题只显示类型语义，不再占位置解释运行链路状态。
    return ProjectTypeCatalogService().definitionOf(projectType).name;
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

  void _announce(String message) {
    // 中文注释: 轻量提示仍由壳层汇总，但会话投影交给专用会话控制器统一处理。
    _updateWorkbench(
      _workbenchConversationController.applyConversationState(
        _viewModel.workbench.copyWith(generationStatus: message),
      ),
    );
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

  void _changeDestination(AppDestination destination) {
    // 中文注释: 壳层自己只保留全局路由切换，不把任何 feature 状态偷偷绑在目的地切换里。
    _viewModel = _viewModel.copyWith(destination: destination);
    _safeNotifyListeners();
  }

  void _mutateWorkbench(
    WorkbenchViewData Function(WorkbenchViewData current) transform,
  ) {
    // 中文注释: 所有工作台视图态变更都经过同一入口，避免多个子控制器各自直接改 viewModel。
    _updateWorkbench(transform(_viewModel.workbench));
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
