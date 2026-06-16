part of 'workflow_command.dart';

Future<_WorkflowContext?> _workflowContext(
  WorkflowCommand command,
  List<String> args, {
  bool requireProvider = false,
}) async {
  // 中文注释: settings、默认项目和 provider 校验集中在这里，避免每个 workflow 子命令各自拼装加载逻辑。
  final settings = await command._settingsRepository.load();
  if (requireProvider && settings.defaultProvider() == null) {
    command._printer.error('未找到可用 provider。');
    return null;
  }
  final project = await _openProject(
    command,
    args,
    defaultProjectPath: settings.defaultProjectPath,
  );
  if (project == null) {
    return null;
  }
  return _WorkflowContext(project: project, settings: settings);
}

Future<ProjectDescriptor?> _openProject(
  WorkflowCommand command,
  List<String> args, {
  required String defaultProjectPath,
}) async {
  // 中文注释: 项目打开只做路径解析与存在性检查，业务判断保持在 shared runtime 内。
  final projectPath = _optionValue(args, '--project') ?? defaultProjectPath;
  final project = await command._projectRepository.openByPath(projectPath);
  if (project == null) {
    command._printer.error('项目不存在: $projectPath');
    return null;
  }
  return project;
}

Future<JsonMap> _taskSelectorFromArgs(
  WorkflowCommand command,
  ProjectDescriptor project,
  List<String> args,
) async {
  // 中文注释: 任务选择支持 path、id 与 positional 三种入口，兼容旧项目定位习惯。
  final taskPath = _optionValue(args, '--task') ?? _optionValue(args, '--path');
  if ((taskPath ?? '').trim().isNotEmpty) {
    return <String, Object?>{'relative_path': taskPath!.trim()};
  }
  final taskId = _optionValue(args, '--id');
  if ((taskId ?? '').trim().isNotEmpty) {
    return <String, Object?>{'task_id': taskId!.trim()};
  }
  final positional = _joinedPositional(args);
  if (positional.trim().isNotEmpty) {
    return <String, Object?>{'relative_path': positional.trim()};
  }
  final nextTask = await command._workflowRuntimeService.nextWorkflowTask(
    project,
  );
  if (nextTask.isNotEmpty) {
    return <String, Object?>{
      'relative_path': ValueReaders.stringValue(nextTask['relative_path']),
    };
  }
  return <String, Object?>{};
}

Future<String> _resolveRunPath(
  WorkflowCommand command,
  ProjectDescriptor project,
  List<String> args,
) async {
  // 中文注释: long-task resume/pause 统一复用同一个运行记录解析逻辑。
  final explicit = _optionValue(args, '--run') ?? '';
  if (explicit.trim().isNotEmpty) {
    return explicit.trim();
  }
  final runs = await command._workflowRuntimeService.listLongTaskRuns(
    project,
    limit: 1,
  );
  if (runs.isEmpty) {
    return '';
  }
  return ValueReaders.stringValue(runs.first['relative_path']);
}

String? _optionValue(List<String> args, String name) {
  // 中文注释: workflow 旗标读取委托共享 parser，命令文件只保留业务分发。
  return CliArguments(args).value(name);
}

int _intOption(List<String> args, String name, int fallback) {
  // 中文注释: workflow 数值旗标统一交给共享 parser 读取，避免每个子命令自己解释。
  return CliArguments(args).intValue(name, fallback);
}

String _joinedPositional(List<String> args) {
  // 中文注释: 非选项文本统一由共享 parser 拼接，减少 prompt/path 解析漂移。
  return CliArguments(args).positionalText();
}

String _titleFromPrompt(String prompt) {
  // 中文注释: 自动标题规则保持和 GUI 一致，避免两端生成的正文标题口径不一致。
  final firstLine = prompt.split('\n').first.trim();
  if (firstLine.isEmpty) {
    return '新正文';
  }
  return firstLine.length > 24 ? firstLine.substring(0, 24) : firstLine;
}

class _WorkflowContext {
  const _WorkflowContext({required this.project, required this.settings});

  final ProjectDescriptor project;
  final AppSettings settings;
}
