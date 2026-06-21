part of 'approval_command.dart';

void _printApprovalHelp(ApprovalCommand command) {
  // 中文注释: approval help 只展示当前已接通的正式审批入口，避免把未来能力伪装成现在可用。
  CliHelpContract.printHelpBlock(command._printer, 'approval help', [
    'approval list [--project 路径]',
    'approval show --request research_request_xxx [--project 路径]',
    'approval approve --request research_request_xxx [--note 备注] [--project 路径]',
    'approval reject --request research_request_xxx [--note 备注] [--project 路径]',
    'approval policy show',
  ]);
}

void _printApprovalPolicy(ApprovalCommand command) {
  // 中文注释: policy show 只投影当前审批壳层的边界和真相源，不在 CLI 里创造新的审批规则。
  CliHelpContract.printHelpBlock(command._printer, 'approval policy', [
    '正式主入口：approval list/show/approve/reject',
    '研究审批的数据来源：项目待办研究动作服务',
    '工具权限审批真相：保留在 adapters/runtime 的审批记录服务中，后续可再接独立命令族。',
    'workflow pending-research：仅作为兼容薄转发入口。',
  ]);
}
