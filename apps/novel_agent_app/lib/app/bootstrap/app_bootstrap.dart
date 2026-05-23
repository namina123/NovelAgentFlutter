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
    final contextAssemblerService = ContextAssemblerService(
      budgetService: ContextBudgetService(),
      staticSectionService: ContextStaticSectionService(
        projectPromptContract: ProjectPromptContract(),
      ),
      projectFileSectionService: ContextProjectFileSectionService(),
    );
    final controller = AppShellController(
      settingsRepository: bundle.settingsRepository,
      loadProjectWorkspaceUseCase: LoadProjectWorkspaceUseCase(
        projectRepository: bundle.projectRepository,
        projectWorkspacePort: bundle.projectWorkspacePort,
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
      settingsRootPath: bundle.settingsRootPath,
      settingsSearchRoots: bundle.settingsSearchRoots,
      defaultProjectsRootPath: bundle.defaultProjectRootPath,
      isMobileProjectRootLocked: Platform.isAndroid || Platform.isIOS,
      generateDraftUseCaseFactory: (provider) {
        // 中文注释: 草稿生成用例按当前 provider 动态创建，避免控制器直接依赖具体 HTTP 实现。
        return GenerateDraftUseCase(
          projectWorkspacePort: bundle.projectWorkspacePort,
          llmGateway: bundle.createGateway(provider),
          toolExecutionPort: bundle.projectToolExecutionPort,
          contextAssemblerService: contextAssemblerService,
          projectPromptContract: ProjectPromptContract(),
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
}
