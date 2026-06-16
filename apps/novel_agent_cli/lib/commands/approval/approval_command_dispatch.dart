part of 'approval_command.dart';

Future<int> approvalCommandDispatch(
  ApprovalCommand command,
  List<String> args,
) async {
  // 中文注释: approval 根入口只分发子命令，不把审批规则写回 CLI 壳层。
  final action = args.isEmpty ? 'help' : args.first;
  final rest = args.isEmpty
      ? const <String>[]
      : args.skip(1).toList(growable: false);
  switch (action) {
    case 'list':
      return _runApprovalList(command, rest);
    case 'show':
      return _runApprovalShow(command, rest);
    case 'approve':
      return _runApprovalApprove(command, rest);
    case 'reject':
      return _runApprovalReject(command, rest);
    case 'policy':
      return _runApprovalPolicy(command, rest);
    case 'help':
    case '--help':
    case '-h':
      _printApprovalHelp(command);
      return 0;
    default:
      command._printer.error('未知 approval 子命令: $action');
      _printApprovalHelp(command);
      return CliExitCodes.invalidInput;
  }
}
