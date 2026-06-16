import 'package:novel_agent_core/novel_agent_core.dart';

import '../../output/terminal_printer.dart';
import 'cli_command_context.dart';

class CliProjectContextLoader {
  CliProjectContextLoader({
    required CliCommandContext commandContext,
    required ProjectRepository projectRepository,
    required TerminalPrinter printer,
  }) : _commandContext = commandContext,
       _projectRepository = projectRepository,
       _printer = printer;

  final CliCommandContext _commandContext;
  final ProjectRepository _projectRepository;
  final TerminalPrinter _printer;

  Future<CliProjectContext?> load(
    List<String> args, {
    String? defaultProjectPath,
  }) async {
    // 中文注释: 项目上下文加载把 settings、默认项目与项目打开统一收口，避免命令文件各自拼接重复逻辑。
    final projectPath =
        _optionValue(args, '--project') ??
        _resolvedDefaultProjectPath(defaultProjectPath);
    if (projectPath.trim().isEmpty) {
      _printer.error('请通过 --project 指定项目路径。');
      return null;
    }
    final project = await _projectRepository.openByPath(projectPath);
    if (project == null) {
      _printer.error('项目不存在: $projectPath');
      return null;
    }
    return CliProjectContext(
      commandContext: _commandContext,
      project: project,
      projectPath: projectPath,
    );
  }

  String _resolvedDefaultProjectPath(String? defaultProjectPath) {
    // 中文注释: 空字符串覆盖值不应吞掉 settings 里已经存在的默认项目路径。
    if (defaultProjectPath == null || defaultProjectPath.trim().isEmpty) {
      return _commandContext.defaultProjectPath;
    }
    return defaultProjectPath;
  }

  String? _optionValue(List<String> args, String name) {
    // 中文注释: 这里只处理共享的 --project 解析，保持 loader 轻量且不扩展成通用 parser。
    final index = args.indexOf(name);
    if (index < 0 || index + 1 >= args.length) {
      return null;
    }
    return args[index + 1].trim();
  }
}
