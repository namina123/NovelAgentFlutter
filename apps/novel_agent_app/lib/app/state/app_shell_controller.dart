import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../diagnostics/controller_notify_trace_service.dart';
import '../diagnostics/navigation_trace_service.dart';
import '../diagnostics/project_hydration_trace_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_preference_resolver.dart';
import '../../features/agent_ecosystem/application/models/agent_ecosystem_snapshot.dart';
import '../../features/agent_ecosystem/application/services/agent_ecosystem_view_data_service.dart';
import '../../features/agent_ecosystem/application/services/customization_import_preview_text_service.dart';
import '../../features/agent_ecosystem/application/services/ecosystem_entry_creation_plan_service.dart';
import '../../features/agent_ecosystem/application/services/ecosystem_entry_editor_service.dart';
import '../../features/agent_ecosystem/application/models/project_skill_loadout_workspace_snapshot.dart';
import '../../features/agent_ecosystem/application/services/project_skill_loadout_view_data_service.dart';
import '../../features/agent_ecosystem/application/services/project_skill_loadout_workspace_service.dart';
import '../../features/agent_ecosystem/presentation/contracts/agent_ecosystem_action_handler.dart';
import '../../features/agent_ecosystem/presentation/models/ecosystem_editor_view_data.dart';
import '../../features/agent_ecosystem/presentation/models/ecosystem_import_command_view_data.dart';
import '../../features/agent_ecosystem/presentation/models/agent_ecosystem_view_data.dart';
import '../../features/agent_ecosystem/presentation/models/project_skill_loadout_view_data.dart';
import '../../features/book_deconstruction/application/controllers/book_deconstruction_controller.dart';
import '../../features/book_deconstruction/application/services/book_deconstruction_application_plan_materialization_service.dart';
import '../../features/book_deconstruction/application/services/book_deconstruction_derived_project_creation_service.dart';
import '../../features/workbench/application/services/import_assistant_model_options_service.dart';
import '../../features/book_deconstruction/application/services/book_deconstruction_narrative_persistence_service.dart';
import '../../features/book_deconstruction/application/services/desktop_book_deconstruction_source_picker_service.dart';
import '../../features/inspiration_workbench/application/controllers/inspiration_workbench_controller.dart';
import '../../features/long_task_station/application/controllers/long_task_station_controller.dart';
import '../../features/project_assets/application/controllers/project_assets_controller.dart';
import '../../features/project_assets/application/services/project_assets_loader_service.dart';
import '../../features/project_assets/application/services/project_rag_extraction_execution_service.dart';
import '../../features/project_assets/application/services/project_reference_extraction_execution_service.dart';
import '../../features/project_assets/application/services/project_expression_constraint_workspace_service.dart';
import '../../features/project_creation/application/controllers/project_creation_controller.dart';
import '../../features/project_creation/application/services/project_creation_expression_constraint_defaults_service.dart';
import '../../features/project_creation/application/services/project_creation_expression_constraint_defaults_settings_service.dart';
import '../../features/prompt_templates/application/services/prompt_templates_view_data_service.dart';
import '../../features/prompt_templates/presentation/contracts/prompt_templates_action_handler.dart';
import '../../features/prompt_templates/presentation/models/prompt_templates_view_data.dart';
import '../../features/project_collection/application/models/project_collection_snapshot.dart';
import '../../features/project_collection/application/services/project_collection_loader_service.dart';
import '../../features/project_collection/presentation/contracts/project_collection_action_handler.dart';
import '../../features/project_collection/presentation/models/project_collection_view_data.dart';
import '../../features/project_open/application/controllers/project_open_controller.dart';
import '../../features/project_open/application/services/project_open_view_data_service.dart';
import '../../features/project_open/presentation/contracts/project_open_action_handler.dart';
import '../../features/project_open/presentation/models/project_open_view_data.dart';
import '../../features/review_center/application/services/review_center_view_data_service.dart';
import '../../features/review_center/application/models/review_center_analysis_state.dart';
import '../../features/review_center/application/services/review_center_analysis_state_service.dart';
import '../../features/review_center/application/services/review_center_playback_preview_service.dart';
import '../../features/review_center/presentation/contracts/review_center_action_handler.dart';
import '../../features/review_center/presentation/models/review_center_view_data.dart';
import '../../features/settings/application/services/model_settings_view_data_service.dart';
import '../../features/settings/application/services/context_settings_contract_service.dart';
import '../../features/settings/application/services/project_creation_expression_constraint_defaults_view_data_service.dart';
import '../../features/settings/application/services/provider_connection_validation_service.dart'
    as app_settings;
import '../../features/settings/application/services/provider_settings_directory_service.dart';
import '../../features/settings/application/services/provider_connection_probe_service.dart';
import '../../features/settings/application/services/theme_settings_view_data_service.dart';
import '../../shared/services/user_facing_error_humanizer.dart';
import '../../features/settings/presentation/contracts/settings_action_handler.dart';
import '../../features/settings/presentation/models/model_editor_view_data.dart';
import '../../features/settings/presentation/models/settings_view_data.dart';
import '../../features/task_center/application/services/task_center_command_orchestration_service.dart';
import '../../features/task_center/application/services/task_center_refresh_service.dart';
import '../../features/task_center/application/services/task_center_workflow_create_option_mapper_service.dart';
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
import '../../features/workbench/application/services/conversation_opening_panel_view_data_service.dart';
import '../../features/workbench/application/services/conversation_input_capability_context_builder_service.dart';
import '../../features/workbench/application/services/conversation_group_selector_view_data_service.dart';
import '../../features/workbench/application/services/workbench_opening_launch_bridge_service.dart';
import '../../features/workbench/application/services/project_agent_group_workspace_view_data_service.dart';
import '../../features/workbench/application/services/project_opening_session_projection_service.dart';
import '../../features/workbench/application/services/project_opening_agent_group_binding_service.dart';
import '../../features/workbench/application/services/desktop_project_directory_picker_service.dart';
import '../../features/workbench/application/services/project_launcher_view_data_service.dart';
import '../../features/workbench/application/services/workbench_primary_action_service.dart';
import '../../features/workbench/application/services/conversation_user_visible_text_service.dart';
import '../../features/workbench/presentation/contracts/conversation_action_handler.dart';
import '../../features/workbench/presentation/contracts/document_workspace_action_handler.dart';
import '../../features/workbench/presentation/contracts/resource_manager_action_handler.dart';
import '../../features/workbench/presentation/models/conversation_group_selector_view_data.dart';
import '../../features/workbench/presentation/models/project_create_request_view_data.dart';
import '../../features/workbench/presentation/models/project_creation_phase.dart';
import '../../features/workbench/presentation/models/project_launcher_view_data.dart';
import '../../features/workbench/presentation/models/conversation_input_capability_context.dart';
import '../../features/workbench/presentation/models/project_agent_group_workspace_view_data.dart';
import '../../features/workbench/presentation/models/selector_option_view_data.dart';
import '../../features/workbench/presentation/models/tool_preview_mode.dart';
import '../../features/workbench/presentation/models/user_option_view_data.dart';
import '../../features/workbench/presentation/models/workbench_canvas_view_data.dart';
import '../../features/workbench/presentation/models/workbench_conversation_view_data.dart';
import '../../features/workbench/presentation/models/workbench_overlay_view_data.dart';
import '../../features/workbench/presentation/models/workbench_resource_view_data.dart';
import '../../features/workbench/presentation/models/workbench_view_data.dart';
import '../navigation/app_shell_navigation_action_handler.dart';
import '../navigation/app_shell_navigation_catalog.dart';
import '../navigation/app_shell_navigation_section.dart';
import '../../shared/view_models/app_shell_view_model.dart';
import '../routing/app_destination.dart';
import 'app_shell_auxiliary_controllers.dart';
import 'app_shell_destination_controller.dart';
import 'book_deconstruction_workspace_policy.dart';
import 'feature_refresh_intent.dart';
import 'feature_visibility_state.dart';
import 'app_shell_listenable_state.dart';
import 'app_shell_project_open_controller.dart';
import 'project_bound_feature_refresh_policy.dart';
import 'project_lifecycle_coordinator.dart';

typedef LoadAgentPackages =
    Future<List<JsonMap>> Function(ProjectDescriptor project);
typedef LoadAgentGroups =
    Future<List<JsonMap>> Function(ProjectDescriptor project);
typedef LoadSkillPackages =
    Future<List<JsonMap>> Function(ProjectDescriptor project);
typedef LoadSkillGroups =
    Future<List<JsonMap>> Function(ProjectDescriptor project);
typedef LoadProjectSkillLoadouts =
    Future<List<AgentSkillLoadout>> Function(ProjectDescriptor project);
typedef SaveProjectSkillLoadouts =
    Future<void> Function(
      ProjectDescriptor project,
      List<AgentSkillLoadout> loadouts,
    );
typedef LoadProjectSkillLoadoutHistory =
    Future<List<AgentSkillLoadoutHistoryEntry>> Function(
      ProjectDescriptor project,
    );
typedef SaveProjectSkillLoadoutHistoryEntry =
    Future<void> Function(
      ProjectDescriptor project,
      AgentSkillLoadoutHistoryEntry entry,
    );
typedef SaveProjectSkillLoadoutAsGroup =
    Future<String> Function({
      required ProjectDescriptor project,
      required ResolvedAgentSkillLoadout loadout,
      required String groupId,
      required String displayName,
      required String description,
    });

class AppShellController extends ChangeNotifier
    implements
        AppShellNavigationActionHandler,
        SettingsActionHandler,
        AgentEcosystemActionHandler,
        ProjectOpenActionHandler,
        ProjectCollectionActionHandler,
        TaskCenterActionHandler,
        ReviewCenterActionHandler,
        PromptTemplatesActionHandler {
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
    required CreateProjectEntryUseCase createProjectEntryUseCase,
    required ImportProjectFilesUseCase importProjectFilesUseCase,
    required UpdateProjectManifestUseCase updateProjectManifestUseCase,
    ExecuteProjectTypeTransitionUseCase? executeProjectTypeTransitionUseCase,
    required ProjectToolHostPort projectToolHostPort,
    required BookDeconstructionNarrativePersistenceService
    bookDeconstructionNarrativePersistenceService,
    required ProjectRuntimeProfileRepository projectRuntimeProfileRepository,
    required ProjectAgentGroupBindingRepository
    projectAgentGroupBindingRepository,
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
    required LoadProjectSkillLoadouts loadProjectSkillLoadouts,
    required SaveProjectSkillLoadouts saveProjectSkillLoadouts,
    required LoadProjectSkillLoadoutHistory loadProjectSkillLoadoutHistory,
    required SaveProjectSkillLoadoutHistoryEntry
    saveProjectSkillLoadoutHistoryEntry,
    required SaveProjectSkillLoadoutAsGroup saveProjectSkillLoadoutAsGroup,
    required WriteProjectTextFileUseCase writeProjectTextFileUseCase,
    required GenerateDraftUseCaseFactory generateDraftUseCaseFactory,
    required LlmGateway Function(
      ProviderEndpointSettings provider,
      JsonMap networkSettings,
    )
    llmGatewayFactory,
    HostAwareGenerateDraftUseCaseFactory? hostAwareGenerateDraftUseCaseFactory,
    required ProjectWorkflowRuntimeService workflowRuntimeService,
    required ProjectReferenceExtractionRuntimeService
    referenceExtractionRuntimeService,
    ProjectReferenceExtractionExecutionService?
    projectReferenceExtractionExecutionService,
    required ProjectConversationDraftRuntimeService
    conversationDraftRuntimeService,
    required ProjectDraftExecutionConstraintRuntimeService
    draftExecutionConstraintRuntimeService,
    required ProjectReviewReportService reviewReportService,
    required ProjectChapterRewriteTaskService projectChapterRewriteTaskService,
    required ProjectPromptTemplateService promptTemplateService,
    required ProjectAssetLibraryService projectAssetLibraryService,
    required ProjectTimelineRepository projectTimelineRepository,
    required ProjectRelationshipRepository projectRelationshipRepository,
    required ProjectExpressionConstraintWorkspaceService
    projectExpressionConstraintWorkspaceService,
    required ProjectGeneralContinuitySetupService
    projectGeneralContinuitySetupService,
    ProjectPendingResearchActionService? pendingResearchActionService,
    required ProjectToolPermissionApprovalRecordService
    toolPermissionApprovalRecordService,
    required LongTaskSupervisor longTaskSupervisor,
    required LongTaskStationController longTaskStationController,
    DesktopBookDeconstructionSourcePickerService?
    desktopBookDeconstructionSourcePickerService,
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
    ProjectSkillLoadoutWorkspaceService? projectSkillLoadoutWorkspaceService,
    ProjectSkillLoadoutViewDataService? projectSkillLoadoutViewDataService,
    CustomizationImportPreviewTextService?
    customizationImportPreviewTextService,
    ProjectOpenController? projectOpenController,
    ProjectOpenViewDataService? projectOpenViewDataService,
    ProjectCollectionLoaderService? projectCollectionLoaderService,
    TaskCenterCommandOrchestrationService?
    taskCenterCommandOrchestrationService,
    TaskCenterRefreshService? taskCenterRefreshService,
    TaskCenterWorkflowCreateOptionMapperService?
    taskCenterWorkflowCreateOptionMapperService,
    ReviewCenterViewDataService? reviewCenterViewDataService,
    ReviewCenterAnalysisStateService? reviewCenterAnalysisStateService,
    ReviewCenterPlaybackPreviewService? reviewCenterPlaybackPreviewService,
    PromptTemplatesViewDataService? promptTemplatesViewDataService,
    PromptTemplatePreviewService? promptTemplatePreviewService,
    PromptTemplateNormalizerService? promptTemplateNormalizerService,
    ModelSettingsViewDataService? modelSettingsViewDataService,
    ProjectCreationExpressionConstraintDefaultsViewDataService?
    projectCreationExpressionConstraintDefaultsViewDataService,
    ConversationInputCapabilityContextBuilderService?
    conversationInputCapabilityContextBuilderService,
    ThemeSettingsViewDataService? themeSettingsViewDataService,
    ModelExecutionProfileService? modelExecutionProfileService,
    ModeGuidanceTransitionService? modeGuidanceTransitionService,
    ProjectLifecycleCoordinator? projectLifecycleCoordinator,
    ProjectBoundFeatureRefreshPolicy? projectBoundFeatureRefreshPolicy,
    ControllerNotifyTraceService? controllerNotifyTraceService,
    NavigationTraceService? navigationTraceService,
    ProjectHydrationTraceService? projectHydrationTraceService,
  }) : _settingsRepository = settingsRepository,
       _loadProjectWorkspaceUseCase = loadProjectWorkspaceUseCase,
       _loadModeGuidanceStateUseCase = loadModeGuidanceStateUseCase,
       _answerModeGuidanceStageUseCase = answerModeGuidanceStageUseCase,
       _buildModeGuidancePlanInputUseCase = buildModeGuidancePlanInputUseCase,
       _readProjectFileUseCase = readProjectFileUseCase,
       _saveDraftUseCase = saveDraftUseCase,
       _createProjectWorkspaceUseCase = createProjectWorkspaceUseCase,
       _createProjectEntryUseCase = createProjectEntryUseCase,
       _importProjectFilesUseCase = importProjectFilesUseCase,
       _updateProjectManifestUseCase = updateProjectManifestUseCase,
       _executeProjectTypeTransitionUseCase =
           executeProjectTypeTransitionUseCase,
       _projectToolHostPort = projectToolHostPort,
       _bookDeconstructionNarrativePersistenceService =
           bookDeconstructionNarrativePersistenceService,
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
       _llmGatewayFactory = llmGatewayFactory,
       _hostAwareGenerateDraftUseCaseFactory =
           hostAwareGenerateDraftUseCaseFactory,
       _workflowRuntimeService = workflowRuntimeService,
       _referenceExtractionRuntimeService = referenceExtractionRuntimeService,
       _injectedProjectReferenceExtractionExecutionService =
           projectReferenceExtractionExecutionService,
       _conversationDraftRuntimeService = conversationDraftRuntimeService,
       _reviewReportService = reviewReportService,
       _projectChapterRewriteTaskService = projectChapterRewriteTaskService,
       _promptTemplateService = promptTemplateService,
       _projectAssetLibraryService = projectAssetLibraryService,
       _projectTimelineRepository = projectTimelineRepository,
       _projectRelationshipRepository = projectRelationshipRepository,
       _projectExpressionConstraintWorkspaceService =
           projectExpressionConstraintWorkspaceService,
       _projectGeneralContinuitySetupService =
           projectGeneralContinuitySetupService,
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
           agentEcosystemViewDataService ?? AgentEcosystemViewDataService(),
       _ecosystemEntryCreationPlanService =
           ecosystemEntryCreationPlanService ??
           EcosystemEntryCreationPlanService(),
       _ecosystemEntryEditorService =
           ecosystemEntryEditorService ?? EcosystemEntryEditorService(),
       _projectSkillLoadoutWorkspaceService =
           projectSkillLoadoutWorkspaceService ??
           ProjectSkillLoadoutWorkspaceService(
             loadLoadouts: loadProjectSkillLoadouts,
             saveLoadouts: saveProjectSkillLoadouts,
             loadHistoryEntries: loadProjectSkillLoadoutHistory,
             saveHistoryEntry: saveProjectSkillLoadoutHistoryEntry,
             saveAsGroup: saveProjectSkillLoadoutAsGroup,
           ),
       _projectSkillLoadoutViewDataService =
           projectSkillLoadoutViewDataService ??
           ProjectSkillLoadoutViewDataService(),
       _customizationImportPreviewTextService =
           customizationImportPreviewTextService ??
           const CustomizationImportPreviewTextService(),
       _projectOpenLifecycleController =
           projectOpenController ?? ProjectOpenController(),
       _projectOpenViewDataService =
           projectOpenViewDataService ?? ProjectOpenViewDataService(),
       _projectCollectionLoaderService =
           projectCollectionLoaderService ?? ProjectCollectionLoaderService(),
       _taskCenterCommandOrchestrationService =
           taskCenterCommandOrchestrationService ??
           const TaskCenterCommandOrchestrationService(),
       _taskCenterRefreshService =
           taskCenterRefreshService ??
           TaskCenterRefreshService(
             runtimeQueryPort: workflowRuntimeService,
             taskCenterCommandOrchestrationService:
                 taskCenterCommandOrchestrationService ??
                 const TaskCenterCommandOrchestrationService(),
           ),
       _taskCenterWorkflowCreateOptionMapperService =
           taskCenterWorkflowCreateOptionMapperService ??
           const TaskCenterWorkflowCreateOptionMapperService(),
       _reviewCenterViewDataService =
           reviewCenterViewDataService ?? const ReviewCenterViewDataService(),
       _reviewCenterAnalysisStateService =
           reviewCenterAnalysisStateService ??
           const ReviewCenterAnalysisStateService(),
       _reviewCenterPlaybackPreviewService =
           reviewCenterPlaybackPreviewService ??
           const ReviewCenterPlaybackPreviewService(),
       _promptTemplatesViewDataService =
           promptTemplatesViewDataService ??
           const PromptTemplatesViewDataService(),
       _promptTemplatePreviewService =
           promptTemplatePreviewService ?? PromptTemplatePreviewService(),
       _promptTemplateNormalizerService =
           promptTemplateNormalizerService ?? PromptTemplateNormalizerService(),
       _modelSettingsViewDataService =
           modelSettingsViewDataService ?? ModelSettingsViewDataService(),
       _projectCreationExpressionConstraintDefaultsViewDataService =
           projectCreationExpressionConstraintDefaultsViewDataService ??
           ProjectCreationExpressionConstraintDefaultsViewDataService(),
       _providerSettingsDirectoryService = ProviderSettingsDirectoryService(),
       _conversationInputCapabilityContextBuilderService =
           conversationInputCapabilityContextBuilderService ??
           const ConversationInputCapabilityContextBuilderService(),
       _themeSettingsViewDataService =
           themeSettingsViewDataService ?? ThemeSettingsViewDataService(),
       _projectCreationExpressionConstraintDefaultsSettingsService =
           const ProjectCreationExpressionConstraintDefaultsSettingsService(),
       _modelExecutionProfileService =
           modelExecutionProfileService ?? ModelExecutionProfileService(),
       _modeGuidanceTransitionService =
           modeGuidanceTransitionService ?? ModeGuidanceTransitionService(),
       _controllerNotifyTraceService = controllerNotifyTraceService,
       _navigationTraceService = navigationTraceService,
       _projectHydrationTraceService = projectHydrationTraceService,
       _desktopBookDeconstructionSourcePickerService =
           desktopBookDeconstructionSourcePickerService ??
           const DesktopBookDeconstructionSourcePickerService(),
       _viewModel = AppShellViewModel.initial() {
    _listenableState = AppShellListenableState(
      viewModel: _viewModel,
      activeThemeId: _activeThemeId,
    );
    _destinationController = AppShellDestinationController(
      readCurrentDestination: () => _viewModel.destination,
      changeDestination: _changeDestination,
      refreshProjectOpen: _refreshProjectOpenView,
      refreshTaskCenter: _refreshTaskCenter,
      longTaskStationController: _longTaskStationController,
      navigationTraceService: _navigationTraceService,
      projectHydrationTraceService: _projectHydrationTraceService,
      readCurrentProjectPath: () => _currentProject?.rootPath ?? '',
      isProjectHydrationInProgress: () =>
          _workbenchWorkspaceController.isProjectHydrationInProgress,
    );
    _workbenchWorkspaceController = WorkbenchWorkspaceController(
      loadProjectWorkspaceUseCase: _loadProjectWorkspaceUseCase,
      readProjectFileUseCase: _readProjectFileUseCase,
      saveDraftUseCase: _saveDraftUseCase,
      createProjectEntryUseCase: _createProjectEntryUseCase,
      importProjectFilesUseCase: _importProjectFilesUseCase,
      updateProjectManifestUseCase: _updateProjectManifestUseCase,
      executeProjectTypeTransitionUseCase: _executeProjectTypeTransitionUseCase,
      projectToolHostPort: _projectToolHostPort,
      writeProjectTextFileUseCase: _writeProjectTextFileUseCase,
      narrativePersistenceService:
          _bookDeconstructionNarrativePersistenceService,
      generateDraftUseCaseFactory: _generateDraftUseCaseFactory,
      longTaskSupervisor: longTaskSupervisor,
      resumeLongTaskRun: _resumeLongTaskStationRun,
      reviewReportService: _reviewReportService,
      projectRuntimeProfileRepository: projectRuntimeProfileRepository,
      readProjectState: () => _workbenchProjectRuntimeState,
      writeProjectState: (state) {
        _workbenchProjectRuntimeState = state;
      },
      resetConversationRuntimeState: () {
        _workbenchConversationRuntimeState =
            const WorkbenchConversationRuntimeState();
        // 中文注释: 必须同时让会话控制器取消在飞请求并清空它自己的运行时状态——否则
        // 切换项目时旧项目的流式响应仍会通过未被置空的 _activeRequestHandle 把
        // onProgress/结果写进新项目的会话（跨项目串话）。resetRuntimeState 之前无人调用。
        _workbenchConversationController.resetRuntimeState();
      },
      restoreConversationRuntimeState: (project) =>
          _workbenchConversationController.restoreProjectSessions(project),
      readWorkbench: () => _viewModel.workbench,
      mutateWorkbench: _mutateWorkbench,
      applyConversationState: (base) =>
          _workbenchConversationController.applyConversationState(base),
      readSettings: () => _settings,
      saveSettingsSilently: _saveSettingsSilently,
      // 中文注释: 后台快照保存前重读磁盘设置作 base，避免冲掉外部并发编辑。
      reloadSettings: () async => _settingsRepository.load(),
      refreshSettingsViewData: _refreshSettingsViewData,
      refreshAgentEcosystem: _refreshAgentEcosystem,
      refreshActiveDestinationAfterProjectLoad:
          _refreshActiveDestinationAfterProjectLoad,
      modelOptionsBuilder: _modelSelectorOptions,
      readProjectAgentGroupWorkspaceViewData:
          _projectAgentGroupWorkspaceViewData,
      selectProjectAgentGroup: _selectProjectAgentGroupFromWorkspace,
      showSettings: () async => _destinationController.showSettings(),
      showAgentEcosystem: _destinationController.showAgentEcosystem,
      showLongTaskStation: _destinationController.showLongTaskStation,
      showInspirationWorkbench: _destinationController.showInspirationWorkbench,
      showPromptTemplates: _destinationController.showPromptTemplates,
      showProjectAssets: () async {
        if (_usesBookDeconstructionAsPrimaryWorkspace(_currentProject)) {
          await _showBookDeconstructionAnalysis();
          return;
        }
        await _destinationController.showProjectAssets();
      },
      showProjectRagAssets: () async {
        projectAssetsController.openRagExtractionWorkspace();
        await _destinationController.showProjectAssets();
      },
      showCurrentAgentSkillLoadout: _showCurrentAgentSkillLoadout,
      showCurrentAgentExpressionConstraints:
          _showCurrentAgentExpressionConstraints,
      announce: _announce,
      pendingResearchActionService: pendingResearchActionService,
      projectLongTaskDetailLoader: longTaskStationController.loadDetailForRun,
      projectHydrationTraceService: _projectHydrationTraceService,
    );
    _workbenchConversationController = WorkbenchConversationController(
      openingLaunchBridgeService: WorkbenchOpeningLaunchBridgeService(
        buildModeGuidancePlanInputUseCase: _buildModeGuidancePlanInputUseCase,
        workflowRuntimeService: _workflowRuntimeService,
      ),
      openingSessionProjectionService: ProjectOpeningSessionProjectionService(
        loadAgentPackages: _loadAgentPackages,
        loadAgentGroups: _loadAgentGroups,
        loadProjectAgentGroupSelections: (project) =>
            projectAgentGroupBindingRepository.loadSelections(project),
      ),
      conversationOpeningPanelViewDataService:
          const ConversationOpeningPanelViewDataService(),
      projectOpeningAgentGroupBindingService:
          ProjectOpeningAgentGroupBindingService(
            loadSelections: (project) =>
                projectAgentGroupBindingRepository.loadSelections(project),
            saveSelections: (project, selections) =>
                projectAgentGroupBindingRepository.saveSelections(
                  project,
                  selections,
                ),
          ),
      saveDraftUseCase: _saveDraftUseCase,
      generateDraftUseCaseFactory: _generateDraftUseCaseFactory,
      hostAwareGenerateDraftUseCaseFactory:
          _hostAwareGenerateDraftUseCaseFactory,
      modelExecutionProfileService: _modelExecutionProfileService,
      conversationSessionStateService: _conversationSessionStateService,
      projectSessionWorkspaceService: ProjectSessionWorkspaceService(
        hostPort: _projectToolHostPort,
      ),
      conversationStreamingStateService: _conversationStreamingStateService,
      conversationGuideViewDataService: _conversationGuideViewDataService,
      conversationUserVisibleTextService: _conversationUserVisibleTextService,
      workbenchPrimaryActionService: _workbenchPrimaryActionService,
      conversationDraftRuntimeService: _conversationDraftRuntimeService,
      draftExecutionConstraintRuntimeService:
          draftExecutionConstraintRuntimeService,
      userOptionPromptBuilderService: _userOptionPromptBuilderService,
      loadModeGuidanceStateUseCase: _loadModeGuidanceStateUseCase,
      answerModeGuidanceStageUseCase: _answerModeGuidanceStageUseCase,
      modeGuidanceTransitionService: _modeGuidanceTransitionService,
      toolPermissionApprovalRecordService: toolPermissionApprovalRecordService,
      workspaceController: _workbenchWorkspaceController,
      readRuntimeState: () => _workbenchConversationRuntimeState,
      writeRuntimeState: (state) {
        _workbenchConversationRuntimeState = state;
      },
      readWorkbench: () => _viewModel.workbench,
      mutateWorkbench: _mutateWorkbench,
      readSettings: () => _settings,
      persistSettings: _persistSettings,
      saveSettingsSilently: _saveSettingsSilently,
      refreshSettingsViewData: _refreshSettingsViewData,
      readThemeId: () => _activeThemeId,
      notifyShell: _safeNotifyListeners,
      showSettings: () async => _destinationController.showSettings(),
      contextStrategySettingsOf: _contextStrategySettingsOf,
      selectedModelProvider: _selectedModelProvider,
      announce: _announce,
      setForegroundBackHandler: _setForegroundBackHandler,
    );
    _projectLifecycleCoordinator =
        projectLifecycleCoordinator ??
        ProjectLifecycleCoordinator(
          readSettings: () => _settings,
          loadProject:
              (
                rootPath, {
                bool deferHydration = false,
                bool openDefaultDocument = true,
              }) => _workbenchWorkspaceController.loadProject(
                rootPath,
                deferHydration: deferHydration,
                openDefaultDocument: openDefaultDocument,
              ),
          readCurrentProject: () =>
              _workbenchWorkspaceController.currentProject,
          isMobileProjectRootLocked: () => _isMobileProjectRootLocked,
        );
    _projectBoundFeatureRefreshPolicy =
        projectBoundFeatureRefreshPolicy ??
        const ProjectBoundFeatureRefreshPolicy();
    _projectCreationController = ProjectCreationController(
      createProjectWorkspaceUseCase: _createProjectWorkspaceUseCase,
      writeProjectTextFileUseCase: _writeProjectTextFileUseCase,
      desktopProjectDirectoryPickerService:
          _desktopProjectDirectoryPickerService,
      projectLauncherViewDataService: _projectLauncherViewDataService,
      projectLifecycleCoordinator: _projectLifecycleCoordinator,
      readWorkbench: () => _viewModel.workbench,
      mutateWorkbench: _mutateWorkbench,
      readCurrentProject: () => _workbenchWorkspaceController.currentProject,
      onProjectCreatedAndOpened: _handleProjectCreatedAndOpened,
      resetToProjectlessWorkbench:
          _workbenchWorkspaceController.resetToProjectlessWorkbench,
      announce: _announce,
      readSettings: () => _settings,
      projectGeneralContinuitySetupService:
          _projectGeneralContinuitySetupService,
      projectCreationExpressionConstraintDefaultsService:
          ProjectCreationExpressionConstraintDefaultsService(
            workspaceService: _projectExpressionConstraintWorkspaceService,
          ),
      defaultProjectsRootPath: _defaultProjectsRootPath,
      isMobileProjectRootLocked: _isMobileProjectRootLocked,
    );
    _workbenchWorkspaceController.attachProjectCreationController(
      _projectCreationController,
    );
    _projectOpenController = AppShellProjectOpenController(
      startProjectCreationFromProjectOpen: _startProjectCreationFromProjectOpen,
      refreshProjectOpenView: _refreshProjectOpenView,
      selectProjectOpenEntry: _selectProjectOpenEntry,
      openProjectFromProjectOpen: _openProjectFromProjectOpen,
      importLocalProjectFromProjectOpen: _importLocalProjectFromProjectOpen,
      deleteProjectFromProjectOpen: _deleteProjectFromProjectOpen,
    );
    _auxiliaryControllers = AppShellAuxiliaryControllers(
      createProjectAssetsController: () => ProjectAssetsController(
        projectAssetLibraryService: _projectAssetLibraryService,
        expressionConstraintWorkspaceService:
            _projectExpressionConstraintWorkspaceService,
        loaderService: ProjectAssetsLoaderService(
          projectAssetLibraryService: _projectAssetLibraryService,
          timelineRepository: _projectTimelineRepository,
          relationshipRepository: _projectRelationshipRepository,
          expressionConstraintWorkspaceService:
              _projectExpressionConstraintWorkspaceService,
        ),
        readCurrentProject: () => _currentProject,
        readAvailableProjectAgents: () =>
            List<JsonMap>.from(_agentEcosystemSnapshot.agents.map(_mapValue)),
        syncWorkbenchResources: _syncWorkbenchResources,
        onBackRequested: _handleProjectAssetsBackRequested,
        ragExtractionExecutionService: ProjectRagExtractionExecutionService(
          // 中文注释: 入库时按当前设置解析 embedding provider；未配置 embedding 模型或缺凭据时
          // 返回 null，ingestion 如实回退到纯元数据（检索端也会诚实标注词法模式）。
          embeddingProviderResolver: () async {
            final settings = _settings;
            if (settings == null) {
              return null;
            }
            return const SettingsBackedEmbeddingProviderResolver().resolve(
              settings,
            );
          },
        ),
        referenceExtractionExecutionService:
            _injectedProjectReferenceExtractionExecutionService ??
            ProjectReferenceExtractionExecutionService(
              readSettings: () => _settings,
              llmGatewayFactory: _llmGatewayFactory,
              executeReferenceExtraction:
                  ({
                    required project,
                    required llmGateway,
                    required modelId,
                    required request,
                  }) => _referenceExtractionRuntimeService.execute(
                    project: project,
                    llmGateway: llmGateway,
                    modelId: modelId,
                    request: request,
                  ),
              modelExecutionProfileService: _modelExecutionProfileService,
            ),
      ),
      createBookDeconstructionController: () => BookDeconstructionController(
        readProjectFileUseCase: _readProjectFileUseCase,
        writeProjectTextFileUseCase: _writeProjectTextFileUseCase,
        narrativePersistenceService:
            _bookDeconstructionNarrativePersistenceService,
        readCurrentProject: () => _currentProject,
        syncWorkbenchResources: _syncWorkbenchResources,
        onBackRequested: showWorkbench,
        readImportAssistantModelOptions: () =>
            const ImportAssistantModelOptionsService().build(_settings),
        sourcePickerService: _desktopBookDeconstructionSourcePickerService,
        projectsRootPath: _defaultProjectsRootPath,
        readSettings: () => _settings,
        generateDraftUseCaseFactory: _generateDraftUseCaseFactory,
        extractKnowledgeHandler:
            (
              ProjectDescriptor project, {
              required String providerId,
              required String modelId,
            }) async {
              // 中文注释: 提取知识（可选）委托给内置隐藏智能体的 LLM reference_extraction：
              // 读拆书产物（结构化正文）分析知识，必须已配置模型；结果如实回给拆书页。
              // provider/model 由拆书"分析"步的用户选择透传（与 app 默认解耦）。
              final service =
                  _injectedProjectReferenceExtractionExecutionService ??
                  ProjectReferenceExtractionExecutionService(
                    readSettings: () => _settings,
                    llmGatewayFactory: _llmGatewayFactory,
                    executeReferenceExtraction:
                        ({
                          required project,
                          required llmGateway,
                          required modelId,
                          required request,
                        }) => _referenceExtractionRuntimeService.execute(
                          project: project,
                          llmGateway: llmGateway,
                          modelId: modelId,
                          request: request,
                        ),
                    modelExecutionProfileService: _modelExecutionProfileService,
                  );
              final result = await service.pickAndExecute(
                project: project,
                overrideProviderId: providerId,
                overrideModelId: modelId,
                analysisOnly: true,
              );
              return result;
            },
        derivedProjectCreationService:
            BookDeconstructionDerivedProjectCreationService(
              createProjectWorkspaceUseCase: _createProjectWorkspaceUseCase,
              writeProjectTextFileUseCase: _writeProjectTextFileUseCase,
              narrativePersistenceService:
                  _bookDeconstructionNarrativePersistenceService,
              applicationPlanMaterializationService:
                  BookDeconstructionApplicationPlanMaterializationService(
                    writeProjectTextFileUseCase: _writeProjectTextFileUseCase,
                  ),
            ),
        openDerivedProjectRequested:
            (ProjectDescriptor project, String preferredOpenPath) async {
              final result = await _projectLifecycleCoordinator
                  .openProjectFromPath(project.rootPath);
              if (!result.isLoaded) {
                _announce('派生项目已创建，但自动打开失败：${project.rootPath}');
                return;
              }
              showWorkbench();
              if (preferredOpenPath.trim().isNotEmpty) {
                await _workbenchWorkspaceController.openResource(
                  preferredOpenPath,
                );
              }
            },
        projectTypeTransitionUseCase: _executeProjectTypeTransitionUseCase,
        onProjectTransitioned: () async {
          // 中文注释: 项目类型已复合成写作类型（manifest 已更新 projectType + book_deconstruction trait），
          // 重新加载当前项目刷新 descriptor；拆书能力靠 capability 守卫（additionalTraitIds）保留。
          final project = _currentProject;
          if (project == null) return;
          final result = await _projectLifecycleCoordinator.openProjectFromPath(
            project.rootPath,
          );
          if (result.isLoaded) {
            await _syncWorkbenchResources();
            showWorkbench();
          }
        },
      ),
      createInspirationWorkbenchController: () =>
          InspirationWorkbenchController(
            loadModeGuidanceStateUseCase: _loadModeGuidanceStateUseCase,
            answerModeGuidanceStageUseCase: _answerModeGuidanceStageUseCase,
            openingLaunchBridgeService: WorkbenchOpeningLaunchBridgeService(
              buildModeGuidancePlanInputUseCase:
                  _buildModeGuidancePlanInputUseCase,
              workflowRuntimeService: _workflowRuntimeService,
            ),
            readCurrentProject: () => _currentProject,
            readCurrentProjectTitle: () => _viewModel.workbench.projectName,
            syncWorkbenchResources: _syncWorkbenchResources,
            onBackRequested: showWorkbench,
            showTaskCenterRequested: () async => showTaskCenter(),
          ),
    );
    _longTaskStationController.attachNavigationCallbacks(
      openProjectRequested: _openLongTaskStationProject,
      openResourceRequested: _openLongTaskStationRunResource,
      showTaskCenterRequested: () async => showTaskCenter(),
      readCurrentProjectPathRequested: () => _currentProject?.rootPath ?? '',
    );
    // 中文注释: 总站暂停/恢复/停止与任务中心共用 workflow 入口，恢复会真正重入队列，而不是只翻 registry 状态。
    _longTaskStationController.attachQueueControlCallbacks(
      pauseRunRequested: _pauseLongTaskStationRun,
      resumeRunRequested: _resumeLongTaskStationRun,
      stopRunRequested: _stopLongTaskStationRun,
    );
    _longTaskStationController.attachRefreshCompletedCallback(
      _refreshTaskCenterFromLongTaskStation,
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
  final CreateProjectEntryUseCase _createProjectEntryUseCase;
  final ImportProjectFilesUseCase _importProjectFilesUseCase;
  final UpdateProjectManifestUseCase _updateProjectManifestUseCase;
  final ExecuteProjectTypeTransitionUseCase?
  _executeProjectTypeTransitionUseCase;
  final ProjectToolHostPort _projectToolHostPort;
  final ProjectCapabilityService _projectCapabilityService =
      ProjectCapabilityService();
  final BookDeconstructionNarrativePersistenceService
  _bookDeconstructionNarrativePersistenceService;
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
  final LlmGateway Function(
    ProviderEndpointSettings provider,
    JsonMap networkSettings,
  )
  _llmGatewayFactory;
  // 中文注释: 连接探测复用同一套 gateway 装配，不在壳层另起网络实现。
  late final ProviderConnectionProbeService _providerConnectionProbeService =
      ProviderConnectionProbeService(gatewayFactory: _llmGatewayFactory);
  final HostAwareGenerateDraftUseCaseFactory?
  _hostAwareGenerateDraftUseCaseFactory;
  final ProjectWorkflowRuntimeService _workflowRuntimeService;
  final ProjectReferenceExtractionRuntimeService
  _referenceExtractionRuntimeService;
  final ProjectReferenceExtractionExecutionService?
  _injectedProjectReferenceExtractionExecutionService;
  final ProjectConversationDraftRuntimeService _conversationDraftRuntimeService;
  final ProjectReviewReportService _reviewReportService;
  final ProjectChapterRewriteTaskService _projectChapterRewriteTaskService;
  final ProjectPromptTemplateService _promptTemplateService;
  final ProjectAssetLibraryService _projectAssetLibraryService;
  final ProjectTimelineRepository _projectTimelineRepository;
  final ProjectRelationshipRepository _projectRelationshipRepository;
  final ProjectExpressionConstraintWorkspaceService
  _projectExpressionConstraintWorkspaceService;
  final ProjectGeneralContinuitySetupService
  _projectGeneralContinuitySetupService;
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
  final ProjectSkillLoadoutWorkspaceService
  _projectSkillLoadoutWorkspaceService;
  final ProjectSkillLoadoutViewDataService _projectSkillLoadoutViewDataService;
  final CustomizationImportPreviewTextService
  _customizationImportPreviewTextService;
  final ProjectOpenViewDataService _projectOpenViewDataService;
  final ProjectCollectionLoaderService _projectCollectionLoaderService;
  final TaskCenterCommandOrchestrationService
  _taskCenterCommandOrchestrationService;
  final TaskCenterRefreshService _taskCenterRefreshService;
  final TaskCenterWorkflowCreateOptionMapperService
  _taskCenterWorkflowCreateOptionMapperService;
  final ReviewCenterViewDataService _reviewCenterViewDataService;
  final ReviewCenterAnalysisStateService _reviewCenterAnalysisStateService;
  final ReviewCenterPlaybackPreviewService _reviewCenterPlaybackPreviewService;
  final PromptTemplatesViewDataService _promptTemplatesViewDataService;
  final PromptTemplatePreviewService _promptTemplatePreviewService;
  final PromptTemplateNormalizerService _promptTemplateNormalizerService;
  final ModelSettingsViewDataService _modelSettingsViewDataService;
  final ContextSettingsContractService _contextSettingsContractService =
      const ContextSettingsContractService();
  final ProjectCreationExpressionConstraintDefaultsViewDataService
  _projectCreationExpressionConstraintDefaultsViewDataService;
  final ProviderSettingsDirectoryService _providerSettingsDirectoryService;
  final ConversationInputCapabilityContextBuilderService
  _conversationInputCapabilityContextBuilderService;
  final ConversationGroupSelectorViewDataService
  _conversationGroupSelectorViewDataService =
      const ConversationGroupSelectorViewDataService();
  final ProjectAgentGroupWorkspaceViewDataService
  _projectAgentGroupWorkspaceViewDataService =
      const ProjectAgentGroupWorkspaceViewDataService();
  final ThemeSettingsViewDataService _themeSettingsViewDataService;
  final ProjectCreationExpressionConstraintDefaultsSettingsService
  _projectCreationExpressionConstraintDefaultsSettingsService;
  final ModelExecutionProfileService _modelExecutionProfileService;
  late final ProjectLifecycleCoordinator _projectLifecycleCoordinator;
  late final ProjectBoundFeatureRefreshPolicy _projectBoundFeatureRefreshPolicy;
  final ControllerNotifyTraceService? _controllerNotifyTraceService;
  final NavigationTraceService? _navigationTraceService;
  final ProjectHydrationTraceService? _projectHydrationTraceService;
  final app_settings.ProviderConnectionValidationService
  _providerConnectionValidationService =
      app_settings.ProviderConnectionValidationService();
  final ModeGuidanceTransitionService _modeGuidanceTransitionService;
  final DesktopBookDeconstructionSourcePickerService
  _desktopBookDeconstructionSourcePickerService;
  late final AppShellListenableState _listenableState;
  late final AppShellDestinationController _destinationController;
  late final WorkbenchWorkspaceController _workbenchWorkspaceController;
  late final WorkbenchConversationController _workbenchConversationController;
  late final ProjectCreationController _projectCreationController;
  late final AppShellAuxiliaryControllers _auxiliaryControllers;
  late final AppShellProjectOpenController _projectOpenController;
  late final ProjectOpenController _projectOpenLifecycleController;
  final ReviewReportChapterAnalysisProjectionService
  _reviewReportChapterAnalysisProjectionService =
      ReviewReportChapterAnalysisProjectionService();

  AppShellViewModel _viewModel;
  AppSettings? _settings;
  WorkbenchProjectRuntimeState _workbenchProjectRuntimeState =
      const WorkbenchProjectRuntimeState();
  WorkbenchConversationRuntimeState _workbenchConversationRuntimeState =
      const WorkbenchConversationRuntimeState();
  final ThemePreferenceResolver _themePreferenceResolver =
      ThemePreferenceResolver();
  String _activeThemeId = ThemePreferenceResolver.darkThemeId;
  bool _disposed = false;
  bool _initialized = false;
  AgentEcosystemSnapshot _agentEcosystemSnapshot =
      AgentEcosystemSnapshot.initial();
  ProjectSkillLoadoutWorkspaceSnapshot _projectSkillLoadoutWorkspaceSnapshot =
      ProjectSkillLoadoutWorkspaceSnapshot.initial();
  ProjectCollectionSnapshot _projectCollectionSnapshot =
      ProjectCollectionSnapshot.initial();
  String _agentEcosystemStatusMessage = '';
  // 中文注释: 生态页顶层异步(刷新列表/生成索引)进行中标志，用于禁用顶部按钮防连点。
  bool _agentEcosystemBusy = false;
  EcosystemImportCommandViewData? _ecosystemImportCommand;
  EcosystemEditorViewData? _ecosystemEditorViewData;
  final Map<String, ProviderConnectionValidationResultViewData>
  _providerConnectionValidationResults =
      <String, ProviderConnectionValidationResultViewData>{};
  // 中文注释: 设置页瞬态反馈：保存成功/校验失败写这里，经 SettingsViewData 投到 SettingsHeader 显示。
  String _settingsAnnouncement = '';
  // 中文注释: 作品库"进入作品"在飞标志——防止连点触发并发 openProject 写同一份 _currentProject。
  bool _isOpeningProject = false;
  List<JsonMap> _taskCenterTasks = const <JsonMap>[];
  String _selectedTaskId = '';
  String _selectedLongTaskRunPath = '';
  String _selectedTaskQueueRunPath = '';
  String _taskCenterStatusMessage = '';
  bool _taskCenterCommandInFlight = false;
  bool _taskCenterLongTaskPulseInFlight = false;
  int _taskCenterRefreshGeneration = 0;
  List<JsonMap> _reviewCenterEntries = const <JsonMap>[];
  String _selectedReviewEntryId = '';
  String _reviewCenterStatusMessage = '';
  String _reviewTypeFilter = '';
  String _reviewScopeFilter = '';
  String _reviewSourceFilter = '';
  ReviewCenterAnalysisState _reviewCenterAnalysisState =
      ReviewCenterAnalysisState.initial();
  List<JsonMap> _promptTemplates = const <JsonMap>[];
  JsonMap _selectedPromptTemplate = const <String, Object?>{};
  String _selectedPromptTemplateId = '';
  String _promptTemplatesStatusMessage = '';
  String _promptTemplatePreviewText = '';
  AppShellViewModel get viewModel => _viewModel;
  ThemeData get activeThemeData => AppTheme.themeDataFor(_activeThemeId);
  String get activeThemeId => _activeThemeId;
  ValueListenable<AppDestination> get destinationListenable =>
      _listenableState.destinationListenable;
  ValueListenable<String> get activeThemeIdListenable =>
      _listenableState.activeThemeIdListenable;
  ValueListenable<WorkbenchViewData> get workbenchPageListenable =>
      _listenableState.workbenchListenable;
  ValueListenable<WorkbenchResourceViewData> get workbenchResourceListenable =>
      _listenableState.workbenchResourceListenable;
  ValueListenable<WorkbenchCanvasViewData> get workbenchCanvasListenable =>
      _listenableState.workbenchCanvasListenable;
  ValueListenable<WorkbenchConversationViewData>
  get workbenchConversationListenable =>
      _listenableState.workbenchConversationListenable;
  ValueListenable<WorkbenchOverlayViewData> get workbenchOverlayListenable =>
      _listenableState.workbenchOverlayListenable;
  ValueListenable<SettingsViewData> get settingsPageListenable =>
      _listenableState.settingsListenable;
  ValueListenable<AgentEcosystemViewData> get agentEcosystemPageListenable =>
      _listenableState.agentEcosystemListenable;
  ValueListenable<ProjectOpenViewData> get projectOpenPageListenable =>
      _listenableState.projectOpenListenable;
  ValueListenable<ProjectCollectionViewData>
  get projectCollectionPageListenable =>
      _listenableState.projectCollectionListenable;
  ValueListenable<TaskCenterViewData> get taskCenterPageListenable =>
      _listenableState.taskCenterListenable;
  ValueListenable<ReviewCenterViewData> get reviewCenterPageListenable =>
      _listenableState.reviewCenterListenable;
  ValueListenable<PromptTemplatesViewData> get promptTemplatesPageListenable =>
      _listenableState.promptTemplatesListenable;
  TaskCenterCommandEnvironment get _taskCenterCommandEnvironment {
    return TaskCenterCommandEnvironment(
      currentProject: () => _currentProject,
      settings: () => _settings,
      selectedTaskId: () => _selectedTaskId,
      setSelectedTaskId: (value) => _selectedTaskId = value.trim(),
      setTaskCenterCommandInFlight: (value) =>
          _taskCenterCommandInFlight = value,
      setTaskCenterStatusMessage: (value) =>
          _taskCenterStatusMessage = value.trim(),
      selectedTaskSelector: _selectedTaskSelector,
      refreshTaskCenter: ({String? status}) =>
          _refreshTaskCenter(status: status),
      refreshTaskCenterView: _refreshTaskCenterView,
      requestTaskCenterLongTaskPulse: _requestTaskCenterLongTaskPulse,
      syncWorkbenchResources: _syncWorkbenchResources,
      adoptTaskCenterRunSelectionsFromResult:
          _adoptTaskCenterRunSelectionsFromResult,
      refreshLongTaskStationAfterTaskCenterMutation:
          _refreshLongTaskStationAfterTaskCenterMutation,
    );
  }

  LongTaskStationController get longTaskStationController =>
      _longTaskStationController;
  NavigationTraceService? get navigationTraceService => _navigationTraceService;
  bool get isProjectHydrationInProgress =>
      _workbenchWorkspaceController.isProjectHydrationInProgress;
  ProjectAssetsController get projectAssetsController =>
      _auxiliaryControllers.projectAssetsController;
  BookDeconstructionController get bookDeconstructionController =>
      _auxiliaryControllers.bookDeconstructionController;
  InspirationWorkbenchController get inspirationWorkbenchController =>
      _auxiliaryControllers.inspirationWorkbenchController;
  ResourceManagerActionHandler get resourceManagerHandler =>
      _workbenchWorkspaceController;
  DocumentWorkspaceActionHandler get documentWorkspaceHandler =>
      _workbenchWorkspaceController;
  ConversationActionHandler get conversationHandler =>
      _workbenchConversationController;
  ProjectDescriptor? get _currentProject =>
      _workbenchWorkspaceController.currentProject;
  bool get usesProjectAssetsAsPrimaryWorkspace =>
      _usesProjectAssetsAsPrimaryWorkspace(_currentProject);

  List<AppShellNavigationSection> navigationSections() {
    return AppShellNavigationCatalog.sections(
      projectAssetsPrimaryWorkspace: usesProjectAssetsAsPrimaryWorkspace,
      bookDeconstructionPrimaryWorkspace:
          _usesBookDeconstructionAsPrimaryWorkspace(_currentProject),
      hasBookDeconstructionCapability: _hasBookDeconstructionCapability(
        _currentProject,
      ),
    );
  }

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
      _activeThemeId = _themeIdFromSettings(settings);
      _viewModel = _viewModel.copyWith(
        settings: _settingsViewDataFrom(settings),
        workbench: _viewModel.workbench.copyWith(
          modelLabel: _defaultModelLabel(settings),
          modelOptions: _modelSelectorOptions(settings),
          groupSelector: _fallbackGroupSelector(settings),
          inputCapabilityContext: _conversationInputCapabilityContext(settings),
          toolPreviewMode: _toolPreviewModeOf(settings),
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
    if (_usesBookDeconstructionAsPrimaryWorkspace(_currentProject)) {
      unawaited(_showBookDeconstructionAnalysis());
      return;
    }
    if (usesProjectAssetsAsPrimaryWorkspace) {
      showProjectAssets();
      return;
    }
    _destinationController.showWorkbench();
    unawaited(_workbenchWorkspaceController.refreshProjectLongTaskSummary());
  }

  void showBookDeconstructionWorkbench() {
    // 中文注释: 拆书向导导航统一收口，工作台会话和其他页签只通过壳层入口跳转。
    if (!_hasBookDeconstructionCapability(_currentProject)) {
      _showPrimaryWorkspaceForCurrentProject();
      return;
    }
    _destinationController.showBookDeconstructionWorkbench();
  }

  void showSettings() {
    // 中文注释: 该方法统一负责切换到设置页，让设置入口不再分散在多个组件内部。
    _destinationController.showSettings();
  }

  // 中文注释: 前台界面（子智能体全屏）经会话控制器注册的"接管返回键"回调。
  // 非空时系统返回键先交给它（关闭全屏），避免直接弹"退出应用"。
  void Function()? _foregroundBackHandler;

  void _setForegroundBackHandler(void Function()? handler) {
    _foregroundBackHandler = handler;
  }

  Future<bool> handleSystemBackRequested() async {
    // 中文注释: 系统返回键只表达“退一步”，具体退到哪里由壳层状态统一判断。
    final foregroundBackHandler = _foregroundBackHandler;
    if (foregroundBackHandler != null) {
      // 中文注释: 前台界面（子智能体全屏等）已注册接管——先交给它关闭全屏，
      // 而不是直接弹"退出应用"。这一步优先于所有其它覆盖层。
      foregroundBackHandler();
      return false;
    }
    final workbench = _viewModel.workbench;
    if (workbench.workspaceCommand != null) {
      onWorkspaceCommandDismissed();
      return false;
    }
    if (workbench.projectAgentGroupWorkspace != null) {
      _workbenchWorkspaceController.onProjectAgentGroupDismissed();
      return false;
    }
    final launcher = workbench.projectLauncher;
    if (launcher != null) {
      if (launcher.mode == ProjectLauncherMode.create &&
          launcher.creationPhase != ProjectCreationPhase.projectType) {
        await _projectCreationController.onProjectCreationBackRequested();
        return false;
      }
      if (launcher.canDismiss) {
        _projectCreationController.onProjectLauncherDismissed();
        return false;
      }
      return true;
    }
    if (workbench.isDocumentsWorkspaceVisible) {
      onDocumentsWorkspaceDismissRequested();
      return false;
    }
    switch (_viewModel.destination) {
      case AppDestination.workbench:
        return true;
      case AppDestination.projectOpen:
        if (_currentProject != null) {
          _showPrimaryWorkspaceForCurrentProject();
          return false;
        }
        // 中文注释: 没有当前项目时，作品库页的返回键应回到工作台(露出项目启动器)，
        // 而不是弹"退出应用"——与其他 destination 的返回行为一致。
        showWorkbench();
        return false;
      case AppDestination.settings:
      case AppDestination.agentEcosystem:
      case AppDestination.longTaskStation:
      case AppDestination.taskCenter:
        _showPrimaryWorkspaceForCurrentProject();
        return false;
      case AppDestination.bookDeconstruction:
        if (_usesBookDeconstructionAsPrimaryWorkspace(_currentProject)) {
          return true;
        }
        if (_hasBookDeconstructionCapability(_currentProject)) {
          showWorkbench();
          return false;
        }
        _showPrimaryWorkspaceForCurrentProject();
        return false;
      case AppDestination.projectAssets:
        if (usesProjectAssetsAsPrimaryWorkspace) {
          return true;
        }
        showWorkbench();
        return false;
    }
  }

  void showAgentEcosystem() {
    // 中文注释: 该方法统一负责切换到智能体生态页，避免资源面板和会话面板各自维护路由。
    _destinationController.showAgentEcosystem();
  }

  void showTaskCenter() {
    // 中文注释: 历史任务中心入口统一折返到长任务总站，避免用户在多个运行空间之间来回找。
    _destinationController.showTaskCenter();
  }

  void showLongTaskStation() {
    // 中文注释: 全局长任务总站只在壳层完成路由切换，真正的运行列表与动作逻辑交给独立子域控制器。
    _destinationController.showLongTaskStation();
  }

  void showInspirationWorkbench() {
    // 中文注释: 灵感工作台导航统一收口，其他子域只通过壳层入口跳转过去。
    _destinationController.showInspirationWorkbench();
  }

  void showReviewCenter() {
    // 中文注释: 历史审稿中心入口统一折返到长任务总站，审稿结果查看回到工作台文件区。
    _destinationController.showReviewCenter();
  }

  void showPromptTemplates() {
    // 中文注释: 模板页导航与数据刷新统一收口，避免后续从设置页或任务页进入时出现两套状态来源。
    _destinationController.showPromptTemplates();
  }

  void showProjectCollection() {
    // 中文注释: 历史项目库入口现已收束到“打开项目”，避免继续暴露两个项目入口概念。
    _destinationController.showProjectCollection();
  }

  void showProjectAssets() {
    // 中文注释: 项目资产页统一负责风格、伏笔与资产包入口，不把资产逻辑散回工作台。
    _destinationController.showProjectAssets();
  }

  Future<void> _handleProjectCreatedAndOpened(ProjectDescriptor project) async {
    if (_usesBookDeconstructionAsPrimaryWorkspace(project)) {
      await bookDeconstructionController.refresh();
      await _destinationController.showBookDeconstructionWorkbench();
      return;
    }
    if (_shouldOpenProjectAssetsByDefault(project)) {
      await projectAssetsController.refresh();
      showProjectAssets();
      return;
    }
    showWorkbench();
  }

  Future<void> _refreshProjectOpenView({
    String status = '',
    bool forceRefresh = false,
  }) async {
    final settings = _settings;
    final snapshot = await _projectOpenLifecycleController.refreshSnapshot(
      projectsRootPath: _defaultProjectsRootPath,
      recentProjectPath: settings?.defaultProjectPath ?? '',
      currentProjectPath: _currentProject?.rootPath ?? '',
      allowImportLocal: !_isMobileProjectRootLocked,
      selectedEntryId: _viewModel.projectOpen.selectedEntryId,
      status: status,
      forceRefresh: forceRefresh || status.trim().isNotEmpty,
    );
    final viewData = _projectOpenViewDataService.build(snapshot);
    _viewModel = _viewModel.copyWith(projectOpen: viewData);
    _safeNotifyListeners();
    _navigationTraceService?.markPageRefreshCompleted(
      AppDestination.projectOpen,
      label: 'project_open_refresh',
    );
  }

  void _selectProjectOpenEntry(String entryId) {
    // 中文注释: 条目选中只更新项目入口页的局部视图态，不触发项目加载。
    _projectOpenLifecycleController.selectEntry(entryId);
    _viewModel = _viewModel.copyWith(
      projectOpen: _projectOpenViewDataService.selectEntry(
        _viewModel.projectOpen,
        entryId,
      ),
    );
    _safeNotifyListeners();
  }

  Future<void> _openProjectFromProjectOpen(String projectPath) async {
    final normalizedPath = projectPath.trim();
    if (normalizedPath.isEmpty) {
      await _refreshProjectOpenView(status: '未识别到有效项目目录。');
      return;
    }
    // 中文注释: 防重入——连点"进入作品"会并发 open，竞写 _currentProject/设置。
    if (_isOpeningProject) {
      return;
    }
    _isOpeningProject = true;
    try {
      // 中文注释: 打开进度走 projectOpen 视图状态(作品库页可见)，不用 _announce(它只写工作台状态条，作品库页看不到)。
      await _refreshProjectOpenView(status: '正在打开项目...');
      final result = await _projectLifecycleCoordinator.openProjectFromPath(
        normalizedPath,
        failureLauncherMode: _currentProject == null
            ? ProjectLauncherMode.guard
            : null,
        failureLauncherStatus: '打开项目失败：$normalizedPath',
      );
      if (!result.isLoaded) {
        // 中文注释: 把协调器产出的具体失败原因(如"项目清单损坏...")带给用户，而不是写死一句 path；
        // 协调器要求弹启动器时(无当前项目)就弹，并带上同样的原因与 canDismiss。
        final reason = result.statusMessage.trim().isNotEmpty
            ? result.statusMessage
            : '打开项目失败：$normalizedPath';
        await _refreshProjectOpenView(status: reason);
        if (result.shouldShowLauncher) {
          await _projectCreationController.showLauncher(
            result.launcherMode ?? ProjectLauncherMode.guard,
            status: result.launcherStatus,
            canDismiss: result.canDismiss,
          );
        }
        return;
      }
      await _refreshProjectOpenView(status: '');
      if (_shouldOpenProjectAssetsByDefault(_currentProject)) {
        await projectAssetsController.refresh();
        showProjectAssets();
        return;
      }
      if (_usesBookDeconstructionAsPrimaryWorkspace(_currentProject)) {
        await bookDeconstructionController.refresh();
        await _destinationController.showBookDeconstructionWorkbench();
        return;
      }
      showWorkbench();
    } finally {
      _isOpeningProject = false;
    }
  }

  Future<void> _importLocalProjectFromProjectOpen() async {
    if (_isMobileProjectRootLocked) {
      await _refreshProjectOpenView(status: '移动端暂不支持导入本地项目。');
      return;
    }
    final selectedPath = await _desktopProjectDirectoryPickerService
        .pickProjectDirectory();
    if (selectedPath == null || selectedPath.trim().isEmpty) {
      // 中文注释: 用户取消选择时不打扰；只有真正失败才在下面 try/catch 里给状态。
      return;
    }
    try {
      final snapshot = await _loadProjectWorkspaceUseCase.execute(selectedPath);
      if (snapshot == null) {
        await _refreshProjectOpenView(status: '所选目录不是有效项目根目录。');
        return;
      }
      await _openProjectFromProjectOpen(snapshot.project.rootPath);
    } catch (error) {
      // 中文注释: 导入/打开期间抛错要如实落到作品库状态，而不是被静默吞掉、用户看到"什么都没发生"。
      await _refreshProjectOpenView(status: '导入项目失败：$error');
    }
  }

  Future<void> _deleteProjectFromProjectOpen(String projectPath) async {
    // 中文注释: 作品库删除只允许清理作品根目录下的子项目，避免误删盘外路径；确认弹窗在页面层完成。
    final normalizedPath = projectPath.trim();
    if (normalizedPath.isEmpty) {
      await _refreshProjectOpenView(status: '未识别到有效项目目录。');
      return;
    }
    final projectsRoot = Directory(_defaultProjectsRootPath).absolute.path;
    final target = Directory(normalizedPath).absolute;
    final targetPath = target.path;
    final rootWithSep = projectsRoot.endsWith(Platform.pathSeparator)
        ? projectsRoot
        : '$projectsRoot${Platform.pathSeparator}';
    final isUnderRoot =
        targetPath == projectsRoot || targetPath.startsWith(rootWithSep);
    if (!isUnderRoot) {
      await _refreshProjectOpenView(
        status: '只能删除作品库根目录下的项目，请到文件管理器处理外部路径。',
      );
      return;
    }
    if (targetPath == projectsRoot) {
      await _refreshProjectOpenView(status: '不能删除作品库根目录本身。');
      return;
    }
    try {
      // 中文注释: 先真正删除目录，成功后再清工作台/锁启动器——否则删除失败时会把用户
      // 困在 guard launcher 里，而项目其实没被删掉。
      final isCurrentProject = _currentProject != null &&
          Directory(_currentProject!.rootPath.trim()).absolute.path ==
              targetPath;
      if (await target.exists()) {
        await target.delete(recursive: true);
      }
      if (isCurrentProject) {
        _workbenchWorkspaceController.resetToProjectlessWorkbench(
          status: '当前作品已删除，请重新选择或新建。',
        );
        // 中文注释: 删的是当前项目时，把启动器锁在工作台上(canDismiss:false)，
        // 这样用户回到工作台不会看到死寂空台，而是被引导重新选择或新建。
        await _projectCreationController.showLauncher(
          ProjectLauncherMode.guard,
          status: '当前作品已删除，请重新选择或新建。',
          canDismiss: false,
        );
      }
      final settings = _settings;
      if (settings != null) {
        final recent = settings.defaultProjectPath.trim();
        if (recent.isNotEmpty &&
            Directory(recent).absolute.path == targetPath) {
          final updated = settings.copyWith(defaultProjectPath: '');
          await _settingsRepository.save(updated);
          _settings = updated;
        }
      }
      _projectOpenLifecycleController.clearCache();
      await _refreshProjectOpenView(
        forceRefresh: true,
        status: '已删除作品：${targetPath.split(Platform.pathSeparator).last}',
      );
    } catch (error) {
      await _refreshProjectOpenView(
        status: UserFacingErrorHumanizer.humanize(error, action: '删除作品'),
      );
    }
  }

  Future<void> _startProjectCreationFromProjectOpen() async {
    // 中文注释: 项目入口页进入新建流程时统一切回工作台并拉起正式创建向导，避免落回旧命令面板。
    // 注意：必须用 _destinationController.showWorkbench() 而不是公开的 showWorkbench()——
    // 后者在当前项目是 knowledge_base 时会重定向到 projectAssets 并 return，
    // 导致 onCreateProjectRequested 设置的创建向导落在工作台视图上、用户却停在资料库页
    // （表现为“在资料库项目页点新建项目，一下就跳回去了”）。
    _destinationController.showWorkbench();
    await _projectCreationController.onCreateProjectRequested();
  }

  Future<void> _showCurrentAgentSkillLoadout(String agentId) async {
    // 中文注释: 工作台当前智能体跳转到技能装载时，预选逻辑统一收口在壳层，不让资源面板自己碰生态快照。
    final cleanAgentId = agentId.trim();
    if (cleanAgentId.isEmpty) {
      return;
    }
    await _refreshAgentEcosystem(
      selectedTabId: 'skill-loadouts',
      selectedEntryId: cleanAgentId,
    );
    await _destinationController.showAgentEcosystem();
  }

  Future<void> _showCurrentAgentExpressionConstraints(String agentId) async {
    // 中文注释: 表达限制仍是项目级子域，但从当前智能体入口进入时会记住一个轻量上下文。
    final cleanAgentId = agentId.trim();
    if (cleanAgentId.isEmpty) {
      return;
    }
    await projectAssetsController.refresh();
    projectAssetsController.openExpressionConstraintsForAgent(cleanAgentId);
    await _destinationController.showProjectAssets();
  }

  Future<void> _showBookDeconstructionAnalysis() async {
    await bookDeconstructionController.refresh(status: '可以开始分析书籍，提取结构化拆书资产。');
    await _destinationController.showBookDeconstructionWorkbench();
  }

  @override
  Future<void> onAppShellDestinationRequested(
    AppDestination destination,
  ) async {
    if (destination == AppDestination.bookDeconstruction) {
      if (!_hasBookDeconstructionCapability(_currentProject)) {
        _showPrimaryWorkspaceForCurrentProject();
        return;
      }
      await _showBookDeconstructionAnalysis();
      return;
    }
    if (destination == AppDestination.workbench) {
      showWorkbench();
      return;
    }
    await _destinationController.showDestination(destination);
  }

  Future<void> _openLongTaskStationProject(RunInstance run) async {
    // 中文注释: 总站跳回工作台时，先保证对应项目已载入，再切回工作台主视图。
    final loaded = await _ensureLongTaskStationProjectLoaded(run);
    if (!loaded) {
      return;
    }
    showWorkbench();
  }

  Future<JsonMap> _pauseLongTaskStationRun(RunInstance run) {
    return _controlLongTaskStationRun(
      run,
      actionLabel: '暂停',
      operation: (project, settings, relativePath) {
        return _workflowRuntimeService.pauseLongTaskRun(
          project,
          relativePath,
          note: 'paused_from_long_task_station',
        );
      },
      requireSettings: false,
    );
  }

  Future<JsonMap> _resumeLongTaskStationRun(RunInstance run) {
    return _controlLongTaskStationRun(
      run,
      actionLabel: '恢复',
      operation: (project, settings, relativePath) {
        if (settings == null) {
          return Future<JsonMap>.value(<String, Object?>{
            'ok': false,
            'error': '设置尚未加载完成，无法恢复长任务。',
          });
        }
        return _workflowRuntimeService.resumeLongTaskRun(
          project,
          settings,
          relativePath,
          options: const <String, Object?>{
            'entry_reason': 'long_task_station_resume',
          },
        );
      },
      requireSettings: true,
    );
  }

  Future<JsonMap> _stopLongTaskStationRun(RunInstance run) {
    return _controlLongTaskStationRun(
      run,
      actionLabel: '停止',
      operation: (project, settings, relativePath) {
        return _workflowRuntimeService.stopLongTaskRun(
          project,
          relativePath,
          note: 'stopped_from_long_task_station',
        );
      },
      requireSettings: false,
    );
  }

  Future<JsonMap> _controlLongTaskStationRun(
    RunInstance run, {
    required String actionLabel,
    required Future<JsonMap> Function(
      ProjectDescriptor project,
      AppSettings? settings,
      String relativePath,
    )
    operation,
    required bool requireSettings,
  }) async {
    // 中文注释: 必须用 run.project 还原目标项目，不能误用当前工作台项目，否则会恢复错书。
    final project = ProjectDescriptor(
      id: run.project.projectId,
      name: run.project.title,
      rootPath: run.project.rootPath,
      projectType: run.project.projectTypeId,
      storageStrategy: run.project.storageStrategy,
      runtimeBaselineId: run.runtimeBaselineId,
    );
    final relativePath = ValueReaders.stringValue(
      run.metadata['record_relative_path'],
    ).trim();
    if (relativePath.isEmpty) {
      // 中文注释: 记录定位失败时给出可操作的指引（运行号 + 去哪找），而不是一句被踢走的提示。
      final runShortId =
          run.id.length > 8 ? run.id.substring(0, 8) : run.id;
      return <String, Object?>{
        'ok': false,
        'error': '无法定位该运行的任务记录（运行 $runShortId）。请到「任务中心 → 链路与运行记录」'
            '找到该运行后再$actionLabel；若列表里也没有，请重新启动长任务。',
      };
    }
    final settings = _settings;
    if (requireSettings && settings == null) {
      return <String, Object?>{
        'ok': false,
        'error': '设置尚未加载完成，无法$actionLabel长任务。',
      };
    }
    try {
      return await operation(project, settings, relativePath);
    } catch (error) {
      return <String, Object?>{
        'ok': false,
        'error': UserFacingErrorHumanizer.humanize(
          error,
          action: '长任务$actionLabel',
        ),
      };
    }
  }

  bool _shouldOpenProjectAssetsByDefault(ProjectDescriptor? project) {
    return _usesProjectAssetsAsPrimaryWorkspace(project);
  }

  bool _usesProjectAssetsAsPrimaryWorkspace(ProjectDescriptor? project) {
    if (project == null) {
      return false;
    }
    if (project.projectType.trim() != 'knowledge_base') {
      return false;
    }
    return const KnowledgeBaseBranchCatalogService()
        .definitionOf(project.projectBranchId)
        .opensProjectAssetsByDefault;
  }

  bool _hasBookDeconstructionCapability(ProjectDescriptor? project) {
    if (project == null) {
      return false;
    }
    return _projectCapabilityService.hasBookDeconstruction(
      projectTypeId: project.projectType,
      additionalTraitIds: project.additionalTraitIds,
      runtimeBaselineId: project.runtimeBaselineId,
    );
  }

  /// A composite writing project retains the deconstruction capability, but
  /// its writing workbench remains its primary workspace.
  bool _usesBookDeconstructionAsPrimaryWorkspace(ProjectDescriptor? project) {
    return const BookDeconstructionWorkspacePolicy()
        .usesDeconstructionAsPrimaryWorkspace(project);
  }

  void _showPrimaryWorkspaceForCurrentProject() {
    if (_usesBookDeconstructionAsPrimaryWorkspace(_currentProject)) {
      unawaited(_showBookDeconstructionAnalysis());
      return;
    }
    if (usesProjectAssetsAsPrimaryWorkspace) {
      showProjectAssets();
      return;
    }
    _destinationController.showWorkbench();
    unawaited(_workbenchWorkspaceController.refreshProjectLongTaskSummary());
  }

  void _handleProjectAssetsBackRequested() {
    if (usesProjectAssetsAsPrimaryWorkspace) {
      unawaited(_destinationController.showProjectOpen());
      return;
    }
    showWorkbench();
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
  void onProviderCreateRequested() {
    _refreshSettingsViewData(selectedProviderId: '__new__');
    _safeNotifyListeners();
  }

  @override
  void onProviderDetailBackRequested() {
    _refreshSettingsViewData(selectedProviderId: '');
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
    final nextTitle = _stringValue(payload['title']);
    if (nextTitle.trim().isEmpty) {
      _announceSettings('请先填写接口/厂商名称再保存。');
      return;
    }
    final nextBaseUrl = _stringValue(payload['base_url']);
    if (nextBaseUrl.trim().isEmpty) {
      _announceSettings('请填写 Base URL 后再保存。');
      return;
    }
    final nextId = sourceId.trim().isNotEmpty
        ? sourceId
        : _nextProviderId(settings.providers, nextTitle);
    // 中文注释: 保留既有 provider 的 isDefault（编辑保存不应把"默认接口"标记悄悄清成 false，
    // 否则 defaultProviderId 解析失败时退路被切断）；新接口默认 false，UI 将来传 is_default 也照收。
    final existingIsDefault =
        sourceId.trim().isNotEmpty &&
        settings.providers.any((p) => p.id == sourceId && p.isDefault);
    final nextProvider = ProviderEndpointSettings(
      id: nextId,
      title: nextTitle,
      protocol: _stringValue(payload['protocol'], 'openai_compatible'),
      baseUrl: nextBaseUrl,
      apiKey: _stringValue(payload['api_key']),
      modelId: '',
      description: _stringValue(payload['description']),
      isDefault: existingIsDefault || _boolValue(payload['is_default']),
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
    // 中文注释: 首个接口自动成为默认，省掉用户再去「模型」页才能用的空窗。
    final shouldBecomeDefault =
        settings.defaultProviderId.trim().isEmpty ||
        settings.defaultProviderId == sourceId ||
        settings.providers.isEmpty;
    final updated = settings.copyWith(
      providers: providers,
      defaultProviderId: shouldBecomeDefault
          ? nextProvider.id
          : settings.defaultProviderId,
      extraSettings: <String, Object?>{
        ...settings.extraSettings,
        'model_settings': <String, Object?>{
          ...modelSettings,
          if (selectedProviderId == sourceId || shouldBecomeDefault)
            'provider_id': nextProvider.id,
        },
      },
    );
    // 中文注释: 草稿探测结果从 __new__ 迁到真实 id，避免保存后状态丢失。
    final draftProbe = _providerConnectionValidationResults.remove('__new__');
    if (draftProbe != null) {
      _providerConnectionValidationResults[nextProvider.id] = draftProbe;
    }
    // 中文注释: API Key 空时不硬拦(本地/自建服务可能无需鉴权)，但在成功提示里追加提醒，
    // 避免用户以为已配好、直到首次发送才撞"鉴权失败"。
    final apiKeyEmpty = _stringValue(payload['api_key']).trim().isEmpty;
    final baseSuccess = shouldBecomeDefault
        ? '接口已保存，并设为当前默认接口。请到「模型」页选择默认模型。'
        : '接口设置已保存。';
    final successMessage = apiKeyEmpty
        ? '$baseSuccess（注意：API Key 未填写，发送前需补上；本地/自建服务若无需鉴权可忽略。）'
        : baseSuccess;
    _persistSettings(
      updated,
      successMessage: successMessage,
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
    final modelProviderId = _stringValue(
      modelSettings['provider_id'],
      settings.defaultProviderId,
    );
    // 中文注释: 被删的接口若正是模型绑定的接口，模型的 provider 与 defaultModelId 都要清空，
    // 否则 _modelSelectorOptions 仍会列出孤立的 defaultModelId，让"未配置模型"banner 不显示、用户盲发。
    final modelProviderGone = modelProviderId == providerId;
    final nextModelProviderId = modelProviderGone ? '' : modelProviderId;
    final nextDefaultModelId =
        modelProviderGone ? '' : settings.defaultModelId;
    final updated = settings.copyWith(
      providers: providers,
      defaultProviderId: settings.defaultProviderId == providerId
          ? ''
          : settings.defaultProviderId,
      defaultModelId: nextDefaultModelId,
      extraSettings: <String, Object?>{
        ...settings.extraSettings,
        'model_settings': <String, Object?>{
          ...modelSettings,
          'provider_id': nextModelProviderId,
          if (modelProviderGone) 'model_id': '',
        },
      },
    );
    _persistSettings(updated, successMessage: '接口已删除。');
  }

  @override
  Future<ProviderConnectionValidationResultViewData>
  onModelConnectionTestRequested(Map<String, Object?> payload) async {
    // 中文注释: 模型页用"当前选中接口 + 模型"真实配对发起探测；先本地自检挡明显错误，
    // 再做一次真联网探测，合并后直接回传给模型页展示。不再写接口缓存、不再刷新整页设置视图，
    // 以免把用户正在编辑的接口/模型表单重置。
    final settings = _settings;
    if (settings == null) {
      return ProviderConnectionValidationResultViewData.initial;
    }
    final title = _stringValue(payload['title']);
    final protocol = _stringValue(payload['protocol'], 'openai_compatible');
    final baseUrl = _stringValue(payload['base_url']);
    final apiKey = _stringValue(payload['api_key']);
    final modelId = _stringValue(payload['model_id']);
    final apiMode = _stringValue(payload['api_mode'], 'chat');
    final validation = _providerConnectionValidationService.validate(
      title: title,
      protocol: protocol,
      baseUrl: baseUrl,
      apiKey: apiKey,
      modelId: modelId,
      apiMode: apiMode,
    );
    final lintView = _toValidationViewData(validation);
    if (!validation.isSuccess) {
      return lintView;
    }
    final provider = ProviderEndpointSettings(
      id: _stringValue(payload['source_id']),
      title: title,
      protocol: protocol,
      baseUrl: baseUrl,
      apiKey: apiKey,
      modelId: modelId,
      description: '',
    );
    final probe = await _providerConnectionProbeService.probe(
      provider: provider,
      modelId: modelId,
      // 中文注释: 把用户已保存的网络设置(含自定义代理)带给探测——此前传空 map 导致探测
      // 走直连，与真实生成路径不一致，代理用户会得到与实战相反的通过/失败结果。
      networkSettings: settings.networkSettings,
    );
    return _validationViewDataWith(
      base: lintView,
      isSuccess: probe.success,
      summary: probe.summary,
      details: <String>[...lintView.details, probe.detail],
    );
  }

  ProviderConnectionValidationResultViewData _validationViewDataWith({
    required ProviderConnectionValidationResultViewData base,
    required bool isSuccess,
    required String summary,
    required List<String> details,
  }) {
    // 中文注释: 复用本地自检结果的模板/路由等元信息，只覆盖成功状态与文案，避免重复拼字段。
    return ProviderConnectionValidationResultViewData(
      isSuccess: isSuccess,
      summary: summary,
      details: details,
      errors: base.errors,
      templateId: base.templateId,
      providerId: base.providerId,
      protocolId: base.protocolId,
      protocolMode: base.protocolMode,
      routeFamily: base.routeFamily,
      selectedRouteFamily: base.selectedRouteFamily,
      allowedRouteFamilies: base.allowedRouteFamilies,
      hideOptions: base.hideOptions,
      fallbackNotAllowed: base.fallbackNotAllowed,
      warnings: base.warnings,
      matchedTemplateId: base.matchedTemplateId,
      matchedTemplateLabel: base.matchedTemplateLabel,
    );
  }

  @override
  void onModelSettingsSaved(Map<String, Object?> payload) {
    // 中文注释: 模型设置单独落成一段运行参数，接口创建与模型运行不会再互相挤进同一份表单。
    final settings = _settings;
    if (settings == null) {
      return;
    }
    final nextProviderId = _stringValue(
      payload['default_provider_id'],
      settings.defaultProviderId,
    );
    final nextModelId = _stringValue(
      payload['default_model_id'],
      _stringValue(payload['model_id'], settings.defaultModelId),
    );
    if (settings.providers.isEmpty) {
      _announceSettings('请先到「接口」页添加并保存接口，再配置默认模型。');
      return;
    }
    if (nextProviderId.trim().isEmpty) {
      _announceSettings('请选择默认接口后再保存模型设置。');
      return;
    }
    if (nextModelId.trim().isEmpty) {
      _announceSettings('请填写或选择默认模型后再保存。');
      return;
    }
    final modelSettings = <String, Object?>{
      ..._modelSettingsOf(settings),
      'provider_id': nextProviderId,
      'model_id': nextModelId,
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
      'custom_reasoning_override': ValueReaders.deepCopyMap(
        ValueReaders.mapValue(payload['custom_reasoning_override']),
      ),
      'custom_parameters': ValueReaders.deepCopyList(
        ValueReaders.objectList(payload['custom_parameters']),
      ),
    };
    final updated = settings.copyWith(
      defaultProviderId: nextProviderId,
      defaultModelId: nextModelId,
      extraSettings: <String, Object?>{
        ...settings.extraSettings,
        'model_settings': modelSettings,
        // 中文注释: RAG 向量化模型 ID——SettingsBackedEmbeddingProviderResolver 读这个键。
        // 留空则检索走关键词匹配（已诚实标注）；填写则用默认接口的该模型做 embedding。
        'embedding_model_id': _stringValue(payload['embedding_model_id']),
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
    final nextToolStrategySettings = Map<String, Object?>.from(payload)
      ..remove('tool_preview_mode');
    final nextToolPreviewMode = ToolPreviewMode.normalize(
      payload['tool_preview_mode'],
    );
    _persistSettings(
      settings.copyWith(
        toolStrategySettings: nextToolStrategySettings,
        extraSettings: <String, Object?>{
          ...settings.extraSettings,
          'workbench_ui': <String, Object?>{
            ..._workbenchUiSettingsOf(settings),
            'tool_preview_mode': nextToolPreviewMode,
          },
        },
      ),
      successMessage: '工具策略已保存。',
    );
  }

  @override
  void onProjectCreationExpressionConstraintDefaultsSaved(
    Map<String, Object?> payload,
  ) {
    final settings = _settings;
    if (settings == null) {
      return;
    }
    final modeName = _stringValue(
      payload['mode'],
      ProjectCreationExpressionConstraintDefaultsMode.builtinFallback.name,
    );
    final mode = ProjectCreationExpressionConstraintDefaultsMode.values
        .firstWhere(
          (entry) => entry.name == modeName,
          orElse: () =>
              ProjectCreationExpressionConstraintDefaultsMode.builtinFallback,
        );
    final selection = ProjectCreationExpressionConstraintDefaultsSelection(
      mode: mode,
      profileIds: ValueReaders.stringList(payload['profile_ids']),
    );
    _persistSettings(
      settings.copyWith(
        extraSettings:
            _projectCreationExpressionConstraintDefaultsSettingsService
                .mergedExtraSettingsForSelection(
                  settings: settings,
                  selection: selection,
                ),
      ),
      successMessage: '项目创建默认表达限制已保存。',
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
    final draftFallbackProtectionEnabled = ValueReaders.boolValue(
      payload[AppSettings.draftFallbackProtectionConfigKey],
      settings.draftFallbackProtectionEnabled,
    );
    final contextSettings = _contextSettingsContractService.normalizeForStorage(
      Map<String, Object?>.from(payload)
        ..remove('default_project_path')
        ..remove(AppSettings.draftFallbackProtectionConfigKey),
    );
    _persistSettings(
      settings.copyWith(
        defaultProjectPath: nextProjectPath,
        draftFallbackProtectionEnabled: draftFallbackProtectionEnabled,
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
    final nextThemeId = _stringValue(
      payload[ThemePreferenceResolver.selectedThemeIdKey],
      _activeThemeId,
    );
    final updated = settings.copyWith(
      themeSettings: _themePreferenceResolver.payloadForSelectedTheme(
        selectedThemeId: nextThemeId,
        base: settings.themeSettings,
      ),
    );
    _persistSettings(updated, successMessage: '主题设置已保存。');
  }

  Future<void> _openLongTaskStationRunResource(
    RunInstance run,
    String relativePath,
  ) async {
    // 中文注释: 总站里的任务节点、检查点、审稿结果统一回到工作台文件查看，不再切去独立中心页。
    final loaded = await _ensureLongTaskStationProjectLoaded(run);
    if (!loaded) {
      return;
    }
    final cleanRelativePath = relativePath.trim();
    if (cleanRelativePath.isNotEmpty) {
      await _workbenchWorkspaceController.openResource(cleanRelativePath);
    }
    _showPrimaryWorkspaceForCurrentProject();
  }

  Future<bool> _ensureLongTaskStationProjectLoaded(RunInstance run) async {
    // 中文注释: 总站联动始终以运行实例引用的项目为准，不假设当前工作台还停留在同一个项目。
    final currentProject = _currentProject;
    if (currentProject != null &&
        _normalizePathForCompare(currentProject.rootPath) ==
            _normalizePathForCompare(run.project.rootPath)) {
      return true;
    }
    final result = await _projectLifecycleCoordinator.openProjectFromPath(
      run.project.rootPath,
    );
    if (!result.isLoaded) {
      _announce('无法打开长任务对应项目：${run.project.rootPath}');
      return false;
    }
    return true;
  }

  void onModelSettingsRequested() =>
      _workbenchWorkspaceController.onModelSettingsRequested();

  void onCreateProjectRequested() =>
      _projectCreationController.onCreateProjectRequested();

  void onOpenProjectRequested() =>
      _projectCreationController.onOpenProjectRequested();

  void onProjectLauncherDismissed() =>
      _projectCreationController.onProjectLauncherDismissed();

  void onProjectLauncherRefreshRequested() =>
      _projectCreationController.onProjectLauncherRefreshRequested();

  void onProjectEntryOpened(String projectPath) =>
      _projectCreationController.onProjectEntryOpened(projectPath);

  @override
  void onProjectOpenRefreshRequested() =>
      _projectOpenController.onProjectOpenRefreshRequested();

  @override
  void onProjectOpenCreateRequested() =>
      _projectOpenController.onProjectOpenCreateRequested();

  @override
  void onProjectOpenImportRequested() =>
      _projectOpenController.onProjectOpenImportRequested();

  @override
  void onProjectOpenEntrySelected(String entryId) =>
      _projectOpenController.onProjectOpenEntrySelected(entryId);

  @override
  void onProjectOpenOpenRequested(String projectPath) =>
      _projectOpenController.onProjectOpenOpenRequested(projectPath);

  @override
  void onProjectOpenDeleteRequested(String projectPath) =>
      _projectOpenController.onProjectOpenDeleteRequested(projectPath);

  Future<void> openResource(String relativePath) async {
    // 中文注释: 壳层需要一个可等待的资源打开入口时，只能透出工作区现有能力，不在这里重写读盘逻辑。
    await _openResource(relativePath);
  }

  void onProjectCreationBackRequested() =>
      _projectCreationController.onProjectCreationBackRequested();

  void onProjectCreationSubmitted(ProjectCreateRequestViewData request) =>
      _projectCreationController.onProjectCreationSubmitted(request);

  void onEditProjectInfoRequested() =>
      _workbenchWorkspaceController.onEditProjectInfoRequested();

  void onProjectTypeTransitionRequested() =>
      _workbenchWorkspaceController.onProjectTypeTransitionRequested();

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

  void onCurrentAgentSkillLoadoutRequested() =>
      _workbenchWorkspaceController.onCurrentAgentSkillLoadoutRequested();

  void onTasksRequested() => _workbenchWorkspaceController.onTasksRequested();

  void onLongTaskStationRequested() =>
      _workbenchWorkspaceController.onLongTaskStationRequested();

  void onReviewsRequested() =>
      _workbenchWorkspaceController.onReviewsRequested();

  void onTemplatesRequested() =>
      _workbenchWorkspaceController.onTemplatesRequested();

  void onProjectAssetsRequested() =>
      _workbenchWorkspaceController.onProjectAssetsRequested();

  void onProjectRagRequested() {
    projectAssetsController.openRagExtractionWorkspace();
    showProjectAssets();
  }

  void onCurrentAgentExpressionConstraintsRequested() =>
      _workbenchWorkspaceController
          .onCurrentAgentExpressionConstraintsRequested();

  @override
  void onProjectExpressionConstraintsRequested() {
    final currentAgentId = _viewModel.workbench.agentSelector.currentAgentId
        .trim();
    if (currentAgentId.isNotEmpty) {
      unawaited(_showCurrentAgentExpressionConstraints(currentAgentId));
      return;
    }
    projectAssetsController.openExpressionConstraintsForAgent('');
    showProjectAssets();
  }

  void onResourceEntrySelected(String entryId) =>
      _workbenchWorkspaceController.onResourceEntrySelected(entryId);

  void onWorkspaceCommandDismissed() =>
      _workbenchWorkspaceController.onWorkspaceCommandDismissed();

  void onWorkspaceImportFilesPickRequested(
    WorkspaceCommandRequestViewData request,
  ) => _workbenchWorkspaceController.onWorkspaceImportFilesPickRequested(
    request,
  );

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

  void onAgentGroupSelected(String groupId) {
    // 中文注释: 会话栏与 opening 面板的组切换统一转发给会话控制器，避免壳层直接碰项目默认组绑定。
    _workbenchConversationController.onAgentGroupSelected(groupId);
  }

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

  void onReasoningToggleChanged(bool enabled) =>
      _workbenchConversationController.onReasoningToggleChanged(enabled);

  void onStopRequested() => _workbenchConversationController.onStopRequested();

  void onAttachmentRequested() =>
      _workbenchConversationController.onAttachmentRequested();

  void onSendRequested(String text) =>
      _workbenchConversationController.onSendRequested(text);

  @override
  void onAgentEcosystemBackRequested() {
    // 中文注释: 生态页关闭统一回到工作台，避免页内自己操作外层导航结构。
    showWorkbench();
  }

  @override
  void onEcosystemRefreshRequested() {
    // 中文注释: 生态刷新统一回到控制器，再由独立的目录加载与 view data 服务承接细节。
    // 顶层刷新进行中置 busy，禁用顶部按钮防连点；刷新结束(成功或失败)复位。
    _refreshAgentEcosystemWithBusy();
  }

  Future<void> _refreshAgentEcosystemWithBusy() async {
    _setAgentEcosystemBusy(true);
    try {
      await _refreshAgentEcosystem();
    } finally {
      _setAgentEcosystemBusy(false);
    }
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
        isImporting: true,
      ),
    );
    final bundleContent = await _projectToolHostPort.readExternalTextFile(
      bundlePath,
    );
    if ((bundleContent ?? '').trim().isEmpty) {
      _updateEcosystemImportCommand(
        _ecosystemImportCommand?.copyWith(
          status: '生态包文件不存在或不是可读文本。',
          isImporting: false,
        ),
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
            isImporting: false,
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
            isImporting: false,
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
        _ecosystemImportCommand?.copyWith(
          status: UserFacingErrorHumanizer.humanize(error, action: '导入生态包'),
          isImporting: false,
        ),
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
    _setAgentEcosystemBusy(true);
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
      _setAgentEcosystemStatus(
        UserFacingErrorHumanizer.humanize(error, action: '生成生态索引'),
      );
    } finally {
      _setAgentEcosystemBusy(false);
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
  void onProjectSkillLoadoutSkillGroupToggled(
    String agentId,
    String groupId,
    bool selected,
  ) {
    _projectSkillLoadoutWorkspaceSnapshot = _projectSkillLoadoutWorkspaceService
        .toggleSkillGroup(
          _projectSkillLoadoutWorkspaceSnapshot,
          agentId: agentId,
          groupId: groupId,
          selected: selected,
        );
    _refreshAgentEcosystemView();
  }

  @override
  void onProjectSkillLoadoutExtraSkillToggled(
    String agentId,
    String skillId,
    bool selected,
  ) {
    _projectSkillLoadoutWorkspaceSnapshot = _projectSkillLoadoutWorkspaceService
        .toggleExtraSkill(
          _projectSkillLoadoutWorkspaceSnapshot,
          agentId: agentId,
          skillId: skillId,
          selected: selected,
        );
    _refreshAgentEcosystemView();
  }

  @override
  void onProjectSkillLoadoutDisabledSkillToggled(
    String agentId,
    String skillId,
    bool disabled,
  ) {
    _projectSkillLoadoutWorkspaceSnapshot = _projectSkillLoadoutWorkspaceService
        .toggleDisabledSkill(
          _projectSkillLoadoutWorkspaceSnapshot,
          agentId: agentId,
          skillId: skillId,
          disabled: disabled,
        );
    _refreshAgentEcosystemView();
  }

  @override
  void onProjectSkillLoadoutApplyRequested(String agentId) async {
    final project = _currentProject;
    if (project == null) {
      _setAgentEcosystemStatus('请先创建或打开项目，才能应用项目级技能装载。');
      return;
    }
    _setAgentEcosystemStatus('正在应用项目技能装载...');
    try {
      _projectSkillLoadoutWorkspaceSnapshot =
          await _projectSkillLoadoutWorkspaceService.applyDraft(
            project,
            _projectSkillLoadoutWorkspaceSnapshot,
            agentId: agentId,
          );
      _setAgentEcosystemStatus('项目技能装载已应用。');
    } catch (error) {
      _setAgentEcosystemStatus(
        UserFacingErrorHumanizer.humanize(error, action: '应用项目技能装载'),
      );
    }
  }

  @override
  void onProjectSkillLoadoutResetRequested(String agentId) {
    _projectSkillLoadoutWorkspaceSnapshot = _projectSkillLoadoutWorkspaceService
        .resetDraft(_projectSkillLoadoutWorkspaceSnapshot, agentId);
    _setAgentEcosystemStatus('已恢复到当前已保存的项目技能装载。');
  }

  @override
  void onProjectSkillLoadoutHistoryRestoreRequested(
    String agentId,
    String historyEntryId,
  ) {
    _projectSkillLoadoutWorkspaceSnapshot = _projectSkillLoadoutWorkspaceService
        .restoreHistoryEntry(
          _projectSkillLoadoutWorkspaceSnapshot,
          agentId: agentId,
          historyEntryId: historyEntryId,
        );
    _setAgentEcosystemStatus('已把历史快照恢复到当前草稿，确认后再应用。');
  }

  @override
  void onProjectSkillLoadoutHistoryCaptureRequested(
    String agentId,
    String title,
  ) async {
    final project = _currentProject;
    if (project == null) {
      _setAgentEcosystemStatus('请先创建或打开项目，才能保存技能装载历史。');
      return;
    }
    _setAgentEcosystemStatus('正在保存技能装载历史快照...');
    try {
      _projectSkillLoadoutWorkspaceSnapshot =
          await _projectSkillLoadoutWorkspaceService.saveHistorySnapshot(
            project,
            _projectSkillLoadoutWorkspaceSnapshot,
            agentId: agentId,
            title: title,
          );
      _setAgentEcosystemStatus('技能装载历史快照已保存。');
    } catch (error) {
      _setAgentEcosystemStatus(
        UserFacingErrorHumanizer.humanize(error, action: '保存技能装载历史'),
      );
    }
  }

  @override
  void onProjectSkillLoadoutSaveAsGroupRequested(
    String agentId,
    String groupId,
    String displayName,
    String description,
  ) async {
    final project = _currentProject;
    if (project == null) {
      _setAgentEcosystemStatus('请先创建或打开项目，才能另存为技能组。');
      return;
    }
    final resolvedLoadout = _resolvedProjectSkillLoadoutForAgent(agentId);
    if (resolvedLoadout == null) {
      _setAgentEcosystemStatus('当前智能体不存在，无法另存为技能组。');
      return;
    }
    _setAgentEcosystemStatus('正在另存为技能组...');
    try {
      final savedGroupId = await _projectSkillLoadoutWorkspaceService
          .saveAsGroup(
            project: project,
            loadout: resolvedLoadout,
            groupId: groupId,
            displayName: displayName,
            description: description,
          );
      await _refreshAgentEcosystem(
        selectedTabId: 'skill-loadouts',
        selectedEntryId: agentId,
      );
      _setAgentEcosystemStatus('已另存为技能组：$savedGroupId');
    } catch (error) {
      _setAgentEcosystemStatus(
        UserFacingErrorHumanizer.humanize(error, action: '另存为技能组'),
      );
    }
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
      _projectSkillLoadoutWorkspaceSnapshot =
          ProjectSkillLoadoutWorkspaceSnapshot.initial();
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
    _projectSkillLoadoutWorkspaceSnapshot =
        await _projectSkillLoadoutWorkspaceService.load(project);
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
    final projectSkillLoadoutViewData = _buildProjectSkillLoadoutViewData();
    final viewData = _agentEcosystemViewDataService
        .build(
          _agentEcosystemSnapshot,
          projectSkillLoadoutViewData: projectSkillLoadoutViewData,
        )
        .copyWith(
          statusMessage: _agentEcosystemStatusMessage,
          isBusy: _agentEcosystemBusy,
          importCommand: _ecosystemImportCommand,
          editorViewData: _ecosystemEditorViewData,
        );
    final settings = _settings;
    _viewModel = _viewModel.copyWith(agentEcosystem: viewData);
    if (settings != null) {
      _viewModel = _viewModel.copyWith(
        workbench: _viewModel.workbench.copyWith(
          modelOptions: _modelSelectorOptions(settings),
          groupSelector: _fallbackGroupSelector(settings),
          inputCapabilityContext: _conversationInputCapabilityContext(settings),
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

  void _setAgentEcosystemBusy(bool value) {
    // 中文注释: 顶层异步(刷新/生成索引)进行中标志——true 时顶部按钮禁用，防止连点触发并行刷新/重建。
    _agentEcosystemBusy = value;
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
      _setAgentEcosystemStatus('请先打开一个项目，再创建项目内生态条目。');
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
      // 中文注释: 新建后直接打开"表单编辑器"（带成员弹窗多选），而不是跳到工作台裸编 JSON。
      // 不走 _showEcosystemEditor(entryId)（它在快照里按 id 反查 proposal，新建的 proposal
      // 快照 id/落点常与 plan.entryId 不一致，会查不到、表单不弹）。这里直接用 plan 构造条目
      // + 刚写入的文件内容构建表单，与"编辑"共用 _buildEcosystemEditorForEntry。
      final sourceContent =
          await _projectToolHostPort.readTextFile(
            project.rootPath,
            plan.relativePath,
          ) ??
          plan.content;
      _updateEcosystemEditorViewData(
        _buildEcosystemEditorForEntry(
          entry: <String, Object?>{
            'id': plan.entryId,
            'name': plan.title,
            'project_relative_path': plan.relativePath,
            'entry_file_path': plan.relativePath,
            'source': 'project_package',
          },
          kind: plan.kind,
          sourceContent: sourceContent,
        ),
      );
      _setAgentEcosystemStatus('已创建 ${_ecosystemKindLabel(plan.kind)}：${plan.title}，请在表单里填写。');
    } catch (error) {
      // 中文注释: 反馈必须走生态页状态通道(_setAgentEcosystemStatus)，_announce 只写工作台状态条，生态页看不到。
      _setAgentEcosystemStatus(
        UserFacingErrorHumanizer.humanize(error, action: '创建生态条目'),
      );
    }
  }

  Future<void> _openEcosystemEntrySource(String entryId) async {
    // 中文注释: 生态源文件打开统一从当前快照反查，避免详情面板自己理解项目目录结构。
    final entry = _selectedEcosystemSnapshotEntry(entryId);
    if (entry == null) {
      _setAgentEcosystemStatus('未找到要打开的生态条目。');
      return;
    }
    final projectRelativePath = _stringValue(entry['project_relative_path']);
    if (projectRelativePath.trim().isEmpty) {
      _setAgentEcosystemStatus('当前条目没有项目内可编辑源文件。');
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
    final canDuplicateBuiltin =
        relativePath.isEmpty &&
        (kind == 'skill-groups' || kind == 'agent-groups');
    if (relativePath.isEmpty && !canDuplicateBuiltin) {
      _setAgentEcosystemStatus('当前条目不是可复制的项目级条目，不能直接编辑。');
      return;
    }
    final sourceContent = relativePath.isEmpty
        ? ''
        : await _projectToolHostPort.readTextFile(
                project.rootPath,
                relativePath,
              ) ??
              '';
    _updateEcosystemEditorViewData(
      _buildEcosystemEditorForEntry(
        entry: entry,
        kind: kind,
        sourceContent: sourceContent,
      ),
    );
  }

  /// 由生态条目（快照条目或新建计划构造的条目）+ 源文件内容构建编辑器视图，并注入可选成员目录。
  /// 中文注释: 抽出来给"编辑"和"新建"两条入口共用，避免新建时依赖快照里按 id 反查 proposal
  /// （proposal 的快照 id/落点可能与 plan.entryId 不一致，会导致查不到、表单不弹）。
  EcosystemEditorViewData _buildEcosystemEditorForEntry({
    required JsonMap entry,
    required String kind,
    required String sourceContent,
  }) {
    return _ecosystemEntryEditorService
        .buildForEntry(entry, kind: kind, sourceContent: sourceContent)
        .copyWith(
          // 注入可选成员目录，供编辑器"弹窗多选"取代手填 ID（按 kind 用对应的几个）。
          availableAgents: _agentEcosystemViewDataService.pickerOptionsFor(
            tabId: 'agents',
            entries: _agentEcosystemSnapshot.agents,
          ),
          availableSkills: _agentEcosystemViewDataService.pickerOptionsFor(
            tabId: 'skills',
            entries: _agentEcosystemSnapshot.skills,
          ),
          availableSkillGroups: _agentEcosystemViewDataService.pickerOptionsFor(
            tabId: 'skill-groups',
            entries: _agentEcosystemSnapshot.skillGroups,
          ),
        );
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
      if (plan.deleteOldRelativePath &&
          oldRelativePath.isNotEmpty &&
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
        '已保存${_ecosystemKindLabel(request.kind)}：${request.name.trim().isEmpty ? request.entryId : request.name.trim()}。${plan.statusMessage}',
      );
    } catch (error) {
      _updateEcosystemEditorViewData(
        _ecosystemEditorViewData?.copyWith(
          statusMessage: UserFacingErrorHumanizer.humanize(error, action: '保存生态条目'),
        ),
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
        _ecosystemEditorViewData?.copyWith(
          statusMessage: UserFacingErrorHumanizer.humanize(error, action: '删除生态条目'),
        ),
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
    _viewModel = _viewModel.copyWith(destination: AppDestination.projectOpen);
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
    await _taskCenterCommandOrchestrationService.runProjectCommand(
      environment: _taskCenterCommandEnvironment,
      pendingMessage: '正在生成长任务队列...',
      successMessage: '长任务队列已生成。',
      operation: (project, settings) async {
        final runtimeProfile = await _workbenchWorkspaceController
            .reloadCurrentRuntimeProfile();
        final contract = const LongTaskProjectContractService().assess(
          project: project,
          runtimeProfile: runtimeProfile,
        );
        if (!contract.isAllowed) {
          return <String, Object?>{
            'ok': false,
            'error': contract.message,
            'error_code': contract.errorCode,
          };
        }
        final initialRunOptions = runtimeProfile == null
            ? const <String, Object?>{}
            : ValueReaders.deepCopyMap(runtimeProfile.initialRunOptions);
        final runtimeMode = request.mode.trim().isEmpty
            ? (runtimeProfile?.runtimeMode.trim().isEmpty ?? true
                  ? TaskRuntimeConstants.modeHumanOutlineAiDraft
                  : runtimeProfile!.runtimeMode.trim())
            : request.mode.trim();
        return _workflowRuntimeService.createLongTaskWorkflow(
          project,
          runtimeMode,
          options: _taskCenterWorkflowCreateOptionMapperService.buildOptions(
            request: request,
            initialRunOptions: initialRunOptions,
            runtimeMode: runtimeMode,
            runtimeBaselineId: ValueReaders.stringValue(
              initialRunOptions['runtime_baseline_id'],
              runtimeProfile?.runtimeBaselineId ?? project.runtimeBaselineId,
            ),
          ),
        );
      },
    );
  }

  @override
  void onTaskCenterSavePlanRequested() {
    _taskCenterCommandOrchestrationService.runSelectorCommand(
      environment: _taskCenterCommandEnvironment,
      pendingMessage: '正在生成任务计划...',
      successMessage: '任务计划已生成。',
      operation: (project, selector, settings) {
        return _workflowRuntimeService.saveWorkflowTaskPlan(project, selector);
      },
    );
  }

  @override
  void onTaskCenterSaveChainSnapshotRequested() {
    _taskCenterCommandOrchestrationService.runProjectCommand(
      environment: _taskCenterCommandEnvironment,
      pendingMessage: '正在保存链路快照...',
      successMessage: '任务链路快照已保存。',
      operation: (project, settings) {
        return _workflowRuntimeService.saveWorkflowChainSnapshot(project);
      },
    );
  }

  @override
  void onTaskCenterPrepareExecutionRequested() {
    _taskCenterCommandOrchestrationService.runSelectorCommand(
      environment: _taskCenterCommandEnvironment,
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
    _taskCenterCommandOrchestrationService.runSelectorCommand(
      environment: _taskCenterCommandEnvironment,
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
    _taskCenterCommandOrchestrationService.runProjectCommand(
      environment: _taskCenterCommandEnvironment,
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
    _taskCenterCommandOrchestrationService.runProjectCommand(
      environment: _taskCenterCommandEnvironment,
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
    _taskCenterCommandOrchestrationService.runSelectorCommand(
      environment: _taskCenterCommandEnvironment,
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
    _taskCenterCommandOrchestrationService.runProjectCommand(
      environment: _taskCenterCommandEnvironment,
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
    _taskCenterCommandOrchestrationService.runSelectorCommand(
      environment: _taskCenterCommandEnvironment,
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
    _taskCenterCommandOrchestrationService.runSelectorCommand(
      environment: _taskCenterCommandEnvironment,
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
    _taskCenterCommandOrchestrationService.runRecentRunCommand(
      environment: _taskCenterCommandEnvironment,
      pendingMessage: '正在暂停长任务运行...',
      successMessage: '长任务运行已暂停。',
      loadRecentRuns: (project) =>
          _workflowRuntimeService.listLongTaskRuns(project, limit: 1),
      operation: (project, settings, runPath) {
        return _workflowRuntimeService.pauseLongTaskRun(project, runPath);
      },
    );
  }

  @override
  void onTaskCenterResumeRequested() {
    _taskCenterCommandOrchestrationService.runRecentRunCommand(
      environment: _taskCenterCommandEnvironment,
      pendingMessage: '正在恢复长任务运行...',
      successMessage: '长任务运行已恢复推进。',
      loadRecentRuns: (project) =>
          _workflowRuntimeService.listLongTaskRuns(project, limit: 1),
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
    _taskCenterCommandOrchestrationService.runSelectorCommand(
      environment: _taskCenterCommandEnvironment,
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
    _taskCenterCommandOrchestrationService.runSelectorCommand(
      environment: _taskCenterCommandEnvironment,
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
        _taskCenterCommandOrchestrationService.runSharedActionCommand(
          environment: _taskCenterCommandEnvironment,
          action: action,
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
        return;
      case 'revision_resolution':
        _taskCenterCommandOrchestrationService.runSharedActionCommand(
          environment: _taskCenterCommandEnvironment,
          action: action,
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
        return;
      case 'run_center_control':
        switch (action.id) {
          case 'pause':
            _taskCenterCommandOrchestrationService.runSharedActionCommand(
              environment: _taskCenterCommandEnvironment,
              action: action,
              pendingMessage: '正在暂停长任务运行...',
              successMessage: '长任务运行已暂停。',
              operation: (project, settings) {
                return _workflowRuntimeService.pauseLongTaskRun(
                  project,
                  action.longTaskRunPath,
                );
              },
            );
            return;
          case 'resume':
            _taskCenterCommandOrchestrationService.runSharedActionCommand(
              environment: _taskCenterCommandEnvironment,
              action: action,
              pendingMessage: '正在恢复长任务运行...',
              successMessage: '长任务运行已恢复推进。',
              requireSettings: true,
              operation: (project, settings) {
                if (settings == null) {
                  return Future<JsonMap>.value(<String, Object?>{
                    'ok': false,
                    'error': '设置尚未加载完成。',
                  });
                }
                return _workflowRuntimeService.resumeLongTaskRun(
                  project,
                  settings,
                  action.longTaskRunPath,
                );
              },
            );
            return;
          case 'stop':
            _taskCenterCommandOrchestrationService.runSharedActionCommand(
              environment: _taskCenterCommandEnvironment,
              action: action,
              pendingMessage: '正在停止长任务运行...',
              successMessage: '长任务运行已停止。',
              operation: (project, settings) {
                return _workflowRuntimeService.stopLongTaskRun(
                  project,
                  action.longTaskRunPath,
                );
              },
            );
            return;
          case 'confirm_checkpoint':
            _taskCenterCommandOrchestrationService.runSharedActionCommand(
              environment: _taskCenterCommandEnvironment,
              action: action,
              pendingMessage: '正在确认检查点并准备继续长任务...',
              successMessage: '已确认检查点，长任务可继续推进。',
              operation: (project, settings) async {
                final revision = await _workflowRuntimeService
                    .buildLongTaskRevisionPlan(
                      project,
                      'confirm_checkpoint',
                      runPath: action.longTaskRunPath,
                      arguments: <String, Object?>{
                        if (action.ownerTaskId.trim().isNotEmpty)
                          'task_id': action.ownerTaskId,
                        'note': '用户在任务中心确认检查点，允许长任务继续。',
                      },
                    );
                if (!ValueReaders.boolValue(revision['ok'])) {
                  return revision;
                }
                return _workflowRuntimeService.applyLongTaskRevisionPlan(
                  project,
                  revision,
                );
              },
            );
            return;
          case 'retry_failed':
          case 'skip_failed':
            final command = action.id == 'retry_failed' ? 'retry' : 'skip';
            final pendingMessage = action.id == 'retry_failed'
                ? '正在恢复失败任务并准备继续长任务...'
                : '正在跳过失败任务并尝试恢复长任务...';
            final successMessage = action.id == 'retry_failed'
                ? '已将失败任务重新排队，长任务可继续推进。'
                : '已跳过失败任务，长任务可尝试继续推进。';
            _taskCenterCommandOrchestrationService.runSharedActionCommand(
              environment: _taskCenterCommandEnvironment,
              action: action,
              pendingMessage: pendingMessage,
              successMessage: successMessage,
              operation: (project, settings) {
                return _workflowRuntimeService.applyLongTaskFailureAction(
                  project,
                  selector: <String, Object?>{
                    'relative_path': action.ownerTaskPath,
                    if (action.ownerTaskId.trim().isNotEmpty)
                      'task_id': action.ownerTaskId,
                  },
                  command: command,
                  runPath: action.longTaskRunPath,
                );
              },
            );
            return;
          default:
            unawaited(_refreshTaskCenter(status: '当前图形界面还未接通该运行控制动作。'));
            return;
        }
      case 'task_user_option':
        _taskCenterCommandOrchestrationService.runSharedActionCommand(
          environment: _taskCenterCommandEnvironment,
          action: action,
          pendingMessage: '正在记录用户选择并准备继续当前任务...',
          successMessage: '已记录用户选择，可继续当前任务。',
          operation: (project, settings) {
            return _workflowRuntimeService.applyWorkflowTaskUserChoice(
              project,
              <String, Object?>{'relative_path': action.ownerTaskPath},
              prompt: action.userOptionPrompt,
              label: action.label,
              description: action.userOptionDescription,
              sourceQuestion: action.userOptionQuestion,
              permissionApprovalId: action.permissionApprovalId,
              permissionApprovalOptionId: action.permissionApprovalOptionId,
            );
          },
        );
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
      _viewModel = _viewModel.copyWith(
        destination: AppDestination.longTaskStation,
      );
      _safeNotifyListeners();
      return;
    }
    await _refreshReviewCenter(
      status: _resultMessage(result, success: '已生成修复任务。'),
    );
  }

  @override
  void onReviewCenterRewriteModeSelected(String rewriteMode) {
    _reviewCenterAnalysisState = _reviewCenterAnalysisStateService
        .updateRewriteMode(_reviewCenterAnalysisState, rewriteMode);
    _refreshReviewCenterView();
  }

  @override
  void onReviewCenterSuggestionToggled(String suggestionId, bool selected) {
    _reviewCenterAnalysisState = _reviewCenterAnalysisStateService
        .toggleSuggestion(_reviewCenterAnalysisState, suggestionId, selected);
    _refreshReviewCenterView();
  }

  @override
  void onReviewCenterSegmentToggled(String segmentId, bool selected) {
    _reviewCenterAnalysisState = _reviewCenterAnalysisStateService
        .toggleSegment(_reviewCenterAnalysisState, segmentId, selected);
    _refreshReviewCenterView();
  }

  @override
  void onReviewCenterPlanRequested() {
    _applyReviewCenterRewritePlan();
    _refreshReviewCenterView();
  }

  @override
  void onReviewCenterMaterializeRewriteRequested() async {
    final project = _currentProject;
    final analysisResult = _reviewCenterAnalysisState.analysisResult;
    if (project == null) {
      await _refreshReviewCenter(status: '请先创建或打开项目。');
      return;
    }
    if (analysisResult == null) {
      await _refreshReviewCenter(status: '当前报告还没有可用的分析结果。');
      return;
    }
    _applyReviewCenterRewritePlan();
    final plan = _reviewCenterAnalysisState.currentPlan;
    if (plan == null) {
      await _refreshReviewCenter(status: '请先生成重写计划。');
      return;
    }
    if (plan.actionKind == ChapterRewriteActionKind.suggestionsOnly) {
      _reviewCenterStatusMessage = '已整理建议与执行说明，本次不创建修订任务。';
      await _refreshReviewCenterView();
      return;
    }
    if (plan.actionKind == ChapterRewriteActionKind.rewritePartial &&
        plan.targetSegments.isEmpty) {
      await _refreshReviewCenter(status: '局部重写至少需要选中一个目标片段。');
      return;
    }
    _reviewCenterStatusMessage = '正在创建修订任务...';
    await _refreshReviewCenterView();
    final result = await _projectChapterRewriteTaskService
        .createRevisionTaskFromPlan(
          project,
          plan,
          analysisPath: _reviewCenterAnalysisState.analysisPath,
        );
    await _syncWorkbenchResources();
    if (ValueReaders.boolValue(result['ok'])) {
      _selectedTaskId = ValueReaders.stringValue(result['relative_path']);
      await _refreshTaskCenter(status: '已根据分析计划创建修订任务。');
      _viewModel = _viewModel.copyWith(
        destination: AppDestination.longTaskStation,
      );
      _safeNotifyListeners();
      return;
    }
    await _refreshReviewCenter(
      status: _resultMessage(result, success: '已创建修订任务。'),
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
    // 中文注释: 任务中心刷新统一交给专用服务，控制器只保留状态快照、版本号和视图回写。
    final project = _currentProject;
    final projectRootPath = project?.rootPath ?? '';
    final refreshGeneration = ++_taskCenterRefreshGeneration;
    try {
      final result = await _taskCenterRefreshService.refresh(
        TaskCenterRefreshRequest(
          project: project,
          selectedTaskId: _selectedTaskId,
          selectedLongTaskRunPath: _selectedLongTaskRunPath,
          selectedTaskQueueRunPath: _selectedTaskQueueRunPath,
          statusMessage: status ?? _taskCenterStatusMessage,
          taskCenterCommandInFlight: _taskCenterCommandInFlight,
          runtimeProfile:
              _workbenchWorkspaceController.currentProjectRuntimeProfile,
          projectStorageStrategy: project?.storageStrategy,
        ),
      );
      if (_isTaskCenterRefreshStale(
        generation: refreshGeneration,
        projectRootPath: projectRootPath,
      )) {
        return;
      }
      _taskCenterTasks = result.tasks;
      _selectedTaskId = result.selectedTaskId;
      _selectedLongTaskRunPath = result.selectedLongTaskRunPath;
      _selectedTaskQueueRunPath = result.selectedTaskQueueRunPath;
      _taskCenterStatusMessage = result.statusMessage;
      _viewModel = _viewModel.copyWith(taskCenter: result.viewData);
      _safeNotifyListeners();
      _navigationTraceService?.markPageRefreshCompleted(
        AppDestination.taskCenter,
        label: 'task_center_refresh',
      );
    } on FileSystemException {
      if (_shouldSilenceTaskCenterRefreshFileSystemError(projectRootPath)) {
        return;
      }
      rethrow;
    }
  }

  Future<void> _refreshTaskCenterView() async {
    // 中文注释: 视图重建和完整刷新现在共享同一条正式服务链，避免控制器再分叉出第二套投影规则。
    await _refreshTaskCenter(status: _taskCenterStatusMessage);
  }

  Future<void> _refreshTaskCenterFromLongTaskStation() async {
    if (_disposed ||
        _currentProject == null ||
        _viewModel.destination != AppDestination.longTaskStation) {
      return;
    }
    await _refreshTaskCenter();
  }

  Future<void> _refreshLongTaskStationAfterTaskCenterMutation() async {
    if (_disposed || _currentProject == null) {
      return;
    }
    await _longTaskStationController.refresh();
  }

  void _requestTaskCenterLongTaskPulse({
    Duration delay = const Duration(milliseconds: 50),
    Duration interval = const Duration(milliseconds: 250),
  }) {
    if (_taskCenterLongTaskPulseInFlight ||
        _disposed ||
        _currentProject == null) {
      return;
    }
    final projectRootPath = _currentProject!.rootPath;
    _taskCenterLongTaskPulseInFlight = true;
    unawaited(() async {
      try {
        var nextDelay = delay;
        while (_shouldContinueTaskCenterLongTaskPulse(projectRootPath)) {
          await Future<void>.delayed(nextDelay);
          if (!_shouldContinueTaskCenterLongTaskPulse(projectRootPath)) {
            return;
          }
          await _longTaskStationController.refresh();
          if (!_shouldContinueTaskCenterLongTaskPulse(projectRootPath)) {
            return;
          }
          await _refreshTaskCenterView();
          nextDelay = interval;
        }
      } finally {
        _taskCenterLongTaskPulseInFlight = false;
      }
    }());
  }

  bool _shouldContinueTaskCenterLongTaskPulse(String projectRootPath) {
    final currentProject = _currentProject;
    if (_disposed || !_taskCenterCommandInFlight || currentProject == null) {
      return false;
    }
    return currentProject.rootPath == projectRootPath;
  }

  bool _isTaskCenterRefreshStale({
    required int generation,
    required String projectRootPath,
  }) {
    final currentProject = _currentProject;
    if (_disposed) {
      return true;
    }
    if (generation != _taskCenterRefreshGeneration) {
      return true;
    }
    if (currentProject == null) {
      return true;
    }
    return currentProject.rootPath != projectRootPath;
  }

  bool _shouldSilenceTaskCenterRefreshFileSystemError(String projectRootPath) {
    if (_disposed) {
      return true;
    }
    final currentProject = _currentProject;
    if (currentProject == null) {
      return true;
    }
    if (currentProject.rootPath != projectRootPath) {
      return true;
    }
    return !Directory(projectRootPath).existsSync();
  }

  Future<void> _adoptTaskCenterRunSelectionsFromResult(JsonMap result) async {
    final longRunPath = ValueReaders.stringValue(
      result['long_task_run_path'],
    ).trim();
    if (longRunPath.isNotEmpty) {
      _selectedLongTaskRunPath = longRunPath;
    }
    final directQueuePath = ValueReaders.stringValue(
      result['relative_path'],
    ).trim();
    final explicitQueuePath = ValueReaders.stringValue(
      result['task_queue_run_path'],
    ).trim();
    final queuePath = explicitQueuePath.isNotEmpty
        ? explicitQueuePath
        : (directQueuePath.startsWith('tracking/task_queue_runs/')
              ? directQueuePath
              : '');
    if (queuePath.isNotEmpty) {
      _selectedTaskQueueRunPath = queuePath;
    }
  }

  Future<void> _refreshReviewCenter({String? status}) async {
    // 中文注释: 审稿中心刷新统一使用共享报告服务，避免 GUI 自己扫目录和手写过滤规则。
    final project = _currentProject;
    if (project == null) {
      _reviewCenterEntries = const <JsonMap>[];
      _selectedReviewEntryId = '';
      _reviewCenterAnalysisState = ReviewCenterAnalysisState.initial();
      _viewModel = _viewModel.copyWith(
        reviewCenter: _reviewCenterViewDataService.build(
          entries: const <JsonMap>[],
          reviewTypeDefinitions: _reviewReportService.listReviewTypeDefs(),
          selectedEntryId: '',
          detailBody: '请先创建或打开项目。',
          reviewTypeFilter: _reviewTypeFilter,
          scopeFilter: _reviewScopeFilter,
          sourceFilter: _reviewSourceFilter,
          analysisState: _reviewCenterAnalysisState,
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
    final selectedStillExists = _reviewCenterEntries.any(
      (entry) =>
          ValueReaders.stringValue(
            entry['markdown_path'],
            ValueReaders.stringValue(entry['relative_path']),
          ) ==
          _selectedReviewEntryId,
    );
    if (!selectedStillExists) {
      _selectedReviewEntryId = _reviewCenterEntries.isEmpty
          ? ''
          : ValueReaders.stringValue(
              _reviewCenterEntries.first['markdown_path'],
              ValueReaders.stringValue(
                _reviewCenterEntries.first['relative_path'],
              ),
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
    var nextAnalysisState = ReviewCenterAnalysisState.initial();
    if (_selectedReviewEntryId.trim().isNotEmpty) {
      final loaded = await _reviewReportService.loadReport(
        project,
        _selectedReviewEntryId,
      );
      detailBody = _reviewCenterViewDataService.fallbackDetailBody(loaded);
      final report = ValueReaders.mapValue(loaded['report']);
      if (ValueReaders.boolValue(loaded['ok']) && report.isNotEmpty) {
        final analysisResult = _reviewReportChapterAnalysisProjectionService
            .project(
              report,
              generatedId: ValueReaders.stringValue(
                report['id'],
                _selectedReviewEntryId,
              ),
              createdAt: ValueReaders.stringValue(report['created_at']),
              reportPath: ValueReaders.stringValue(
                loaded['markdown_path'],
                _selectedReviewEntryId,
              ),
            );
        nextAnalysisState = _syncReviewCenterAnalysisState(
          currentState: _reviewCenterAnalysisState,
          nextResult: analysisResult,
          analysisPath: ValueReaders.stringValue(
            loaded['markdown_path'],
            _selectedReviewEntryId,
          ),
        );
        nextAnalysisState = await _hydrateReviewCenterPlaybackState(
          project,
          nextAnalysisState,
        );
      }
    }
    _reviewCenterAnalysisState = nextAnalysisState;
    _viewModel = _viewModel.copyWith(
      reviewCenter: _reviewCenterViewDataService.build(
        entries: _reviewCenterEntries,
        reviewTypeDefinitions: _reviewReportService.listReviewTypeDefs(),
        selectedEntryId: _selectedReviewEntryId,
        detailBody: detailBody,
        reviewTypeFilter: _reviewTypeFilter,
        scopeFilter: _reviewScopeFilter,
        sourceFilter: _reviewSourceFilter,
        analysisState: _reviewCenterAnalysisState,
        status: _reviewCenterStatusMessage,
      ),
    );
    _safeNotifyListeners();
  }

  ReviewCenterAnalysisState _syncReviewCenterAnalysisState({
    required ReviewCenterAnalysisState currentState,
    required ChapterAnalysisResult nextResult,
    required String analysisPath,
  }) {
    final currentResult = currentState.analysisResult;
    if (currentResult != null &&
        currentResult.id == nextResult.id &&
        currentState.analysisPath == analysisPath.trim()) {
      return currentState;
    }
    return _reviewCenterAnalysisStateService.createInitialState(
      nextResult,
      analysisPath: analysisPath,
    );
  }

  Future<ReviewCenterAnalysisState> _hydrateReviewCenterPlaybackState(
    ProjectDescriptor project,
    ReviewCenterAnalysisState state,
  ) async {
    final plannedState = _rebuildReviewCenterRewritePlan(state: state);
    final plan = plannedState.currentPlan;
    final result = plannedState.analysisResult;
    if (plan == null || result == null) {
      return plannedState.copyWith(playbackBody: '', playbackSourcePath: '');
    }
    final sourcePath = _playbackSourcePath(plan, result);
    if (sourcePath.isEmpty) {
      return plannedState.copyWith(playbackBody: '', playbackSourcePath: '');
    }
    final sourceBody =
        await _projectToolHostPort.readTextFile(project.rootPath, sourcePath) ??
        '';
    return plannedState.copyWith(
      playbackBody: _reviewCenterPlaybackPreviewService.build(
        plan: plan,
        sourceBody: sourceBody,
      ),
      playbackSourcePath: sourcePath,
    );
  }

  void _applyReviewCenterRewritePlan() {
    _reviewCenterAnalysisState = _rebuildReviewCenterRewritePlan(
      state: _reviewCenterAnalysisState,
    );
  }

  ReviewCenterAnalysisState _rebuildReviewCenterRewritePlan({
    required ReviewCenterAnalysisState state,
  }) {
    final result = state.analysisResult;
    if (result == null) {
      return state.copyWith(clearCurrentPlan: true);
    }
    final selectedSuggestions = _reviewCenterAnalysisStateService
        .selectedSuggestions(state);
    final selectedSuggestionIds = selectedSuggestions
        .map((item) => item.id)
        .toList(growable: false);
    final selectedIssueIds = selectedSuggestions
        .expand((item) => item.issueIds)
        .where((item) => item.trim().isNotEmpty)
        .toSet()
        .toList(growable: false);
    final planBuilder = const ChapterRewritePlanBuilderService();
    ChapterRewritePlan plan;
    switch (state.rewriteMode) {
      case ChapterRewriteActionKind.rewriteFull:
        plan = planBuilder.buildFullChapterPlan(
          result,
          generatedId: 'plan_${result.id}_full',
          selectedIssueIds: selectedIssueIds,
          selectedSuggestionIds: selectedSuggestionIds,
        );
        break;
      case ChapterRewriteActionKind.rewritePartial:
        plan = planBuilder.buildPartialRewritePlan(
          result,
          generatedId: 'plan_${result.id}_partial',
          targetSegments: _reviewCenterAnalysisStateService.selectedSegments(
            state,
          ),
          selectedIssueIds: selectedIssueIds,
          selectedSuggestionIds: selectedSuggestionIds,
        );
        break;
      default:
        plan = planBuilder.buildSuggestionsOnlyPlan(
          result,
          generatedId: 'plan_${result.id}_advice',
          selectedIssueIds: selectedIssueIds,
          selectedSuggestionIds: selectedSuggestionIds,
        );
        break;
    }
    return state.copyWith(currentPlan: plan);
  }

  String _playbackSourcePath(
    ChapterRewritePlan plan,
    ChapterAnalysisResult result,
  ) {
    if (plan.targetSegments.isNotEmpty) {
      return plan.targetSegments.first.sourcePath.trim();
    }
    if (plan.outputPaths.isNotEmpty) {
      return plan.outputPaths.first.trim();
    }
    if (result.sourcePaths.isNotEmpty) {
      return result.sourcePaths.first.trim();
    }
    return result.chapterPath.trim();
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

  Future<void> _syncWorkbenchResources({String selectedId = ''}) async {
    // 中文注释: 任务、审稿、模板等页面改动项目文件后，统一刷新工作台资源树，保证目录视图始终跟真实磁盘一致。
    final currentSelectedId = selectedId.trim().isEmpty
        ? _viewModel.workbench.activeDocumentPath
        : selectedId.trim();
    _workbenchWorkspaceController.invalidateInformationViewCache();
    final entries = await _reloadResourceEntries(selectedId: currentSelectedId);
    _viewModel = _viewModel.copyWith(
      workbench: _workbenchConversationController.applyConversationState(
        _viewModel.workbench.copyWith(resourceEntries: entries),
      ),
    );
    _safeNotifyListeners();
  }

  void _createReviewTaskForCurrentDocument() async {
    // 中文注释: 当前文档一键审稿统一先创建 review 任务，再切到任务中心等待用户执行。
    // 失败分支此前写到 _refreshReviewCenter——但 ReviewCenter 视图已废弃、无 widget 渲染，
    // 用户点审稿失败会零反馈。失败现在改走 _announce（工作台状态条可见），与保存按钮一致。
    final project = _currentProject;
    if (project == null) {
      _announce('请先创建或打开项目，再审稿。');
      return;
    }
    final sourcePath = _viewModel.workbench.activeDocumentPath.trim();
    if (sourcePath.isEmpty) {
      _announce('请先打开一个需要审稿的正文或文档。');
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
      _viewModel = _viewModel.copyWith(
        destination: AppDestination.longTaskStation,
      );
      _safeNotifyListeners();
      return;
    }
    _announce(_resultMessage(result, success: '已创建审稿任务。'));
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
      'skill-loadouts': agents,
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

  ProjectSkillLoadoutWorkspaceViewData _buildProjectSkillLoadoutViewData() {
    return _projectSkillLoadoutViewDataService.build(
      projectAvailable: _currentProject != null,
      snapshot: _projectSkillLoadoutWorkspaceSnapshot,
      agents: _agentEcosystemSnapshot.agents,
      skills: _agentEcosystemSnapshot.skills,
      skillGroups: _agentEcosystemSnapshot.skillGroups,
      selectedAgentId: _selectedProjectSkillLoadoutAgentId(),
      statusMessage: _agentEcosystemStatusMessage,
    );
  }

  String _selectedProjectSkillLoadoutAgentId() {
    final selectedAgentId = _agentEcosystemSnapshot.selectedEntryIdForTab(
      'skill-loadouts',
    );
    if (selectedAgentId.trim().isNotEmpty) {
      return selectedAgentId;
    }
    if (_agentEcosystemSnapshot.agents.isEmpty) {
      return '';
    }
    return _stringValue(_agentEcosystemSnapshot.agents.first['id']);
  }

  JsonMap? _agentDocumentById(String agentId) {
    final cleanAgentId = agentId.trim();
    for (final agent in _agentEcosystemSnapshot.agents) {
      if (_stringValue(agent['id']) == cleanAgentId) {
        return agent;
      }
    }
    return null;
  }

  ResolvedAgentSkillLoadout? _resolvedProjectSkillLoadoutForAgent(
    String agentId,
  ) {
    final agent = _agentDocumentById(agentId);
    if (agent == null) {
      return null;
    }
    final draft =
        _projectSkillLoadoutWorkspaceSnapshot.draftLoadouts[agentId] ??
        _projectSkillLoadoutWorkspaceSnapshot.savedLoadouts.firstWhere(
          (item) => item.agentId == agentId,
          orElse: () => AgentSkillLoadout(
            agentId: agentId,
            source: AgentSkillLoadoutSource.projectSelection,
          ),
        );
    return AgentSkillLoadoutResolverService().resolveAgentDocument(
      agent,
      loadout: draft,
      availableSkillGroups: _agentEcosystemSnapshot.skillGroups,
      availableSkillIds: _idsOf(_agentEcosystemSnapshot.skills),
    );
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
    _listenableState.dispose();
    _auxiliaryControllers.dispose();
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
    // 中文注释: 切换项目后只按照正式刷新 policy 处理当前可见页，壳层不再直接用 destination 确定业务刷新逻辑。
    await _reconcilePrimaryWorkspaceDestinationAfterProjectLoad();
    final intents = _projectBoundFeatureRefreshPolicy.resolveAfterProjectLoad(
      FeatureVisibilityState(
        destination: _viewModel.destination,
        projectPath: _currentProject?.rootPath ?? '',
        isProjectHydrationInProgress:
            _workbenchWorkspaceController.isProjectHydrationInProgress,
      ),
    );
    for (final intent in intents) {
      switch (intent.target) {
        case FeatureRefreshTarget.projectOpen:
          await _refreshProjectOpenView();
          break;
        case FeatureRefreshTarget.bookDeconstruction:
          await bookDeconstructionController.refresh();
          break;
        case FeatureRefreshTarget.projectAssets:
          await projectAssetsController.refresh();
          break;
        case FeatureRefreshTarget.longTaskStation:
          await _longTaskStationController.refresh();
          break;
        case FeatureRefreshTarget.taskCenter:
          await _refreshTaskCenter();
          break;
      }
    }
  }

  Future<void> _reconcilePrimaryWorkspaceDestinationAfterProjectLoad() async {
    final project = _currentProject;
    if (project == null) {
      return;
    }
    final currentDestination = _viewModel.destination;
    if (currentDestination != AppDestination.workbench &&
        currentDestination != AppDestination.projectOpen) {
      return;
    }
    if (_usesBookDeconstructionAsPrimaryWorkspace(project)) {
      await bookDeconstructionController.refresh();
      await _destinationController.showBookDeconstructionWorkbench();
      return;
    }
    if (_usesProjectAssetsAsPrimaryWorkspace(project)) {
      await projectAssetsController.refresh();
      await _destinationController.showProjectAssets();
    }
  }

  SettingsViewData _settingsViewDataFrom(
    AppSettings settings, {
    String? activeTabId,
    String? selectedProviderId,
  }) {
    // 中文注释: 设置页数据投影由控制器统一完成，避免展示层直接理解核心设置模型。
    final requestedActiveTabId = activeTabId ?? _viewModel.settings.activeTabId;
    final effectiveProviderId =
        selectedProviderId ?? _selectedProviderId(settings);
    final modelSettings = _modelSettingsOf(settings);
    final providerDirectoryOptions = _providerSettingsDirectoryService
        .providerOptions();
    final allModelOptions = _providerSettingsDirectoryService.allModelOptions();
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
            connectionValidationResult: _providerConnectionValidationResultFor(
              settings,
              provider,
              modelSettings,
            ),
            isSelected: provider.id == effectiveProviderId,
          ),
        )
        .toList(growable: false);
    final effectiveProviders = effectiveProviderId == '__new__'
        ? <ProviderEndpointViewData>[
            for (final provider in providers)
              ProviderEndpointViewData(
                id: provider.id,
                title: provider.title,
                protocol: provider.protocol,
                baseUrl: provider.baseUrl,
                rawApiKey: provider.rawApiKey,
                apiKeyState: provider.apiKeyState,
                description: provider.description,
                connectionValidationResult: provider.connectionValidationResult,
                isSelected: false,
              ),
            ProviderEndpointViewData(
              id: '__new__',
              title: '',
              protocol: 'openai_compatible',
              baseUrl: '',
              rawApiKey: '',
              apiKeyState: '未配置密钥',
              description: '',
              connectionValidationResult:
                  _providerConnectionValidationResults['__new__'] ??
                  ProviderConnectionValidationResultViewData.initial,
              isSelected: true,
            ),
          ]
        : providers;
    final providerConnectionValidationResult = effectiveProviderId == '__new__'
        ? _providerConnectionValidationResults[effectiveProviderId] ??
              ProviderConnectionValidationResultViewData.initial
        : _providerConnectionValidationResults[effectiveProviderId] ??
              providers
                  .where((entry) => entry.id == effectiveProviderId)
                  .map((entry) => entry.connectionValidationResult)
                  .firstOrNull ??
              ProviderConnectionValidationResultViewData.initial;
    return SettingsViewData(
      activeTabId:
          const [
            'interfaces',
            'models',
            'permissions',
            'tooling',
            'network',
            'context',
            'theme',
          ].contains(requestedActiveTabId)
          ? requestedActiveTabId
          : 'interfaces',
      tabs: const [
        SettingsTabViewData(id: 'interfaces', label: '接口'),
        SettingsTabViewData(id: 'models', label: '模型'),
        SettingsTabViewData(id: 'permissions', label: '权限'),
        SettingsTabViewData(id: 'tooling', label: '工具策略'),
        SettingsTabViewData(id: 'network', label: '网络'),
        SettingsTabViewData(id: 'context', label: '上下文'),
        SettingsTabViewData(id: 'theme', label: '主题'),
      ],
      providers: effectiveProviders,
      providerDirectoryOptions: providerDirectoryOptions,
      allModelOptions: allModelOptions,
      tabSections: _settingsSections(settings),
      providerConnectionValidationResult: providerConnectionValidationResult,
      defaultProviderId: settings.defaultProviderId,
      defaultModelId: settings.defaultModelId,
      modelSettings: modelSettings,
      modelEditor: _modelSettingsViewDataService.build(settings, modelSettings),
      defaultProjectPath: settings.defaultProjectPath,
      draftFallbackProtectionEnabled: settings.draftFallbackProtectionEnabled,
      permissionSettings: settings.permissionSettings,
      toolStrategySettings: _toolStrategySettingsView(settings),
      projectCreationExpressionConstraintDefaults:
          _projectCreationExpressionConstraintDefaultsViewDataService.build(
            settings,
          ),
      networkSettings: settings.networkSettings,
      contextSettings: settings.contextSettings,
      themeSettings: settings.themeSettings,
      themeViewData: _themeSettingsViewDataService.build(
        themeSettings: settings.themeSettings,
        activeThemeId: _activeThemeId,
      ),
      settingsRootPath: _settingsRootPath,
      settingsSearchRoots: _settingsSearchRoots,
      defaultProjectsRootPath: _defaultProjectsRootPath,
      isMobileProjectRootLocked: _isMobileProjectRootLocked,
      settingsAnnouncement: _settingsAnnouncement,
    );
  }

  ProviderConnectionValidationResultViewData
  _providerConnectionValidationResultFor(
    AppSettings settings,
    ProviderEndpointSettings provider,
    Map<String, Object?> modelSettings,
  ) {
    // 中文注释: 优先回放联网探测缓存（"测试连接"的真实结果）；没有缓存才回落到本地静态校验。
    // 否则用户点完测试连接后，详情页一直显示本地静态结果，联网探测结果永远不浮现。
    final cached = _providerConnectionValidationResults[provider.id];
    if (cached != null) {
      return cached;
    }
    final validation = _providerConnectionValidationService.validate(
      title: provider.title,
      protocol: provider.protocol,
      baseUrl: provider.baseUrl,
      apiKey: provider.apiKey,
      modelId: provider.modelId,
      apiMode: _stringValue(modelSettings['api_mode'], 'chat'),
    );
    return _toValidationViewData(validation);
  }

  ProviderConnectionValidationResultViewData _toValidationViewData(
    ProviderConnectionValidationResult result,
  ) {
    // 中文注释: 共享验证结果转成 UI 可消费的稳定视图对象，避免 widget 直接依赖 core service 返回类型。
    return ProviderConnectionValidationResultViewData(
      isSuccess: result.isSuccess,
      summary: result.summary,
      details: result.details,
      errors: result.errors,
      templateId: result.templateId,
      providerId: result.providerId,
      protocolId: result.protocolId,
      protocolMode: result.protocolKind?.id ?? result.protocolId,
      routeFamily: result.routeFamily,
      selectedRouteFamily: result.selectedRouteFamily,
      allowedRouteFamilies: result.allowedRouteFamilies,
      hideOptions: result.hideOptions,
      fallbackNotAllowed: result.fallbackNotAllowed,
      warnings: result.warnings,
      matchedTemplateId: result.matchedTemplateId,
      matchedTemplateLabel: result.matchedTemplateLabel,
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
    // 中文注释: announcement 是一次性瞬态：投影进视图后立即清空，避免后续 tab/provider 切换触发的
    // 重建把同一条消息当成新消息再次弹出（陈旧"已保存"横幅跟随用户到处跑）。
    // 重复保存会重新写入字段，因此连击保存同一条消息仍能再次弹出。
    _settingsAnnouncement = '';
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
    return <String, List<SettingsSectionViewData>>{
      'models': [
        SettingsSectionViewData(
          title: '默认推理入口',
          description: '这里反映当前 GUI / CLI 会读取的接口选择、模型 ID 与运行参数。',
          items: [
            SettingsItemViewData(label: '默认接口', value: providerLabel),
            SettingsItemViewData(label: '默认模型', value: modelLabel),
            SettingsItemViewData(
              label: '上下文窗口长度',
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
          description: '只在项目工作区内读写，不向移动端额外申请外部存储权限。',
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
          description: 'GUI 与 CLI 共用同一套核心调度与工具执行入口，界面只展示当前可感知的工作方式。',
          items: const [
            SettingsItemViewData(label: '文件访问', value: '工作区文件由应用统一读写'),
            SettingsItemViewData(label: '工具调度', value: '工具调用由应用统一协调后再进入工作区'),
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
          description: '模型网络入口来自接口配置；代理行为由网络设置统一控制。',
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
          description: '上下文装配、会话历史与草稿保护都走共享 core；这里展示当前启用的关键行为。',
          items: [
            SettingsItemViewData(
              label: '默认项目',
              value: settings.defaultProjectPath,
            ),
            SettingsItemViewData(
              label: '普通会话草稿保护',
              value: settings.draftFallbackProtectionEnabled
                  ? '已开启：仅暂存草稿，不直接写正式文件'
                  : '已关闭：不再自动暂存普通会话结果',
            ),
            SettingsItemViewData(
              label: '当前项目',
              value: currentProjectPath.trim().isEmpty
                  ? '未加载项目'
                  : currentProjectPath,
            ),
          ],
        ),
      ],
      'theme': [
        SettingsSectionViewData(
          title: '界面外观',
          description: '主题切换在应用层生效，但不改变 core 行为和项目数据。',
          items: [
            SettingsItemViewData(
              label: '当前主题',
              value: _themePreferenceResolver.labelOf(_activeThemeId),
            ),
            SettingsItemViewData(label: '主题来源', value: 'ThemeRegistry 内置主题'),
            SettingsItemViewData(label: '分栏风格', value: '直角面板 + 线性分割'),
            SettingsItemViewData(label: '窄屏入口', value: '会话栏额外暴露文档与设置入口'),
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
      _activeThemeId = _themeIdFromSettings(savedSettings);
      // 中文注释: 保存成功消息写入设置页瞬态反馈，使刷新后的 SettingsViewData 带上它供 SettingsHeader 显示。
      _settingsAnnouncement = successMessage;
      _refreshSettingsViewData(selectedProviderId: selectedProviderId);
      _viewModel = _viewModel.copyWith(
        workbench: _viewModel.workbench.copyWith(
          modelLabel: _defaultModelLabel(savedSettings),
          modelOptions: _modelSelectorOptions(savedSettings),
          groupSelector: _fallbackGroupSelector(savedSettings),
          inputCapabilityContext: _conversationInputCapabilityContext(
            savedSettings,
          ),
          toolPreviewMode: _toolPreviewModeOf(savedSettings),
        ),
      );
      _announce(successMessage);
    } catch (error) {
      // 中文注释: 写盘失败同样要在设置页可见，而不是只写进工作台状态条。
      _settingsAnnouncement = '保存设置失败：$error';
      _refreshSettingsViewData();
      _announce('保存设置失败：$error');
    }
  }

  Future<void> _saveSettingsSilently(AppSettings nextSettings) async {
    // 中文注释: 工作台记忆这类背景状态更新不应打断用户，因此单独走静默保存链。
    try {
      final savedSettings = await _settingsRepository.save(nextSettings);
      _settings = savedSettings;
      _activeThemeId = _themeIdFromSettings(savedSettings);
      _refreshSettingsViewData();
      _viewModel = _viewModel.copyWith(
        workbench: _viewModel.workbench.copyWith(
          modelLabel: _defaultModelLabel(savedSettings),
          modelOptions: _modelSelectorOptions(savedSettings),
          groupSelector: _fallbackGroupSelector(savedSettings),
          inputCapabilityContext: _conversationInputCapabilityContext(
            savedSettings,
          ),
          toolPreviewMode: _toolPreviewModeOf(savedSettings),
        ),
      );
    } catch (_) {
      // 中文注释: 记忆保存失败不影响主流程，因此这里静默吞掉。
    }
  }

  String _themeIdFromSettings(AppSettings settings) {
    // 中文注释: 主题偏好解析统一委派给解析器，壳层只读取当前应启用的主题 ID。
    return _themePreferenceResolver.resolveSelectedThemeId(
      settings.themeSettings,
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

  ConversationInputCapabilityContext _conversationInputCapabilityContext(
    AppSettings settings,
  ) {
    // 中文注释: 工作台输入能力事实源统一在壳层收口，避免侧栏自己去碰设置、模型元能力和智能体生态快照。
    final editor = _modelSettingsViewDataService.build(
      settings,
      _modelSettingsOf(settings),
    );
    final selectedAgent = _selectedAgentDocument(settings);
    final projection = _workbenchConversationRuntimeState
        .openingProjection
        ?.currentPrimaryAgentSummary;
    return _conversationInputCapabilityContextBuilderService.build(
      modelEditor: editor,
      hasActiveProject: _viewModel.workbench.projectPath.trim().isNotEmpty,
      hostSupportsAttachmentPicking: _hostSupportsAttachmentPicking(),
      collaborationSupportsReasoning:
          projection?.thinkingSupported ??
          _agentSupportsReasoning(selectedAgent),
      collaborationSupportsAttachments: true,
      collaborationSupportsToolOptions: true,
      productExposesReasoningToggle: true,
      // 中文注释: 会话附件协议桥尚未完成，产品入口必须保持关闭，避免用户能选附件却发不出去。
      productExposesAttachmentEntry: false,
      productExposesStopAction: true,
      productExposesToolOptionsAction: false,
      productExposesOptimizeAction: false,
    );
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

  JsonMap _workbenchUiSettingsOf(AppSettings settings) {
    // 中文注释: 工作台 UI 偏好单独收口到 extraSettings.workbench_ui，避免散落在无关设置段里。
    return _mapValue(settings.extraSettings['workbench_ui']);
  }

  String _toolPreviewModeOf(AppSettings settings) {
    return ToolPreviewMode.normalize(
      _workbenchUiSettingsOf(settings)['tool_preview_mode'],
    );
  }

  Map<String, Object?> _toolStrategySettingsView(AppSettings settings) {
    return <String, Object?>{
      ...settings.toolStrategySettings,
      'tool_preview_mode': _toolPreviewModeOf(settings),
    };
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
    // 中文标题 slug 会退化成 interface，再叠时间戳避免多个「新接口」撞 id。
    final baseId = _slugFromTitle(title);
    final existingIds = providers
        .map((provider) => provider.id.trim().toLowerCase())
        .where((id) => id.isNotEmpty)
        .toSet();
    var candidate = baseId;
    if (baseId == 'interface' || existingIds.contains(baseId.toLowerCase())) {
      final stamp = DateTime.now().millisecondsSinceEpoch
          .toRadixString(36)
          .toLowerCase();
      candidate = baseId == 'interface' ? 'interface_$stamp' : '${baseId}_$stamp';
    }
    if (!existingIds.contains(candidate.toLowerCase())) {
      return candidate;
    }
    var suffix = 1;
    while (existingIds.contains('${candidate}_$suffix'.toLowerCase())) {
      suffix += 1;
    }
    return '${candidate}_$suffix';
  }

  String _slugFromTitle(String title) {
    // 中文注释: 标题转内部 ID 时只保留稳定的英文数字和下划线，空结果则退回 interface。
    var result = title.trim().toLowerCase();
    result = result.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    result = result.replaceAll(RegExp(r'_+'), '_');
    result = result.replaceAll(RegExp(r'^_+|_+$'), '');
    return result.isEmpty ? 'interface' : result;
  }

  String _fallbackPrimaryAgentLabel(AppSettings settings) {
    // 中文注释: 当项目还没有解析出默认智能体组时，主智能体标签先回退到设置里的默认智能体名称。
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

  ConversationGroupSelectorViewData _fallbackGroupSelector(
    AppSettings settings,
  ) {
    // 中文注释: 会话栏在 opening projection 尚未可用时先展示稳定回退值，避免出现空白或旧单智能体选择器。
    return _conversationGroupSelectorViewDataService.build(
      openingProjection: _workbenchConversationRuntimeState.openingProjection,
      fallbackPrimaryAgentLabel: _fallbackPrimaryAgentLabel(settings),
    );
  }

  ProjectAgentGroupWorkspaceViewData? _projectAgentGroupWorkspaceViewData() {
    // 中文注释: 项目级组配置浮层只在当前项目已打开且 opening projection 已就绪时暴露正式配置数据。
    if (_currentProject == null) {
      return null;
    }
    final projection = _workbenchConversationRuntimeState.openingProjection;
    if (projection == null) {
      return null;
    }
    return _projectAgentGroupWorkspaceViewDataService.build(
      projection: projection,
    );
  }

  Future<ProjectAgentGroupWorkspaceViewData?>
  _selectProjectAgentGroupFromWorkspace(String groupId) async {
    // 中文注释: 项目面板发起的组切换统一回到会话控制器执行，再把最新 projection 重新投影回正式配置浮层。
    await _workbenchConversationController.selectProjectAgentGroup(groupId);
    return _projectAgentGroupWorkspaceViewData();
  }

  JsonMap _selectedAgentDocument(AppSettings settings) {
    // 中文注释: 当前主智能体文档统一从已加载生态里解析，找不到时退回默认全能智能体兜底。
    final selectedAgentId = settings.defaultAgentId.trim();
    if (selectedAgentId.isEmpty || selectedAgentId == 'default_generalist') {
      return AgentProfileCatalogService().fallbackDefaultAgent();
    }
    for (final agent in _agentEcosystemSnapshot.agents) {
      if (_stringValue(agent['id']) == selectedAgentId) {
        return _mapValue(agent);
      }
    }
    return AgentProfileCatalogService().fallbackDefaultAgent();
  }

  bool _agentSupportsReasoning(JsonMap agent) {
    // 中文注释: 协作能力目前先消费智能体自身是否允许思考，后续 group-first 会在这里接主成员/组级策略。
    return !agent.containsKey('thinking_supported') ||
        _boolValue(agent['thinking_supported']);
  }

  bool _hostSupportsAttachmentPicking() {
    // 中文注释: 当前附件选择只为未来桌面端预留宿主事实源，移动端和 Web 继续保持关闭。
    if (kIsWeb) {
      return false;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return true;
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        return false;
    }
  }

  void _announce(String message) {
    // 中文注释: 轻量提示只更新状态文案，不重新整套重算 opening / 会话投影，避免提示链路反向触发递归刷新。
    _updateWorkbench(_viewModel.workbench.copyWith(generationStatus: message));
  }

  void _announceSettings(String message) {
    // 中文注释: 设置页反馈单独走这条通道：写入瞬态字段并刷新设置视图，让 SettingsHeader 能看到
    // 保存成功/校验失败——_announce 写的是工作台状态条，设置页看不到。
    final settings = _settings;
    if (settings == null) {
      return;
    }
    _settingsAnnouncement = message;
    _refreshSettingsViewData();
  }

  JsonMap _contextStrategySettingsOf(AppSettings settings) {
    // 中文注释: 控制器只负责收集上下文策略配置，不解释具体策略含义。
    return _contextSettingsContractService.runtimeStrategySettings(
      settings.contextSettings,
    );
  }

  void _changeDestination(AppDestination destination) {
    // 中文注释: 壳层自己只保留全局路由切换，不把任何 feature 状态偷偷绑在目的地切换里。
    _viewModel = _viewModel.copyWith(destination: destination);
    _longTaskStationController.setAutoRefreshEnabled(
      destination == AppDestination.longTaskStation,
    );
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
    _listenableState.syncFrom(
      viewModel: _viewModel,
      activeThemeId: _activeThemeId,
    );
    _controllerNotifyTraceService?.record(
      controllerName: 'AppShellController',
      reason: '_safeNotifyListeners',
      destination: _viewModel.destination.name,
      projectPath: _currentProject?.rootPath ?? '',
    );
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
