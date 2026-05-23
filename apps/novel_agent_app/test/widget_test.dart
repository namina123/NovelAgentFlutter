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
      isMobileProjectRootLocked: false,
      generateDraftUseCaseFactory: (provider) {
        // 中文注释: widget 测试沿用真实装配，确保最小可用链路至少能在界面层成功挂载。
        return GenerateDraftUseCase(
          projectWorkspacePort: bundle.projectWorkspacePort,
          llmGateway: bundle.createGateway(provider),
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
