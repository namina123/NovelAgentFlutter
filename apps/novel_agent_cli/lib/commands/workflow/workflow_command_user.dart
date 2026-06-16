part of 'workflow_command.dart';

Future<int> _runWorkflowStart(
  WorkflowCommand command,
  List<String> args,
) async {
  // 中文注释: start 只负责把用户意图导向连续运行家族的正式起点，不在 CLI 层新增运行语义。
  if (_looksLikeReferenceExtractionStart(args)) {
    return _runDebug(command, <String>['extract-reference', ...args]);
  }
  return _runDebug(command, <String>['create', ...args]);
}

Future<int> _runWorkflowStatus(
  WorkflowCommand command,
  List<String> args,
) async {
  // 中文注释: status 只汇总任务队列与预检结果，供用户快速判断当前连续运行是否可继续。
  final context = await _workflowContext(command, args);
  if (context == null) {
    return 2;
  }
  final tasks = await command._workflowRuntimeService.listWorkflowTasks(
    context.project,
  );
  final preflight = await command._workflowRuntimeService.taskQueuePreflight(
    context.project,
  );
  final nextTask = await command._workflowRuntimeService.nextWorkflowTask(
    context.project,
  );
  final runs = await command._workflowRuntimeService.listLongTaskRuns(
    context.project,
    limit: 3,
  );
  final lines = <String>[
    '任务总数：${tasks.length}',
    '可运行：${ValueReaders.boolValue(preflight["can_run"]) ? "是" : "否"}',
    '主阻塞：${ValueReaders.stringValue(preflight["primary_blocker"], "none")}',
    '下一任务：${ValueReaders.stringValue(nextTask["title"], "暂无")}',
    '最近运行：${runs.length}',
  ];
  command._printer.block('workflow status', lines.join('\n'));
  return 0;
}

Future<int> _runWorkflowContinue(
  WorkflowCommand command,
  List<String> args,
) async {
  // 中文注释: continue 只推进当前连续运行一次，保留用户层最小闭环。
  if (_hasExplicitTaskSelector(args)) {
    return _runDebug(command, <String>['run-once', ...args]);
  }
  return _runDebug(command, <String>['run-next', ...args]);
}

Future<int> _runWorkflowPause(
  WorkflowCommand command,
  List<String> args,
) async {
  // 中文注释: pause 继续复用现有长任务暂停合同，只是收敛到用户层入口。
  return _runPause(command, args);
}

Future<int> _runWorkflowResume(
  WorkflowCommand command,
  List<String> args,
) async {
  // 中文注释: resume 继续复用现有长任务恢复合同，只是收敛到用户层入口。
  return _runResume(command, args);
}

Future<int> _runWorkflowInspect(
  WorkflowCommand command,
  List<String> args,
) async {
  // 中文注释: inspect 汇总连续运行链路与下一步位置，避免用户再手动拼多条 debug 命令。
  final context = await _workflowContext(command, args);
  if (context == null) {
    return 2;
  }
  final chain = await command._workflowRuntimeService.workflowChainView(
    context.project,
  );
  command._printer.block('workflow inspect', _prettyJson(chain));
  return 0;
}

Future<int> _runWorkflowLogs(WorkflowCommand command, List<String> args) async {
  // 中文注释: logs 只展示最近连续运行记录，便于用户确认宿主到底推进到哪一轮。
  final context = await _workflowContext(command, args);
  if (context == null) {
    return 2;
  }
  final runs = await command._workflowRuntimeService.listLongTaskRuns(
    context.project,
    limit: _intOption(args, '--limit', 10),
  );
  if (runs.isEmpty) {
    command._printer.info('当前没有连续运行记录。');
    return 0;
  }
  final lines = runs
      .map(
        (run) =>
            '${ValueReaders.stringValue(run["status"], "unknown")}｜'
            '${ValueReaders.stringValue(run["title"], "未命名")}｜'
            '${ValueReaders.stringValue(run["relative_path"])}',
      )
      .join('\n');
  command._printer.block('workflow logs', lines);
  return 0;
}

bool _looksLikeReferenceExtractionStart(List<String> args) {
  // 中文注释: start 的 extraction 分支只看稳定的提取参数，不依赖 CLI 私有状态。
  const extractionFlags = <String>{
    '--source',
    '--path',
    '--list-strategies',
    '--strategy-profile',
    '--package-id',
    '--display-name',
    '--version-id',
    '--version-label',
    '--source-language',
    '--target-language',
    '--bundle-dir',
    '--max-chapters',
    '--max-entities',
    '--no-export',
    '--no-attach',
    '--no-project-mount',
  };
  for (final flag in extractionFlags) {
    if (args.contains(flag) ||
        args.any((token) => token.startsWith('$flag='))) {
      return true;
    }
  }
  return false;
}

bool _hasExplicitTaskSelector(List<String> args) {
  // 中文注释: continue 若用户显式点名任务，则走单步推进；否则默认继续下一条可运行任务。
  return CliArguments(args).has('--task') ||
      CliArguments(args).has('--path') ||
      CliArguments(args).has('--id');
}
