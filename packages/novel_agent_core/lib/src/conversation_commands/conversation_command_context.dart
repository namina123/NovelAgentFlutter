import '../common/json_types.dart';
import '../project/project_descriptor.dart';
import '../session/session_context_pressure_contracts.dart';
import 'conversation_command_backend.dart';

/// 单次指令执行的上下文。
///
/// 宿主在 dispatch 时为每条指令构造一个 context，携带当前会话的项目、会话记录、
/// 指令参数、后端实现与可选的预算设置。命令据此执行并返回 [ConversationCommandResult]。
class ConversationCommandContext {
  const ConversationCommandContext({
    required this.project,
    required this.sessionRecord,
    required this.rawArgs,
    required this.backend,
    this.budgetSettings,
  });

  final ProjectDescriptor project;

  /// 当前会话记录（JsonMap）。命令不应直接改它，需改写时通过 [backend] 返回新记录。
  final JsonMap sessionRecord;

  /// `/指令名` 之后的全部参数文本（已 trim）。
  final String rawArgs;

  final ConversationCommandBackend backend;

  /// 可选的 token 预算设置，供需要压力计算的命令/后端使用。
  final SessionTokenBudgetSettings? budgetSettings;
}
