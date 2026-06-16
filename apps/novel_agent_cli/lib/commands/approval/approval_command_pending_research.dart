part of 'approval_command.dart';

Future<int> _runApprovalList(ApprovalCommand command, List<String> args) async {
  final context = await _projectContext(command, args);
  if (context == null) {
    return CliExitCodes.invalidInput;
  }
  final records = await command._pendingResearchActionService.list(
    context.project,
  );
  if (records.isEmpty) {
    command._printer.info('当前没有待处理审批。');
    return 0;
  }
  final lines = records.map(_approvalRecordLine).join('\n');
  command._printer.block('待处理审批', lines);
  return 0;
}

Future<int> _runApprovalShow(ApprovalCommand command, List<String> args) async {
  final context = await _projectContext(command, args);
  if (context == null) {
    return CliExitCodes.invalidInput;
  }
  final requestId = _approvalRequestId(args);
  if (requestId.isEmpty) {
    command._printer.error('请通过 --request 或 --id 指定审批请求。');
    return CliExitCodes.invalidInput;
  }
  final record = await command._pendingResearchActionService.load(
    context.project,
    requestId: requestId,
  );
  if (record.isEmpty) {
    command._printer.error('未找到对应审批请求。');
    return CliExitCodes.notFound;
  }
  command._printer.block('审批详情', _approvalRecordDetails(record));
  return 0;
}

Future<int> _runApprovalApprove(
  ApprovalCommand command,
  List<String> args,
) async {
  final context = await _projectContext(command, args);
  if (context == null) {
    return CliExitCodes.invalidInput;
  }
  final requestId = _approvalRequestId(args);
  if (requestId.isEmpty) {
    command._printer.error('请通过 --request 或 --id 指定审批请求。');
    return CliExitCodes.invalidInput;
  }
  final result = await command._pendingResearchActionService.approve(
    context.project,
    requestId: requestId,
    actorId: 'novel_agent_cli',
    note: await _note(command, args),
  );
  return _printApprovalActionResult(command, result, success: '审批请求已确认。');
}

Future<int> _runApprovalReject(
  ApprovalCommand command,
  List<String> args,
) async {
  final context = await _projectContext(command, args);
  if (context == null) {
    return CliExitCodes.invalidInput;
  }
  final requestId = _approvalRequestId(args);
  if (requestId.isEmpty) {
    command._printer.error('请通过 --request 或 --id 指定审批请求。');
    return CliExitCodes.invalidInput;
  }
  final result = await command._pendingResearchActionService.reject(
    context.project,
    requestId: requestId,
    actorId: 'novel_agent_cli',
    note: await _note(command, args),
  );
  return _printApprovalActionResult(command, result, success: '审批请求已拒绝。');
}

Future<int> _runApprovalPolicy(
  ApprovalCommand command,
  List<String> args,
) async {
  final action = args.isEmpty ? 'show' : args.first;
  switch (action) {
    case 'show':
      _printApprovalPolicy(command);
      return 0;
    case 'help':
    case '--help':
    case '-h':
      _printApprovalHelp(command);
      return 0;
    default:
      command._printer.error('未知 approval policy 动作: $action');
      _printApprovalHelp(command);
      return CliExitCodes.invalidInput;
  }
}

Future<_ApprovalProjectContext?> _projectContext(
  ApprovalCommand command,
  List<String> args,
) async {
  // 中文注释: approval 命令直接复用 shared 项目上下文加载，避免重复实现 settings/project 打开逻辑。
  final context = await command._projectContextLoader.load(args);
  if (context == null) {
    return null;
  }
  return _ApprovalProjectContext(context.project);
}

int _printApprovalActionResult(
  ApprovalCommand command,
  JsonMap result, {
  required String success,
}) {
  // 中文注释: 审批动作结果只投影共享 action service 输出，不在 CLI 里重建状态机。
  if (!ValueReaders.boolValue(result['ok'])) {
    final error = ValueReaders.stringValue(result['error'], '执行失败。');
    command._printer.error(error);
    if (error.toLowerCase().contains('not found')) {
      return CliExitCodes.notFound;
    }
    return CliExitCodes.executionFailure;
  }
  command._printer.success(success);
  final requestId = ValueReaders.stringValue(result['request_id']).trim();
  final requestState = ValueReaders.stringValue(result['request_state']).trim();
  final actionStatus = ValueReaders.stringValue(result['action_status']).trim();
  if (requestId.isNotEmpty) {
    command._printer.info('请求: $requestId');
  }
  if (requestState.isNotEmpty) {
    command._printer.info('状态: ${_approvalStateLabel(requestState)}');
  }
  if (actionStatus.isNotEmpty && actionStatus != 'updated') {
    command._printer.info('结果: $actionStatus');
  }
  final changedPaths = ValueReaders.stringList(result['changed_paths']);
  if (changedPaths.isNotEmpty) {
    for (final path in changedPaths) {
      command._printer.info('已更新: ${_formatApprovalArtifactPath(path)}');
    }
  }
  return 0;
}

String _approvalRecordLine(JsonMap record) {
  // 中文注释: 待处理审批列表只做稳定的人类可读投影，不生成新的审批语义。
  final requestId = ValueReaders.stringValue(record['request_id']).trim();
  final requestState = ValueReaders.stringValue(record['request_state']).trim();
  final researchRequest = ValueReaders.mapValue(record['research_request']);
  final query = ValueReaders.stringValue(researchRequest['query']).trim();
  final reason = ValueReaders.stringValue(
    ValueReaders.mapValue(record['permission_decision'])['reason'],
    ValueReaders.stringValue(record['resolution_note']),
  ).trim();
  final parts = <String>[requestId, _approvalStateLabel(requestState)];
  if (query.isNotEmpty) {
    parts.add(query);
  }
  if (reason.isNotEmpty) {
    parts.add(reason);
  }
  return parts.join('｜');
}

String _approvalRecordDetails(JsonMap record) {
  // 中文注释: 详情投影只消费共享审批记录字段，便于 CLI / GUI / probe 复用同一合同。
  final requestId = ValueReaders.stringValue(record['request_id']).trim();
  final requestState = ValueReaders.stringValue(record['request_state']).trim();
  final researchRequest = ValueReaders.mapValue(record['research_request']);
  final query = ValueReaders.stringValue(researchRequest['query']).trim();
  final reason = ValueReaders.stringValue(
    ValueReaders.mapValue(record['permission_decision'])['reason'],
    ValueReaders.stringValue(record['resolution_note']),
  ).trim();
  final latestAction = ValueReaders.mapValue(
    ValueReaders.mapValue(record['metadata'])['latest_pending_research_action'],
  );
  final relativePath = ValueReaders.stringValue(record['relative_path']).trim();
  final lines = <String>[
    '审批类型：资料研究',
    if (requestId.isNotEmpty) '请求 ID：$requestId',
    if (requestState.isNotEmpty)
      '状态：${_approvalStateLabel(requestState)}（$requestState）',
    if (query.isNotEmpty) '请求：$query',
    if (reason.isNotEmpty) '原因：$reason',
    if (latestAction.isNotEmpty)
      '最近动作：${ValueReaders.stringValue(latestAction["command"])}',
    if (relativePath.isNotEmpty) '记录路径：${_formatApprovalArtifactPath(relativePath)}',
  ];
  return lines.where((line) => line.trim().isNotEmpty).join('\n');
}

String _approvalRequestId(List<String> args) {
  // 中文注释: 审批请求 ID 读取沿用同一条参数优先级，不额外引入壳层状态。
  return _optionValue(args, '--request') ?? _optionValue(args, '--id') ?? '';
}

String? _optionValue(List<String> args, String name) {
  return CliArguments(args).value(name);
}

Future<String> _note(ApprovalCommand command, List<String> args) async {
  // 中文注释: 审批备注优先取显式参数，必要时再从管道读取，方便脚本直接喂入说明文本。
  final note = await command._automationInputService.resolveTextInput(
    args,
    optionNames: const <String>['--note'],
  );
  return note?.trim() ?? '';
}

String _approvalStateLabel(String requestState) {
  // 中文注释: 审批状态仅做共享状态到人类可读标签的映射。
  switch (requestState) {
    case ProjectPendingResearchRequestStates.awaitingUserConfirmation:
      return '等待确认';
    case ProjectPendingResearchRequestStates.pendingGatewayExecution:
      return '待处理';
    case ProjectPendingResearchRequestStates.pendingReview:
      return '待审核';
    case ProjectPendingResearchRequestStates.needsUserInfo:
      return '待补充信息';
    case ProjectPendingResearchRequestStates.rejected:
      return '已拒绝';
    case ProjectPendingResearchRequestStates.completed:
      return '已完成';
    default:
      return requestState;
  }
}

String _formatApprovalArtifactPath(String relativePath) {
  // 中文注释: approval CLI 与 workflow 一样复用 core 路径身份语义，未知路径则原样输出。
  return const CliProjectArtifactLabelService().formatPath(relativePath);
}

class _ApprovalProjectContext {
  const _ApprovalProjectContext(this.project);

  final ProjectDescriptor project;
}
