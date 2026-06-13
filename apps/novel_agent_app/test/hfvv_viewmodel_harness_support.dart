import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_app/app/state/app_shell_controller.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/book_deconstruction_narrative_persistence_service.dart';
import 'package:novel_agent_app/features/long_task_station/application/controllers/long_task_station_controller.dart';
import 'package:novel_agent_app/features/project_assets/application/services/project_expression_constraint_workspace_service.dart';
import 'package:novel_agent_app/features/project_assets/application/services/project_reference_extraction_execution_service.dart';
import 'package:novel_agent_app/features/workbench/application/controllers/generate_draft_use_case_factory.dart';
import 'package:novel_agent_app/features/workbench/application/models/conversation_tool_lifecycle_status.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_entry_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/project_create_request_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/project_creation_phase.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_conversation_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_resource_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_view_data.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

const String hfvvRunId = '2026-06-10T01-35-42';
const String hfvv02LaneId = 'hfvv_02_viewmodel_harness_smoke';

class HfvvAppShellHarness {
  HfvvAppShellHarness._({
    required this.controller,
    required this.bundle,
    required this.generateDraftUseCase,
    required this.artifactRoot,
    required this.workspaceRoot,
    required this.repoRoot,
  });

  final AppShellController controller;
  final AdapterBundle bundle;
  final ScriptedGenerateDraftUseCase generateDraftUseCase;
  final Directory artifactRoot;
  final Directory workspaceRoot;
  final Directory repoRoot;

  static Future<HfvvAppShellHarness> create({
    required ScriptedGenerateDraftUseCase generateDraftUseCase,
    ProjectReferenceExtractionExecutionService?
    projectReferenceExtractionExecutionService,
    ProjectWorkflowRuntimeService Function({
      required AdapterBundle bundle,
      required GenerateDraftUseCaseFactory generateDraftUseCaseFactory,
      required ProjectTaskRepository projectTaskRepository,
      required ProjectPromptTemplateService promptTemplateService,
    })?
    workflowRuntimeServiceFactory,
  }) async {
    final repoRoot = _resolveRepoRoot();
    final artifactRoot = Directory(
      '${repoRoot.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}high_fidelity_viewmodel_validation${Platform.pathSeparator}$hfvvRunId${Platform.pathSeparator}hfvv_02',
    );
    final workspaceRoot = Directory(
      '${artifactRoot.path}${Platform.pathSeparator}$hfvv02LaneId',
    );
    if (workspaceRoot.existsSync()) {
      workspaceRoot.deleteSync(recursive: true);
    }
    workspaceRoot.createSync(recursive: true);
    artifactRoot.createSync(recursive: true);

    final settingsRoot = Directory(
      '${workspaceRoot.path}${Platform.pathSeparator}settings',
    )..createSync(recursive: true);
    final projectsRoot = Directory(
      '${workspaceRoot.path}${Platform.pathSeparator}projects',
    )..createSync(recursive: true);

    final bundle = AdapterBundle.standard(
      workingDirectoryPath: repoRoot.path,
      settingsRootPath: settingsRoot.path,
      defaultProjectRootPath: projectsRoot.path,
      environment: const <String, String>{},
    );
    await bundle.settingsRepository.save(_seedSettings());
    final controller = _buildController(
      bundle: bundle,
      generateDraftUseCaseFactory: (_, __) => generateDraftUseCase,
      projectReferenceExtractionExecutionService:
          projectReferenceExtractionExecutionService,
      workflowRuntimeServiceFactory: workflowRuntimeServiceFactory,
    );
    final harness = HfvvAppShellHarness._(
      controller: controller,
      bundle: bundle,
      generateDraftUseCase: generateDraftUseCase,
      artifactRoot: artifactRoot,
      workspaceRoot: workspaceRoot,
      repoRoot: repoRoot,
    );
    await harness.initialize();
    return harness;
  }

  WorkbenchViewData get workbench => controller.workbenchPageListenable.value;
  WorkbenchConversationViewData get conversation =>
      controller.workbenchConversationListenable.value;
  WorkbenchResourceViewData get resources =>
      controller.workbenchResourceListenable.value;

  Future<void> initialize() async {
    await controller.initialize();
    await controller.longTaskStationController.initialize();
  }

  Future<void> createProject({
    required String title,
    String projectTypeId = 'novel',
    String storageStrategyId = 'markdown_project_store',
  }) async {
    controller.onCreateProjectRequested();
    await waitUntil(
      () =>
          workbench.projectLauncher?.creationPhase ==
          ProjectCreationPhase.projectType,
      description: 'project type phase',
    );
    final request = ProjectCreateRequestViewData(
      title: title,
      projectTypeId: projectTypeId,
      storageStrategyId: storageStrategyId,
    );
    controller.onProjectCreationSubmitted(request);
    await waitUntil(
      () =>
          workbench.projectLauncher?.creationPhase ==
          ProjectCreationPhase.storageStrategy,
      description: 'storage strategy phase',
    );
    controller.onProjectCreationSubmitted(request);
    await waitUntil(
      () => workbench.projectPath.trim().isNotEmpty,
      description: 'project path after creation',
      timeout: const Duration(seconds: 15),
    );
    await waitUntil(
      () => !workbench.generationStatus.contains('正在加载项目'),
      description: 'project load to settle',
    );
  }

  Future<void> sendPrompt(String text) async {
    controller.onSendRequested(text);
    await generateDraftUseCase.pendingProgressSeen.future;
  }

  Future<void> releasePromptCompletion() async {
    generateDraftUseCase.releaseResult();
    await waitUntil(
      () => !conversation.isGenerating,
      description: 'conversation generation complete',
      timeout: const Duration(seconds: 15),
    );
  }

  Future<void> waitUntil(
    bool Function() predicate, {
    required String description,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (predicate()) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    throw TimeoutException('Timed out waiting for $description.');
  }

  Future<void> recordStep({
    required String stepId,
    required String label,
    JsonMap modelEvent = const <String, Object?>{},
    List<Object?> toolEvents = const <Object?>[],
  }) async {
    await _writeJson(
      '${stepId}_viewmodel.json',
      await snapshot(stepId: stepId, label: label),
    );
    await _writeJson('${stepId}_model_event.json', modelEvent);
    await _writeJson('${stepId}_tool_events.json', <String, Object?>{
      'events': toolEvents,
    });
  }

  Future<void> writeSummary(JsonMap document) async {
    await _writeJson('hfvv_02_smoke_summary.json', document);
  }

  Future<JsonMap> snapshot({
    required String stepId,
    required String label,
  }) async {
    final projectEntries = await _projectEntries();
    final runningTools = _toolEntriesByStatus(
      conversation.conversationEntries,
      ConversationToolLifecycleStatus.running,
    );
    final completedTools = _toolEntriesByStatus(
      conversation.conversationEntries,
      ConversationToolLifecycleStatus.completed,
    );
    final failedTools = _toolEntriesByStatus(
      conversation.conversationEntries,
      ConversationToolLifecycleStatus.failed,
    );
    final pendingConfirmationTools = _toolEntriesByStatus(
      conversation.conversationEntries,
      ConversationToolLifecycleStatus.pendingConfirmation,
    );
    final longTaskView = controller.longTaskStationController.viewData;
    return <String, Object?>{
      'step_id': stepId,
      'label': label,
      'captured_at': DateTime.now().toIso8601String(),
      'workspace_relative_project_path': _relativeToWorkspace(
        workbench.projectPath,
      ),
      'workbench': <String, Object?>{
        'project_name': workbench.projectName,
        'project_subtitle': workbench.projectSubtitle,
        'generation_status': workbench.generationStatus,
        'tool_core_status': workbench.toolCoreStatus,
        'is_generating': workbench.isGenerating,
        'context_summary': workbench.contextSummary,
        'active_document_path': workbench.activeDocumentPath,
        'resource_entry_count': workbench.resourceEntries.length,
        'pending_option_count': workbench.pendingOptions.length,
      },
      'conversation': <String, Object?>{
        'generation_status': conversation.generationStatus,
        'tool_core_status': conversation.toolCoreStatus,
        'is_generating': conversation.isGenerating,
        'entry_count': conversation.conversationEntries.length,
        'entries': conversation.conversationEntries
            .map(_conversationEntryToJson)
            .toList(growable: false),
        'pending_options': conversation.pendingOptions
            .map(
              (option) => <String, Object?>{
                'label': option.label,
                'description': option.description,
                'prompt': option.prompt,
                'source_question': option.sourceQuestion,
              },
            )
            .toList(growable: false),
      },
      'resource_view': <String, Object?>{
        'project_name': resources.projectName,
        'project_subtitle': resources.projectSubtitle,
        'entries': resources.resourceEntries
            .map(
              (entry) => <String, Object?>{
                'title': entry.title,
                'relative_path': entry.relativePath,
                'is_directory': entry.isDirectory,
                'is_selected': entry.isSelected,
                'has_children': entry.hasChildren,
              },
            )
            .toList(growable: false),
        'information_summary': resources.informationViewData.summary,
        'information_usage_summary': resources.informationViewData.usageSummary,
        'information_pending_count':
            resources.informationViewData.pendingEntries.length,
      },
      'long_task_station': <String, Object?>{
        'status_message': longTaskView.statusMessage,
        'supervisor_status_label': longTaskView.supervisorStatusLabel,
        'total_count': longTaskView.totalCount,
        'active_count': longTaskView.activeCount,
        'attention_count': longTaskView.attentionCount,
        'run_count': longTaskView.runs.length,
      },
      'project_files': projectEntries,
      'derived_statuses': <String, Object?>{
        'running_tools': runningTools,
        'completed_tools': completedTools,
        'failed_tools': failedTools,
        'pending_confirmation_tools': pendingConfirmationTools,
        'waiting_user':
            conversation.pendingOptions.isNotEmpty ||
            pendingConfirmationTools.isNotEmpty,
      },
    };
  }

  Future<List<JsonMap>> _projectEntries() async {
    final projectPath = workbench.projectPath.trim();
    if (projectPath.isEmpty) {
      return const <JsonMap>[];
    }
    final entries = await bundle.projectWorkspacePort.listEntries(projectPath);
    return entries
        .map(ValueReaders.mapValue)
        .map(
          (entry) => <String, Object?>{
            'relative_path': ValueReaders.stringValue(entry['relative_path']),
            'is_dir': ValueReaders.boolValue(entry['is_dir']),
          },
        )
        .toList(growable: false);
  }

  Future<void> _writeJson(String fileName, Object? payload) async {
    final file = File('${artifactRoot.path}${Platform.pathSeparator}$fileName');
    await file.parent.create(recursive: true);
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString('${encoder.convert(payload)}\n');
  }

  static Directory _resolveRepoRoot() {
    final candidate = Directory.current.parent.parent;
    return candidate;
  }

  static AppSettings _seedSettings() {
    return const AppSettings(
      defaultProviderId: 'hfvv-provider',
      defaultAgentId: 'default_generalist',
      defaultModelId: 'hfvv-fake-model',
      defaultProjectPath: 'missing_hfvv_project',
      autoSaveDrafts: true,
      providers: <ProviderEndpointSettings>[
        ProviderEndpointSettings(
          id: 'hfvv-provider',
          title: 'HFVV Fake Provider',
          protocol: 'openai_compatible',
          baseUrl: 'https://hfvv.invalid/v1',
          apiKey: '__hfvv_fake__',
          modelId: 'hfvv-fake-model',
          description: 'HFVV fake provider for viewmodel harness smoke test.',
          isDefault: true,
        ),
      ],
    );
  }

  static AppShellController _buildController({
    required AdapterBundle bundle,
    required GenerateDraftUseCaseFactory generateDraftUseCaseFactory,
    ProjectReferenceExtractionExecutionService?
    projectReferenceExtractionExecutionService,
    ProjectWorkflowRuntimeService Function({
      required AdapterBundle bundle,
      required GenerateDraftUseCaseFactory generateDraftUseCaseFactory,
      required ProjectTaskRepository projectTaskRepository,
      required ProjectPromptTemplateService promptTemplateService,
    })?
    workflowRuntimeServiceFactory,
  }) {
    final contextAssemblerService = ContextAssemblerService(
      budgetService: ContextBudgetService(),
      staticSectionService: ContextStaticSectionService(
        projectPromptContract: ProjectPromptContract(),
      ),
      projectFileSectionService: ContextProjectFileSectionService(),
    );
    final writeProjectTextFileUseCase = WriteProjectTextFileUseCase(
      projectWorkspacePort: bundle.projectWorkspacePort,
    );
    final modeGuidanceRepository = ProjectModeGuidanceRepository(
      workspacePort: bundle.projectWorkspacePort,
    );
    final generateCustomizationIndexesUseCase =
        GenerateCustomizationIndexesUseCase(
          writeProjectTextFileUseCase: writeProjectTextFileUseCase,
        );
    final projectAgentSkillLoadoutRepository =
        ProjectAgentSkillLoadoutRepository(
          workspacePort: bundle.projectWorkspacePort,
        );
    final projectAgentSkillLoadoutHistoryRepository =
        ProjectAgentSkillLoadoutHistoryRepository(
          workspacePort: bundle.projectWorkspacePort,
        );
    final expressionConstraintProfileRepository =
        ExpressionConstraintProfileRepository(
          workspacePort: bundle.projectWorkspacePort,
        );
    final projectExpressionConstraintBindingRepository =
        ProjectExpressionConstraintBindingRepository(
          workspacePort: bundle.projectWorkspacePort,
        );
    final projectExpressionConstraintWorkspaceService =
        ProjectExpressionConstraintWorkspaceService(
          loadProfiles: (project) => expressionConstraintProfileRepository
              .loadProfiles(project, includeBuiltins: true),
          loadBindings:
              projectExpressionConstraintBindingRepository.loadBindings,
          saveBindings:
              projectExpressionConstraintBindingRepository.saveBindings,
        );
    final draftExecutionConstraintRuntimeService =
        ProjectDraftExecutionConstraintRuntimeService(
          expressionConstraintProfileRepository:
              expressionConstraintProfileRepository,
          projectExpressionConstraintBindingRepository:
              projectExpressionConstraintBindingRepository,
          constraintBindingRepository: LocalConstraintBindingRepository(
            workspacePort: bundle.projectWorkspacePort,
          ),
        );
    final projectSkillLoadoutSaveAsGroupService =
        ProjectSkillLoadoutSaveAsGroupService(
          workspacePort: bundle.projectWorkspacePort,
        );
    final projectTaskRepository = ProjectTaskRepository(
      workspacePort: bundle.projectWorkspacePort,
    );
    final promptTemplateService = ProjectPromptTemplateService(
      workspacePort: bundle.projectWorkspacePort,
    );
    final projectAssetLibraryService = ProjectAssetLibraryService(
      workspacePort: bundle.projectWorkspacePort,
      projectToolHostPort: bundle.projectToolHostPort,
    );
    final projectGeneralContinuitySetupService =
        ProjectGeneralContinuitySetupService(
          continuityRepository: ProjectContinuityRepository(
            workspacePort: bundle.projectWorkspacePort,
          ),
          inputRepository: ProjectContinuityInputRepository(
            workspacePort: bundle.projectWorkspacePort,
          ),
        );
    final projectTimelineRepository = ProjectTimelineRepository(
      hostPort: bundle.projectToolHostPort,
    );
    final projectRelationshipRepository = ProjectRelationshipRepository(
      hostPort: bundle.projectToolHostPort,
    );
    final projectChapterRewriteTaskService = ProjectChapterRewriteTaskService(
      taskRepository: projectTaskRepository,
    );
    final reviewReportService = ProjectReviewReportService(
      workspacePort: bundle.projectWorkspacePort,
      taskRepository: projectTaskRepository,
    );
    final longTaskStationDetailService = ProjectLongTaskStationDetailService(
      taskRepository: projectTaskRepository,
      reviewReportService: reviewReportService,
    );
    final workflowRuntimeService =
        workflowRuntimeServiceFactory?.call(
          bundle: bundle,
          generateDraftUseCaseFactory: generateDraftUseCaseFactory,
          projectTaskRepository: projectTaskRepository,
          promptTemplateService: promptTemplateService,
        ) ??
        ProjectWorkflowRuntimeService(
          taskRepository: projectTaskRepository,
          promptTemplateService: promptTemplateService,
          generateDraftUseCaseFactory: generateDraftUseCaseFactory,
          longTaskSupervisor: bundle.longTaskSupervisor,
        );
    final conversationDraftRuntimeService =
        ProjectConversationDraftRuntimeService(
          workspacePort: bundle.projectWorkspacePort,
          hostPort: bundle.projectToolHostPort,
        );
    final referenceExtractionRuntimeService =
        ProjectReferenceExtractionRuntimeService(
          workspacePort: bundle.projectWorkspacePort,
          loadAvailableAgents: (project) =>
              bundle.agentPackageCatalog.loadAgentPackages(project),
          loadAvailableGroups: (project) =>
              bundle.agentGroupCatalog.loadAgentGroups(project),
          groupBindingRepository: bundle.projectAgentGroupBindingRepository,
        );
    final longTaskStationController = LongTaskStationController(
      longTaskSupervisor: bundle.longTaskSupervisor,
      detailService: longTaskStationDetailService,
    );
    return AppShellController(
      settingsRepository: bundle.settingsRepository,
      loadProjectWorkspaceUseCase: LoadProjectWorkspaceUseCase(
        projectRepository: bundle.projectRepository,
        projectWorkspacePort: bundle.projectWorkspacePort,
      ),
      loadModeGuidanceStateUseCase: LoadModeGuidanceStateUseCase(
        statePort: modeGuidanceRepository,
      ),
      answerModeGuidanceStageUseCase: AnswerModeGuidanceStageUseCase(
        statePort: modeGuidanceRepository,
      ),
      buildModeGuidancePlanInputUseCase: BuildModeGuidancePlanInputUseCase(
        statePort: modeGuidanceRepository,
      ),
      readProjectFileUseCase: ReadProjectFileUseCase(
        bundle.projectWorkspacePort,
      ),
      saveDraftUseCase: SaveDraftUseCase(
        projectWorkspacePort: bundle.projectWorkspacePort,
      ),
      createProjectWorkspaceUseCase: CreateProjectWorkspaceUseCase(
        projectRepository: bundle.projectRepository,
        projectWorkspacePort: bundle.projectWorkspacePort,
        projectContentRepository: bundle.projectContentRepository,
        projectReadableProjectionService:
            bundle.projectReadableProjectionService,
      ),
      createProjectEntryUseCase: CreateProjectEntryUseCase(
        projectToolHostPort: bundle.projectToolHostPort,
      ),
      importProjectFilesUseCase: ImportProjectFilesUseCase(
        projectToolHostPort: bundle.projectToolHostPort,
      ),
      updateProjectManifestUseCase: UpdateProjectManifestUseCase(
        writeProjectTextFileUseCase: writeProjectTextFileUseCase,
      ),
      projectToolHostPort: bundle.projectToolHostPort,
      bookDeconstructionNarrativePersistenceService:
          BookDeconstructionNarrativePersistenceService(
            workspacePort: bundle.projectWorkspacePort,
          ),
      projectRuntimeProfileRepository: ProjectRuntimeProfileRepository(
        workspacePort: bundle.projectWorkspacePort,
      ),
      projectAgentGroupBindingRepository:
          bundle.projectAgentGroupBindingRepository,
      previewCustomizationBundleImportUseCase:
          PreviewCustomizationBundleImportUseCase(),
      importCustomizationBundleUseCase: ImportCustomizationBundleUseCase(
        projectToolHostPort: bundle.projectToolHostPort,
        generateCustomizationIndexesUseCase:
            generateCustomizationIndexesUseCase,
      ),
      generateCustomizationIndexesUseCase: generateCustomizationIndexesUseCase,
      saveCustomizationMarketIndexUseCase: SaveCustomizationMarketIndexUseCase(
        projectToolHostPort: bundle.projectToolHostPort,
        writeProjectTextFileUseCase: writeProjectTextFileUseCase,
      ),
      settingsRootPath: bundle.settingsRootPath,
      settingsSearchRoots: bundle.settingsSearchRoots,
      defaultProjectsRootPath: bundle.defaultProjectRootPath,
      isMobileProjectRootLocked: false,
      loadAgentPackages: (project) =>
          bundle.agentPackageCatalog.loadAgentPackages(project),
      loadAgentGroups: (project) =>
          bundle.agentGroupCatalog.loadAgentGroups(project),
      loadSkillPackages: (project) =>
          bundle.skillPackageCatalog.loadSkillPackages(project),
      loadSkillGroups: (project) =>
          bundle.skillGroupCatalog.loadSkillGroups(project),
      loadProjectSkillLoadouts: (project) =>
          projectAgentSkillLoadoutRepository.loadLoadouts(project),
      saveProjectSkillLoadouts: (project, loadouts) =>
          projectAgentSkillLoadoutRepository.saveLoadouts(project, loadouts),
      loadProjectSkillLoadoutHistory: (project) =>
          projectAgentSkillLoadoutHistoryRepository.listEntries(project),
      saveProjectSkillLoadoutHistoryEntry: (project, entry) =>
          projectAgentSkillLoadoutHistoryRepository.saveEntry(project, entry),
      saveProjectSkillLoadoutAsGroup:
          ({
            required project,
            required loadout,
            required groupId,
            required displayName,
            required description,
          }) => projectSkillLoadoutSaveAsGroupService.saveAsGroup(
            project: project,
            loadout: loadout,
            groupId: groupId,
            displayName: displayName,
            description: description,
          ),
      writeProjectTextFileUseCase: writeProjectTextFileUseCase,
      llmGatewayFactory: (provider, networkSettings) =>
          bundle.createGateway(provider, networkSettings: networkSettings),
      draftExecutionConstraintRuntimeService:
          draftExecutionConstraintRuntimeService,
      workflowRuntimeService: workflowRuntimeService,
      referenceExtractionRuntimeService: referenceExtractionRuntimeService,
      projectReferenceExtractionExecutionService:
          projectReferenceExtractionExecutionService,
      conversationDraftRuntimeService: conversationDraftRuntimeService,
      reviewReportService: reviewReportService,
      projectChapterRewriteTaskService: projectChapterRewriteTaskService,
      promptTemplateService: promptTemplateService,
      projectAssetLibraryService: projectAssetLibraryService,
      projectTimelineRepository: projectTimelineRepository,
      projectRelationshipRepository: projectRelationshipRepository,
      projectExpressionConstraintWorkspaceService:
          projectExpressionConstraintWorkspaceService,
      projectGeneralContinuitySetupService:
          projectGeneralContinuitySetupService,
      longTaskSupervisor: bundle.longTaskSupervisor,
      longTaskStationController: longTaskStationController,
      generateDraftUseCaseFactory: generateDraftUseCaseFactory,
    );
  }

  static JsonMap _conversationEntryToJson(ConversationEntryViewData entry) {
    return <String, Object?>{
      'id': entry.id,
      'kind': entry.kind.name,
      'title': entry.title,
      'body': entry.body,
      'is_error': entry.isError,
      'is_retryable_failure': entry.isRetryableFailure,
      'tool_lifecycle_status': entry.toolLifecycleStatus?.name ?? '',
      'detail_title': entry.detailTitle,
      'detail_summary': entry.detailSummary,
      'detail_body': entry.detailBody,
      'detail_expanded_by_default': entry.detailExpandedByDefault,
    };
  }

  static List<String> _toolEntriesByStatus(
    List<ConversationEntryViewData> entries,
    ConversationToolLifecycleStatus status,
  ) {
    return entries
        .where((entry) => entry.toolLifecycleStatus == status)
        .map((entry) => entry.title)
        .toList(growable: false);
  }

  String _relativeToWorkspace(String absolutePath) {
    final normalizedPath = absolutePath.replaceAll('\\', '/');
    final normalizedRoot = workspaceRoot.path.replaceAll('\\', '/');
    if (normalizedPath.startsWith(normalizedRoot)) {
      var relative = normalizedPath.substring(normalizedRoot.length);
      if (relative.startsWith('/')) {
        relative = relative.substring(1);
      }
      return relative;
    }
    return normalizedPath.split('/').last;
  }
}

class ScriptedGenerateDraftUseCase extends GenerateDraftUseCase {
  ScriptedGenerateDraftUseCase({
    required this.resultBuilder,
    List<DraftGenerationProgress> progressFrames =
        const <DraftGenerationProgress>[],
  }) : _progressFrames = List<DraftGenerationProgress>.unmodifiable(
         progressFrames,
       ),
       super(
         projectWorkspacePort: _NoopProjectWorkspacePort(),
         llmGateway: _NoopLlmGateway(),
         toolExecutionPort: _NoopToolExecutionPort(),
         contextAssemblerService: ContextAssemblerService(
           budgetService: ContextBudgetService(),
           staticSectionService: ContextStaticSectionService(
             projectPromptContract: ProjectPromptContract(),
           ),
           projectFileSectionService: ContextProjectFileSectionService(),
         ),
         projectPromptContract: ProjectPromptContract(),
       );

  final DraftGenerationResult Function({
    required ProjectDescriptor project,
    required String userPrompt,
    required String modelId,
  })
  resultBuilder;
  final List<DraftGenerationProgress> _progressFrames;

  final Completer<void> pendingProgressSeen = Completer<void>();
  final Completer<void> _allowResult = Completer<void>();
  final List<DraftGenerationProgress> emittedProgress =
      <DraftGenerationProgress>[];
  DraftGenerationResult? lastResult;
  String lastUserPrompt = '';
  String lastModelId = '';
  JsonMap lastAgent = const <String, Object?>{};
  JsonMap lastSelectedCollaborationGroup = const <String, Object?>{};

  void releaseResult() {
    if (!_allowResult.isCompleted) {
      _allowResult.complete();
    }
  }

  @override
  Future<DraftGenerationResult> execute({
    required ProjectDescriptor project,
    required String userPrompt,
    required String modelId,
    String title = '',
    String intent = 'draft',
    JsonMap agent = const <String, Object?>{},
    JsonMap selectedCollaborationGroup = const <String, Object?>{},
    String sessionContext = '',
    JsonMap requestOptions = const <String, Object?>{},
    JsonMap contextSettings = const <String, Object?>{},
    JsonMap modelProfile = const <String, Object?>{},
    JsonMap skillRoutingContext = const <String, Object?>{},
    AppSettings? subAgentRuntimeSettings,
    List<ProjectAgentBinding> subAgentBindings = const <ProjectAgentBinding>[],
    String subAgentBindingModeId = '',
    String subAgentBindingStageId = '',
    List<String> exposedToolIds = const <String>[],
    List<Object?> memorySections = const <Object?>[],
    List<Object?> expressionConstraintProfiles = const <Object?>[],
    List<Object?> projectExpressionConstraintBindings = const <Object?>[],
    JsonMap writingExecutionConstraints = const <String, Object?>{},
    List<Object?> projectFileSectionPlan = const <Object?>[],
    JsonMap projectFileContents = const <String, Object?>{},
    String activeDocumentPath = '',
    String activeDocumentBody = '',
    DraftGenerationCancellationToken? cancellationToken,
    void Function(DraftGenerationProgress progress)? onProgress,
  }) async {
    lastUserPrompt = userPrompt;
    lastModelId = modelId;
    lastAgent = ValueReaders.deepCopyMap(agent);
    lastSelectedCollaborationGroup = ValueReaders.deepCopyMap(
      selectedCollaborationGroup,
    );
    for (final progress in _progressFrames) {
      emittedProgress.add(progress);
      onProgress?.call(progress);
    }
    if (_progressFrames.isNotEmpty && !pendingProgressSeen.isCompleted) {
      pendingProgressSeen.complete();
    }
    await _allowResult.future;
    final result = resultBuilder(
      project: project,
      userPrompt: userPrompt,
      modelId: modelId,
    );
    lastResult = result;
    return result;
  }
}

class _NoopProjectWorkspacePort implements ProjectWorkspacePort {
  @override
  Future<void> createDirectory(String rootPath, String relativePath) async {}

  @override
  Future<List<JsonMap>> listEntries(
    String rootPath, {
    bool recursive = true,
  }) async => const <JsonMap>[];

  @override
  Future<String?> readTextFile(String rootPath, String relativePath) async =>
      null;

  @override
  Future<void> writeTextFile(
    String rootPath,
    String relativePath,
    String content,
  ) async {}
}

class _NoopToolExecutionPort implements ToolExecutionPort {
  @override
  Future<JsonMap> execute({
    required ProjectDescriptor project,
    required JsonMap toolCall,
  }) async => <String, Object?>{'ok': false, 'error': 'noop'};
}

class _NoopLlmGateway implements LlmGateway {
  @override
  Future<JsonMap> requestChat({
    required ChatRequest request,
    DraftGenerationCancellationToken? cancellationToken,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) async => <String, Object?>{'content': 'noop'};

  @override
  Future<JsonMap> requestChatLegacy({
    required List<JsonMap> messages,
    required String modelId,
    List<JsonMap> tools = const <JsonMap>[],
    JsonMap options = const <String, Object?>{},
    List<ChatInputAttachment> attachments = const <ChatInputAttachment>[],
    DraftGenerationCancellationToken? cancellationToken,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) async => <String, Object?>{'content': 'noop'};

  @override
  Future<String> requestText({
    required String prompt,
    required String modelId,
  }) async => 'noop';
}
