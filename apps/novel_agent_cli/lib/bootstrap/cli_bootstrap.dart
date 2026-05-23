import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../commands/project/project_command.dart';
import '../commands/session/session_command.dart';
import '../commands/workflow/workflow_command.dart';
import '../output/terminal_printer.dart';

class CliBootstrap {
  Future<int> run(List<String> args) async {
    // 中文注释: CLI bootstrap 是唯一允许组装适配器和命令对象的地方，命令本身只消费依赖。
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
    final workflowCommand = WorkflowCommand(
      settingsRepository: bundle.settingsRepository,
      projectRepository: bundle.projectRepository,
      saveDraftUseCase: SaveDraftUseCase(
        projectWorkspacePort: bundle.projectWorkspacePort,
      ),
      generateDraftUseCaseFactory: (provider) {
        // 中文注释: CLI 与 GUI 共用同一套生成用例装配，只在输入输出壳层上保持差异。
        return GenerateDraftUseCase(
          projectWorkspacePort: bundle.projectWorkspacePort,
          llmGateway: bundle.createGateway(provider),
          toolExecutionPort: bundle.projectToolExecutionPort,
          contextAssemblerService: contextAssemblerService,
          projectPromptContract: ProjectPromptContract(),
        );
      },
      printer: printer,
    );
    final projectCommand = ProjectCommand(
      loadProjectWorkspaceUseCase: LoadProjectWorkspaceUseCase(
        projectRepository: bundle.projectRepository,
        projectWorkspacePort: bundle.projectWorkspacePort,
      ),
      printer: printer,
    );
    final sessionCommand = SessionCommand(printer: printer);
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
        'session',
      ].join('\n'),
    );
  }
}
