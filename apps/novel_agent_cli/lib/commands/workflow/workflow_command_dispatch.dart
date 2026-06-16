part of 'workflow_command.dart';

Future<int> workflowCommandDispatch(
  WorkflowCommand command,
  List<String> args,
) async {
  // 中文注释: workflow 根入口只负责动作分发，不再承载具体子命令逻辑。
  final action = args.isEmpty ? 'help' : args.first;
  final rest = args.isEmpty
      ? const <String>[]
      : args.skip(1).toList(growable: false);
  switch (action) {
    case 'start':
      return _runWorkflowStart(command, rest);
    case 'status':
      return _runWorkflowStatus(command, rest);
    case 'continue':
      return _runWorkflowContinue(command, rest);
    case 'pause':
      return _runWorkflowPause(command, rest);
    case 'resume':
      return _runWorkflowResume(command, rest);
    case 'inspect':
      return _runWorkflowInspect(command, rest);
    case 'logs':
      return _runWorkflowLogs(command, rest);
    case 'debug':
      return _runDebug(command, rest);
    case 'draft':
    case 'extract-reference':
    case 'create':
    case 'list':
    case 'next':
    case 'preflight':
    case 'plan':
    case 'chain':
    case 'prepare':
    case 'run-once':
    case 'run-next':
    case 'run-queue':
    case 'guidance-status':
    case 'create-from-guidance':
    case 'postprocess-once':
    case 'postprocess-next':
    case 'complete-next':
    case 'checkpoint-actions':
    case 'apply-checkpoint-action':
    case 'revision-resolution':
    case 'apply-revision-resolution':
    case 'accept-revision':
    case 'rollback-revision':
      return _runDebug(command, args);
    case 'pending-research':
      return command._approvalCommand.run(rest);
    case 'help':
    case '--help':
    case '-h':
      _printHelp(command);
      return 0;
    default:
      command._printer.error('未知 workflow 子命令: $action');
      _printHelp(command);
      return 2;
  }
}
