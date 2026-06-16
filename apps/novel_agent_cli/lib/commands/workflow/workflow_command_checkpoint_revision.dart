part of 'workflow_command.dart';

Future<int> _runCheckpointActions(
  WorkflowCommand command,
  List<String> args,
) async {
  // 中文注释: checkpoint 动作合同只读取共享 runtime 输出，CLI 不自己重建动作判断。
  final context = await _workflowContext(command, args);
  if (context == null) {
    return 2;
  }
  final reviewPath = _optionValue(args, '--review') ?? '';
  if (reviewPath.trim().isEmpty) {
    command._printer.error('请通过 --review 指定 checkpoint review 路径。');
    return 2;
  }
  final result = await command._workflowRuntimeService
      .buildCheckpointReviewActionPackage(context.project, reviewPath.trim());
  if (!ValueReaders.boolValue(result['ok'])) {
    command._printer.error(ValueReaders.stringValue(result['error'], '执行失败。'));
    return 1;
  }
  command._printer.block('checkpoint 动作包', _prettyJson(result));
  return 0;
}

Future<int> _runApplyCheckpointAction(
  WorkflowCommand command,
  List<String> args,
) async {
  // 中文注释: checkpoint 动作应用统一转发给 runtime，CLI 只负责参数收集和结果展示。
  final context = await _workflowContext(command, args);
  if (context == null) {
    return 2;
  }
  final reviewPath = _optionValue(args, '--review') ?? '';
  final actionCommand = _optionValue(args, '--command') ?? '';
  if (reviewPath.trim().isEmpty || actionCommand.trim().isEmpty) {
    command._printer.error('请通过 --review 和 --command 指定 checkpoint 动作。');
    return 2;
  }
  final result = await command._workflowRuntimeService
      .applyCheckpointReviewAction(
        context.project,
        reviewPath.trim(),
        actionCommand.trim(),
      );
  return _printWorkflowResult(command, result, success: 'checkpoint 动作已应用。');
}

Future<int> _runRevisionResolution(
  WorkflowCommand command,
  List<String> args,
) async {
  // 中文注释: revision 收口合同也走共享 runtime，CLI 不重新推断当前能否返工或回滚。
  final context = await _workflowContext(command, args);
  if (context == null) {
    return 2;
  }
  final selector = await _taskSelectorFromArgs(command, context.project, args);
  if (selector.isEmpty) {
    command._printer.error('请通过 --task 或 --id 选择 revision 任务。');
    return 2;
  }
  final result = await command._workflowRuntimeService.buildRevisionResolution(
    context.project,
    selector,
  );
  if (!ValueReaders.boolValue(result['ok'])) {
    command._printer.error(ValueReaders.stringValue(result['error'], '执行失败。'));
    return 1;
  }
  command._printer.block('revision 收口动作', _prettyJson(result));
  return 0;
}

Future<int> _runApplyRevisionResolution(
  WorkflowCommand command,
  List<String> args,
) async {
  // 中文注释: revision 收口动作应用统一转发给 runtime，避免 CLI 与 GUI 各自实现一套分支。
  final context = await _workflowContext(command, args);
  if (context == null) {
    return 2;
  }
  final selector = await _taskSelectorFromArgs(command, context.project, args);
  final actionCommand = _optionValue(args, '--command') ?? '';
  if (selector.isEmpty || actionCommand.trim().isEmpty) {
    command._printer.error(
      '请通过 --task 或 --id 选择 revision 任务，并通过 --command 指定动作。',
    );
    return 2;
  }
  final result = await command._workflowRuntimeService
      .applyRevisionResolutionAction(
        context.project,
        selector,
        actionCommand.trim(),
      );
  return _printWorkflowResult(command, result, success: 'revision 收口动作已应用。');
}

Future<int> _runAcceptRevision(
  WorkflowCommand command,
  List<String> args,
) async {
  // 中文注释: 接受修订结果只变更共享任务状态，不在 CLI 层直接操作 diff 文件。
  final context = await _workflowContext(command, args);
  if (context == null) {
    return 2;
  }
  final selector = await _taskSelectorFromArgs(command, context.project, args);
  if (selector.isEmpty) {
    command._printer.error('请通过 --task 或 --id 选择 revision 任务。');
    return 2;
  }
  final result = await command._workflowRuntimeService.acceptRevisionTask(
    context.project,
    selector,
  );
  return _printWorkflowResult(command, result, success: '修订结果已接受。');
}

Future<int> _runRollbackRevision(
  WorkflowCommand command,
  List<String> args,
) async {
  // 中文注释: 回滚修订依赖 revision diff 中的 backup 配对，这个过程完全交给共享 runtime 执行。
  final context = await _workflowContext(command, args);
  if (context == null) {
    return 2;
  }
  final selector = await _taskSelectorFromArgs(command, context.project, args);
  if (selector.isEmpty) {
    command._printer.error('请通过 --task 或 --id 选择 revision 任务。');
    return 2;
  }
  final result = await command._workflowRuntimeService.rollbackRevisionTask(
    context.project,
    selector,
  );
  return _printWorkflowResult(command, result, success: '修订结果已回滚。');
}
