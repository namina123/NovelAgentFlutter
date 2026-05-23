import 'package:novel_agent_core/novel_agent_core.dart';

import '../../output/terminal_printer.dart';

class ProjectCommand {
  const ProjectCommand({
    required LoadProjectWorkspaceUseCase loadProjectWorkspaceUseCase,
    required TerminalPrinter printer,
  }) : _loadProjectWorkspaceUseCase = loadProjectWorkspaceUseCase,
       _printer = printer;

  final LoadProjectWorkspaceUseCase _loadProjectWorkspaceUseCase;
  final TerminalPrinter _printer;

  Future<int> run(
    List<String> args, {
    required String defaultProjectPath,
  }) async {
    // 中文注释: 项目命令当前只负责项目检查与摘要输出，不承担创作流程编排。
    final projectPath = _optionValue(args, '--project') ?? defaultProjectPath;
    final snapshot = await _loadProjectWorkspaceUseCase.execute(projectPath);
    if (snapshot == null) {
      _printer.error('项目不存在: $projectPath');
      return 2;
    }
    _printer.success('已打开项目: ${snapshot.project.name}');
    _printer.info('根目录: ${snapshot.project.rootPath}');
    _printer.info('资源条目: ${snapshot.entries.length}');
    final tree = ProjectPromptContract().projectTreeSummary(snapshot.entries);
    _printer.block('项目目录', tree);
    return 0;
  }

  String? _optionValue(List<String> args, String name) {
    // 中文注释: 当前 CLI 参数格式较轻，选项读取集中在命令类内部即可，不把解析库提前引进来。
    final index = args.indexOf(name);
    if (index < 0 || index + 1 >= args.length) {
      return null;
    }
    return args[index + 1].trim();
  }
}
