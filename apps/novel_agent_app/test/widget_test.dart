import 'package:flutter/widgets.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novel_agent_app/app/app.dart';
import 'package:novel_agent_app/app/state/app_shell_controller.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/book_deconstruction_narrative_persistence_service.dart';
import 'package:novel_agent_app/features/long_task_station/application/controllers/long_task_station_controller.dart';
import 'package:novel_agent_app/features/project_assets/application/services/project_expression_constraint_workspace_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App shell renders workbench entry points', (
    WidgetTester tester,
  ) async {
    // 中文注释: 这里先验证新的应用壳能正常挂载，而不是继续沿用 Flutter 默认计数器测试。
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final bundle = AdapterBundle.standard();
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
    final workflowRuntimeService = ProjectWorkflowRuntimeService(
      taskRepository: projectTaskRepository,
      promptTemplateService: promptTemplateService,
      generateDraftUseCaseFactory: (provider, networkSettings) {
        return GenerateDraftUseCase(
          projectWorkspacePort: bundle.projectWorkspacePort,
          llmGateway: bundle.createGateway(
            provider,
            networkSettings: networkSettings,
          ),
          toolExecutionPort: bundle.projectToolExecutionPort,
          contextAssemblerService: contextAssemblerService,
          projectPromptContract: ProjectPromptContract(),
          hostPlatform: HostPlatform.windows,
          loadAvailableAgents: (project) =>
              bundle.agentPackageCatalog.loadAgentPackages(project),
          loadAvailableAgentGroups: (project) =>
              bundle.agentGroupCatalog.loadAgentGroups(project),
        );
      },
    );
    final conversationDraftRuntimeService =
        ProjectConversationDraftRuntimeService(
          workspacePort: bundle.projectWorkspacePort,
          hostPort: bundle.projectToolHostPort,
          taskRepository: projectTaskRepository,
        );
    final longTaskStationController = LongTaskStationController(
      longTaskSupervisor: bundle.longTaskSupervisor,
      detailService: longTaskStationDetailService,
    );
    final controller = AppShellController(
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
      draftExecutionConstraintRuntimeService:
          draftExecutionConstraintRuntimeService,
      workflowRuntimeService: workflowRuntimeService,
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
      generateDraftUseCaseFactory: (provider, networkSettings) {
        // 中文注释: widget 测试沿用真实装配，确保最小可用链路至少能在界面层成功挂载。
        return GenerateDraftUseCase(
          projectWorkspacePort: bundle.projectWorkspacePort,
          llmGateway: bundle.createGateway(
            provider,
            networkSettings: networkSettings,
          ),
          toolExecutionPort: bundle.projectToolExecutionPort,
          contextAssemblerService: contextAssemblerService,
          projectPromptContract: ProjectPromptContract(),
          hostPlatform: HostPlatform.windows,
          loadAvailableAgents: (project) =>
              bundle.agentPackageCatalog.loadAgentPackages(project),
          loadAvailableAgentGroups: (project) =>
              bundle.agentGroupCatalog.loadAgentGroups(project),
        );
      },
    );

    await tester.pumpWidget(NovelAgentApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.byType(WidgetsApp), findsOneWidget);
    expect(find.text('正文工作区'), findsOneWidget);
  });
}
