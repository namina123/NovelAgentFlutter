import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../shared/cli_arguments.dart';
import '../shared/cli_automation_input_service.dart';
import '../shared/cli_exit_codes.dart';
import '../shared/cli_help_contract.dart';
import '../shared/cli_project_artifact_label_service.dart';
import '../shared/cli_project_context_loader.dart';
import '../../output/terminal_printer.dart';

part 'approval_command_dispatch.dart';
part 'approval_command_output.dart';
part 'approval_command_pending_research.dart';

class ApprovalCommand {
  const ApprovalCommand({
    required ProjectPendingResearchActionService pendingResearchActionService,
    required CliProjectContextLoader projectContextLoader,
    required TerminalPrinter printer,
    CliAutomationInputService? automationInputService,
  }) : _pendingResearchActionService = pendingResearchActionService,
       _projectContextLoader = projectContextLoader,
       _automationInputService =
           automationInputService ?? const CliAutomationInputService(),
       _printer = printer;

  final ProjectPendingResearchActionService _pendingResearchActionService;
  final CliProjectContextLoader _projectContextLoader;
  final CliAutomationInputService _automationInputService;
  final TerminalPrinter _printer;

  Future<int> run(List<String> args) async {
    // 中文注释: approval 命令组只负责壳层分发，审批真相仍由共享 adapter 服务提供。
    return approvalCommandDispatch(this, args);
  }
}
