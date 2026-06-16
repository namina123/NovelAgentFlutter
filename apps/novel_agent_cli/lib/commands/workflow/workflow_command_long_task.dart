part of 'workflow_command.dart';

Future<int> _runCreate(WorkflowCommand command, List<String> args) async {
  // 中文注释: 长任务开局只生成计划与任务文件，方便 CLI 和 GUI 共用后续执行链。
  final context = await _workflowContext(command, args);
  if (context == null) {
    return 2;
  }
  final result = await command._workflowRuntimeService.createLongTaskWorkflow(
    context.project,
    _optionValue(args, '--mode') ??
        TaskRuntimeConstants.modeHumanOutlineAiDraft,
    options: <String, Object?>{
      'outline_path': _optionValue(args, '--outline') ?? 'outline/outline.md',
      'seed_prompt': _optionValue(args, '--seed') ?? '',
      'chapter_count': _intOption(args, '--chapters', 12),
      'checkpoint_interval': _intOption(args, '--checkpoint', 3),
    },
  );
  return _printWorkflowResult(command, result, success: '长任务队列已生成。');
}

Future<int> _runList(WorkflowCommand command, List<String> args) async {
  // 中文注释: 任务列表命令输出共享排序结果，便于终端快速核对当前项目队列。
  final context = await _workflowContext(command, args);
  if (context == null) {
    return 2;
  }
  final tasks = await command._workflowRuntimeService.listWorkflowTasks(
    context.project,
  );
  if (tasks.isEmpty) {
    command._printer.info('当前项目还没有任务。');
    return 0;
  }
  final lines = tasks
      .map(
        (task) =>
            '${ValueReaders.stringValue(task['status'])}'
            '｜${ValueReaders.stringValue(task['task_type'])}'
            '｜${ValueReaders.stringValue(task['title'])}'
            '｜${ValueReaders.stringValue(task['relative_path'])}',
      )
      .join('\n');
  command._printer.block('任务列表', lines);
  return 0;
}

Future<int> _runNext(WorkflowCommand command, List<String> args) async {
  // 中文注释: 下一任务预览只显示共享调度层认定的下一条 runnable 任务。
  final context = await _workflowContext(command, args);
  if (context == null) {
    return 2;
  }
  final nextTask = await command._workflowRuntimeService.nextWorkflowTask(
    context.project,
  );
  if (nextTask.isEmpty) {
    command._printer.info('当前没有可运行任务。');
    return 0;
  }
  command._printer.block('下一任务', _prettyJson(nextTask));
  return 0;
}

Future<int> _runPreflight(WorkflowCommand command, List<String> args) async {
  // 中文注释: 预检命令复用共享 preflight 规则，让 CLI 看到的阻塞原因和 GUI 完全一致。
  final context = await _workflowContext(command, args);
  if (context == null) {
    return 2;
  }
  final result = await command._workflowRuntimeService.taskQueuePreflight(
    context.project,
  );
  command._printer.block('队列预检', _prettyJson(result));
  return ValueReaders.boolValue(result['runnable']) ? 0 : 1;
}

Future<int> _runPlan(WorkflowCommand command, List<String> args) async {
  // 中文注释: 单任务计划导出成 Markdown 文件，供先审阅再执行的终端流程使用。
  final context = await _workflowContext(command, args);
  if (context == null) {
    return 2;
  }
  final selector = await _taskSelectorFromArgs(command, context.project, args);
  if (selector.isEmpty) {
    command._printer.error('请通过 --task 或 --id 选择任务。');
    return 2;
  }
  final result = await command._workflowRuntimeService.saveWorkflowTaskPlan(
    context.project,
    selector,
  );
  return _printWorkflowResult(command, result, success: '任务计划已生成。');
}

Future<int> _runChain(WorkflowCommand command, List<String> args) async {
  // 中文注释: 链路命令用于查看当前任务链结构和下一步位置，便于终端恢复现场。
  final context = await _workflowContext(command, args);
  if (context == null) {
    return 2;
  }
  final result = await command._workflowRuntimeService.workflowChainView(
    context.project,
  );
  command._printer.block('任务链', _prettyJson(result));
  return 0;
}

Future<int> _runPrepare(WorkflowCommand command, List<String> args) async {
  // 中文注释: prepare 只生成执行包，不直接触发模型，适合先检查 prompt 和输出路径。
  final context = await _workflowContext(command, args);
  if (context == null) {
    return 2;
  }
  final selector = await _taskSelectorFromArgs(command, context.project, args);
  if (selector.isEmpty) {
    command._printer.error('请通过 --task 或 --id 选择任务。');
    return 2;
  }
  final result = await command._workflowRuntimeService
      .prepareWorkflowTaskExecution(
        context.project,
        selector,
        contextSettings: context.settings.contextSettings,
      );
  return _printWorkflowResult(command, result, success: '执行包已准备完成。');
}

Future<int> _runSelectedOnce(WorkflowCommand command, List<String> args) async {
  // 中文注释: run-once 只推进指定任务一轮，方便终端精确控制节奏。
  final context = await _workflowContext(command, args, requireProvider: true);
  if (context == null) {
    return 2;
  }
  final selector = await _taskSelectorFromArgs(command, context.project, args);
  if (selector.isEmpty) {
    command._printer.error('请通过 --task 或 --id 选择任务。');
    return 2;
  }
  final result = await command._workflowRuntimeService.runWorkflowTaskOnce(
    context.project,
    context.settings,
    selector,
  );
  return _printWorkflowResult(command, result, success: '当前任务已执行一轮。');
}

Future<int> _runNextOnce(WorkflowCommand command, List<String> args) async {
  // 中文注释: run-next 让共享调度层自己挑选下一可运行任务并推进一次。
  final context = await _workflowContext(command, args, requireProvider: true);
  if (context == null) {
    return 2;
  }
  final result = await command._workflowRuntimeService.runNextWorkflowTaskOnce(
    context.project,
    context.settings,
  );
  return _printWorkflowResult(command, result, success: '下一任务已执行一轮。');
}

Future<int> _runQueue(WorkflowCommand command, List<String> args) async {
  // 中文注释: run-queue 走共享受控连续运行逻辑，让 CLI 也遵守同样的安全停机规则。
  final context = await _workflowContext(command, args, requireProvider: true);
  if (context == null) {
    return 2;
  }
  final result = await command._workflowRuntimeService.runWorkflowTaskQueue(
    context.project,
    context.settings,
    options: <String, Object?>{'max_steps': _intOption(args, '--steps', 3)},
  );
  return _printWorkflowResult(command, result, success: '队列运行已推进。');
}

Future<int> _runGuidanceStatus(
  WorkflowCommand command,
  List<String> args,
) async {
  // 中文注释: guidance-status 只读取共享模式状态并输出，不触发任何模型或任务写入。
  final context = await _workflowContext(command, args);
  if (context == null) {
    return 2;
  }
  final modeId = _optionValue(args, '--mode') ?? 'seed_autopilot_novel';
  final state = await command._loadModeGuidanceStateUseCase.execute(
    context.project,
    modeId: modeId,
    initializeIfMissing: false,
  );
  command._printer.block('模式引导状态', _prettyJson(state.toJsonMap()));
  return 0;
}

Future<int> _runCreateFromGuidance(
  WorkflowCommand command,
  List<String> args,
) async {
  // 中文注释: create-from-guidance 直接把已收束的模式状态映射成共享任务骨架，CLI 不再要求用户重复手填同样信息。
  final context = await _workflowContext(command, args);
  if (context == null) {
    return 2;
  }
  final modeId = _optionValue(args, '--mode') ?? 'seed_autopilot_novel';
  final planInput = await command._buildModeGuidancePlanInputUseCase.execute(
    context.project,
    modeId: modeId,
  );
  if (planInput == null) {
    command._printer.error('当前项目还没有模式引导状态。');
    return 2;
  }
  if (!planInput.isReady) {
    command._printer.error(
      '当前模式信息尚未完成，缺失阶段：${planInput.missingFields.join(', ')}',
    );
    return 2;
  }
  final result = await command._workflowRuntimeService.createLongTaskWorkflow(
    context.project,
    planInput.runtimeMode,
    options: planInput.options,
  );
  return _printWorkflowResult(command, result, success: '已根据模式引导生成长任务队列。');
}

Future<int> _runPostprocessOnce(
  WorkflowCommand command,
  List<String> args,
) async {
  // 中文注释: 后处理单步不会改写正文规划，而是推进摘要、记忆和检查产物。
  final context = await _workflowContext(command, args, requireProvider: true);
  if (context == null) {
    return 2;
  }
  final selector = await _taskSelectorFromArgs(command, context.project, args);
  if (selector.isEmpty) {
    command._printer.error('请通过 --task 或 --id 选择任务。');
    return 2;
  }
  final result = await command._workflowRuntimeService
      .runWorkflowTaskPostprocessOnce(
        context.project,
        context.settings,
        selector,
      );
  return _printWorkflowResult(command, result, success: '当前任务后处理已执行一轮。');
}

Future<int> _runPostprocessNext(
  WorkflowCommand command,
  List<String> args,
) async {
  // 中文注释: 自动选择下一条待后处理任务并推进一轮。
  final context = await _workflowContext(command, args, requireProvider: true);
  if (context == null) {
    return 2;
  }
  final result = await command._workflowRuntimeService
      .runNextWorkflowTaskPostprocessOnce(context.project, context.settings);
  return _printWorkflowResult(command, result, success: '下一条后处理已执行一轮。');
}

Future<int> _runCompleteAndNext(
  WorkflowCommand command,
  List<String> args,
) async {
  // 中文注释: complete-next 用于人工确认后把当前任务标记完成，并尝试继续下一条。
  final context = await _workflowContext(command, args, requireProvider: true);
  if (context == null) {
    return 2;
  }
  final selector = await _taskSelectorFromArgs(command, context.project, args);
  if (selector.isEmpty) {
    command._printer.error('请通过 --task 或 --id 选择任务。');
    return 2;
  }
  final result = await command._workflowRuntimeService
      .completeWorkflowTaskAndRunNext(
        context.project,
        context.settings,
        selector,
      );
  return _printWorkflowResult(command, result, success: '已完成当前任务，并尝试继续下一条。');
}

Future<int> _runPause(WorkflowCommand command, List<String> args) async {
  // 中文注释: 暂停优先使用命令参数指定运行记录，否则回退到最近一条长任务运行记录。
  final context = await _workflowContext(command, args);
  if (context == null) {
    return 2;
  }
  final runPath = await _resolveRunPath(command, context.project, args);
  if (runPath.isEmpty) {
    command._printer.error('当前没有可暂停的长任务运行记录。');
    return 2;
  }
  final result = await command._workflowRuntimeService.pauseLongTaskRun(
    context.project,
    runPath,
  );
  return _printWorkflowResult(command, result, success: '长任务运行已暂停。');
}

Future<int> _runResume(WorkflowCommand command, List<String> args) async {
  // 中文注释: 恢复长任务继续复用共享队列运行入口，不在 CLI 层另造一套继续逻辑。
  final context = await _workflowContext(command, args, requireProvider: true);
  if (context == null) {
    return 2;
  }
  final runPath = await _resolveRunPath(command, context.project, args);
  if (runPath.isEmpty) {
    command._printer.error('当前没有可恢复的长任务运行记录。');
    return 2;
  }
  final result = await command._workflowRuntimeService.resumeLongTaskRun(
    context.project,
    context.settings,
    runPath,
  );
  return _printWorkflowResult(command, result, success: '长任务运行已恢复推进。');
}
