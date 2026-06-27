import 'conversation_command_context.dart';
import 'conversation_command_result.dart';

/// 一条斜杠指令的抽象。
///
/// 内置指令在 core 实现，只依赖 [ConversationCommandContext.backend] 触发后端副作用，
/// 自身只做参数解析与纯领域投影，保持无状态、可被 CLI 与 GUI 共享。
abstract class ConversationCommand {
  const ConversationCommand({
    required this.name,
    this.aliases = const <String>[],
    required this.summary,
    this.usage = '',
    this.argHint = '',
  });

  /// 指令名（不含 `/`），如 `goal`。
  final String name;

  /// 别名（同样不含 `/`），如 `?`。
  final List<String> aliases;

  /// 一句话简介，供 `/help` 与 GUI 自动补全列表展示。
  final String summary;

  /// 用法示例，如 `/goal [模式|目标文字]`。
  final String usage;

  /// 参数提示，补全列表里展示，如 `[模式]`。
  final String argHint;

  Future<ConversationCommandResult> execute(ConversationCommandContext ctx);
}
