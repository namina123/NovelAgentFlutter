part of 'workflow_command.dart';

Future<int> _runDebug(WorkflowCommand command, List<String> args) async {
  // 中文注释: debug 命令组继续承接所有细颗粒 workflow 操作，但不再占据主帮助界面。
  final action = args.isEmpty ? 'help' : args.first;
  final rest = args.isEmpty
      ? const <String>[]
      : args.skip(1).toList(growable: false);
  switch (action) {
    case 'draft':
      return _runDraft(command, rest);
    case 'extract-reference':
      return _runExtractReference(command, rest);
    case 'create':
      return _runCreate(command, rest);
    case 'list':
      return _runList(command, rest);
    case 'next':
      return _runNext(command, rest);
    case 'preflight':
      return _runPreflight(command, rest);
    case 'plan':
      return _runPlan(command, rest);
    case 'chain':
      return _runChain(command, rest);
    case 'prepare':
      return _runPrepare(command, rest);
    case 'run-once':
      return _runSelectedOnce(command, rest);
    case 'run-next':
      return _runNextOnce(command, rest);
    case 'run-queue':
      return _runQueue(command, rest);
    case 'guidance-status':
      return _runGuidanceStatus(command, rest);
    case 'create-from-guidance':
      return _runCreateFromGuidance(command, rest);
    case 'postprocess-once':
      return _runPostprocessOnce(command, rest);
    case 'postprocess-next':
      return _runPostprocessNext(command, rest);
    case 'complete-next':
      return _runCompleteAndNext(command, rest);
    case 'pause':
      return _runPause(command, rest);
    case 'resume':
      return _runResume(command, rest);
    case 'checkpoint-actions':
      return _runCheckpointActions(command, rest);
    case 'apply-checkpoint-action':
      return _runApplyCheckpointAction(command, rest);
    case 'revision-resolution':
      return _runRevisionResolution(command, rest);
    case 'apply-revision-resolution':
      return _runApplyRevisionResolution(command, rest);
    case 'accept-revision':
      return _runAcceptRevision(command, rest);
    case 'rollback-revision':
      return _runRollbackRevision(command, rest);
    case 'help':
    case '--help':
    case '-h':
      _printDebugHelp(command);
      return 0;
    default:
      command._printer.error('未知 workflow debug 子命令: $action');
      _printDebugHelp(command);
      return 2;
  }
}
