import 'package:flutter/widgets.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novel_agent_app/app/app.dart';
import 'package:novel_agent_app/app/state/app_shell_controller.dart';

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
    final projectTaskRepository = ProjectTaskRepository(
      workspacePort: bundle.projectWorkspacePort,
    );
    final promptTemplateService = ProjectPromptTemplateService(
      workspacePort: bundle.projectWorkspacePort,
    );
    final reviewReportService = ProjectReviewReportService(
      workspacePort: bundle.projectWorkspacePort,
      taskRepository: projectTaskRepository,
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
        );
      },
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
      ),
      discoverProjectsUseCase: DiscoverProjectsUseCase(
        projectRepository: bundle.projectRepository,
        projectWorkspacePort: bundle.projectWorkspacePort,
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
      writeProjectTextFileUseCase: writeProjectTextFileUseCase,
      workflowRuntimeService: workflowRuntimeService,
      reviewReportService: reviewReportService,
      promptTemplateService: promptTemplateService,
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
        );
      },
    );

    await tester.pumpWidget(NovelAgentApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.byType(WidgetsApp), findsOneWidget);
    expect(find.text('正文工作区'), findsOneWidget);
  });
}
