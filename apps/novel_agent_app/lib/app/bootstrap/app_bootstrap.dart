import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../app.dart';
import '../state/app_shell_controller.dart';
import 'mobile_project_root_provider.dart';

class AppBootstrap {
  Future<void> run() async {
    // 中文注释: bootstrap 负责 GUI 组合根依赖，确保适配器实例化只发生在这一层。
    WidgetsFlutterBinding.ensureInitialized();
    final bundle = await _createAdapterBundle();
    final hostPlatform = _currentHostPlatform();
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
          hostPlatform: hostPlatform,
          loadAvailableAgents: (project) =>
              bundle.agentPackageCatalog.loadAgentPackages(project),
          loadAvailableAgentGroups: (project) =>
              bundle.agentGroupCatalog.loadAgentGroups(project),
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
      isMobileProjectRootLocked: Platform.isAndroid || Platform.isIOS,
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
        // 中文注释: 草稿生成用例按当前 provider 动态创建，避免控制器直接依赖具体 HTTP 实现。
        return GenerateDraftUseCase(
          projectWorkspacePort: bundle.projectWorkspacePort,
          llmGateway: bundle.createGateway(
            provider,
            networkSettings: networkSettings,
          ),
          toolExecutionPort: bundle.projectToolExecutionPort,
          contextAssemblerService: contextAssemblerService,
          projectPromptContract: ProjectPromptContract(),
          hostPlatform: hostPlatform,
          loadAvailableAgents: (project) =>
              bundle.agentPackageCatalog.loadAgentPackages(project),
          loadAvailableAgentGroups: (project) =>
              bundle.agentGroupCatalog.loadAgentGroups(project),
        );
      },
    );
    runApp(NovelAgentApp(controller: controller));
  }

  Future<AdapterBundle> _createAdapterBundle() async {
    // 中文注释: GUI 根依赖会按平台切换默认项目目录策略，但不会让移动端暴露可配置目录入口。
    if (Platform.isAndroid || Platform.isIOS) {
      final mobileProjectRootProvider = MobileProjectRootProvider();
      final documentsRootPath = await mobileProjectRootProvider
          .resolveDocumentsRootPath();
      final defaultProjectRootPath = await mobileProjectRootProvider
          .resolveDefaultProjectRootPath();
      return AdapterBundle.standard(
        settingsRootPath: documentsRootPath,
        settingsSearchRoots: <String>[documentsRootPath],
        defaultProjectRootPath: defaultProjectRootPath,
        allowConfiguredProjectPathOverride: false,
      );
    }
    final desktopPaths = DesktopAppPathsProvider().resolve(
      workingDirectoryPath: Directory.current.path,
    );
    return AdapterBundle.standard(
      workingDirectoryPath: Directory.current.path,
      settingsRootPath: desktopPaths.settingsRootPath,
      settingsSearchRoots: desktopPaths.settingsSearchRoots,
      defaultProjectRootPath: desktopPaths.defaultProjectRootPath,
    );
  }

  HostPlatform _currentHostPlatform() {
    // 中文注释: GUI 平台识别集中在 bootstrap，避免下层 core 再直接依赖 dart:io Platform。
    if (Platform.isWindows) {
      return HostPlatform.windows;
    }
    if (Platform.isLinux) {
      return HostPlatform.linux;
    }
    if (Platform.isMacOS) {
      return HostPlatform.macos;
    }
    if (Platform.isAndroid) {
      return HostPlatform.android;
    }
    if (Platform.isIOS) {
      return HostPlatform.ios;
    }
    return HostPlatform.unknown;
  }
}
