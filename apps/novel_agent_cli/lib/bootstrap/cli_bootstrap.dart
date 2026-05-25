import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../commands/project/project_command.dart';
import '../commands/review/review_command.dart';
import '../commands/session/session_command.dart';
import '../commands/template/template_command.dart';
import '../commands/workflow/workflow_command.dart';
import '../output/terminal_printer.dart';

class CliBootstrap {
  Future<int> run(List<String> args) async {
    // 中文注释: CLI bootstrap 是唯一允许组装适配器和命令对象的地方，命令本身只消费依赖。
    final hostPlatform = _currentHostPlatform();
    final desktopPaths = DesktopAppPathsProvider().resolve(
      workingDirectoryPath: Directory.current.path,
    );
    final bundle = AdapterBundle.standard(
      workingDirectoryPath: Directory.current.path,
      settingsRootPath: desktopPaths.settingsRootPath,
      settingsSearchRoots: desktopPaths.settingsSearchRoots,
      defaultProjectRootPath: desktopPaths.defaultProjectRootPath,
    );
    final printer = const TerminalPrinter();
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
        );
      },
    );
    final workflowCommand = WorkflowCommand(
      settingsRepository: bundle.settingsRepository,
      projectRepository: bundle.projectRepository,
      saveDraftUseCase: SaveDraftUseCase(
        projectWorkspacePort: bundle.projectWorkspacePort,
      ),
      buildModeGuidancePlanInputUseCase: BuildModeGuidancePlanInputUseCase(
        statePort: modeGuidanceRepository,
      ),
      loadModeGuidanceStateUseCase: LoadModeGuidanceStateUseCase(
        statePort: modeGuidanceRepository,
      ),
      workflowRuntimeService: workflowRuntimeService,
      generateDraftUseCaseFactory: (provider, networkSettings) {
        // 中文注释: CLI 与 GUI 共用同一套生成用例装配，只在输入输出壳层上保持差异。
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
        );
      },
      printer: printer,
    );
    final projectCommand = ProjectCommand(
      loadProjectWorkspaceUseCase: LoadProjectWorkspaceUseCase(
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
      saveCustomizationBundleUseCase: SaveCustomizationBundleUseCase(
        writeProjectTextFileUseCase: writeProjectTextFileUseCase,
      ),
      loadAgentPackages: (project) =>
          bundle.agentPackageCatalog.loadAgentPackages(project),
      loadAgentGroups: (project) =>
          bundle.agentGroupCatalog.loadAgentGroups(project),
      loadSkillPackages: (project) =>
          bundle.skillPackageCatalog.loadSkillPackages(project),
      loadSkillGroups: (project) =>
          bundle.skillGroupCatalog.loadSkillGroups(project),
      projectRepository: bundle.projectRepository,
      printer: printer,
    );
    final sessionCommand = SessionCommand(printer: printer);
    final reviewCommand = ReviewCommand(
      settingsRepository: bundle.settingsRepository,
      projectRepository: bundle.projectRepository,
      reviewReportService: reviewReportService,
      printer: printer,
    );
    final templateCommand = TemplateCommand(
      settingsRepository: bundle.settingsRepository,
      projectRepository: bundle.projectRepository,
      promptTemplateService: promptTemplateService,
      printer: printer,
    );
    if (args.isEmpty) {
      _printRootHelp(printer);
      return 0;
    }
    final settings = await bundle.settingsRepository.load();
    switch (args.first) {
      case 'workflow':
        return workflowCommand.run(args.skip(1).toList(growable: false));
      case 'project':
        return projectCommand.run(
          args.skip(1).toList(growable: false),
          defaultProjectPath: settings.defaultProjectPath,
        );
      case 'session':
        return sessionCommand.run(args.skip(1).toList(growable: false));
      case 'review':
        return reviewCommand.run(args.skip(1).toList(growable: false));
      case 'template':
        return templateCommand.run(args.skip(1).toList(growable: false));
      case 'help':
      case '--help':
      case '-h':
        _printRootHelp(printer);
        return 0;
      default:
        printer.error('未知命令: ${args.first}');
        _printRootHelp(printer);
        return 2;
    }
  }

  void _printRootHelp(TerminalPrinter printer) {
    // 中文注释: 根帮助只展示当前已经可用的入口，减少用户在迁移期踩到空命令。
    printer.block(
      'novel_agent help',
      [
        'workflow draft --prompt "写第一章开场"',
        'project --project D:\\YourNovel',
        'review list --project D:\\YourNovel',
        'template list --project D:\\YourNovel',
        'session',
      ].join('\n'),
    );
  }

  HostPlatform _currentHostPlatform() {
    // 中文注释: CLI 平台识别集中在 bootstrap，后续若引入能力探测也只需在这里替换来源。
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
