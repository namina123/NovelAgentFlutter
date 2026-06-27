import 'conversation_command_context.dart';
import 'conversation_command_registry.dart';
import 'conversation_command_result.dart';

/// 斜杠指令分发器。
///
/// 解析 `/name args`，查注册表，执行命令断网，返回 [ConversationCommandResult]。
/// 非指令（不以 `/` 开头）返回 passThrough，交由宿主走正常发送链。
/// 宿主通过 [contextFactory] 提供每条指令的上下文（project/sessionRecord/backend 等）。
class ConversationCommandDispatcher {
  ConversationCommandDispatcher({
    required this.registry,
    required this.contextFactory,
  });

  final ConversationCommandRegistry registry;

  /// 给定指令参数文本，返回当前会话的执行上下文。
  /// 宿主在此从自己的状态载体取 project / sessionRecord / backend。
  final ConversationCommandContext Function(String rawArgs) contextFactory;

  Future<ConversationCommandResult> dispatch(String input) async {
    final trimmed = input.trim();
    if (!trimmed.startsWith('/')) {
      return const ConversationCommandResult(
        kind: ConversationCommandOutcomeKind.passThrough,
      );
    }
    final body = trimmed.substring(1).trim();
    if (body.isEmpty) {
      return ConversationCommandResult(
        kind: ConversationCommandOutcomeKind.unknown,
        message: availableCommandsHint(),
      );
    }
    final name = body.split(RegExp(r'\s+')).first;
    final command = registry.lookup(name);
    if (command == null) {
      return ConversationCommandResult(
        kind: ConversationCommandOutcomeKind.unknown,
        message: '未知指令：/$name\n${availableCommandsHint()}',
      );
    }
    final rawArgs = body.substring(name.length).trim();
    final ctx = contextFactory(rawArgs);
    final result = await command.execute(ctx);
    if (result.kind == ConversationCommandOutcomeKind.exit) {
      return result;
    }
    // 中文注释: 命令自报 handled/unknown 时直接回传；若命令误报 passThrough（极少），保留其语义。
    return result;
  }

  String availableCommandsHint() {
    final lines = <String>['可用指令：'];
    for (final command in registry.all()) {
      final tail = command.argHint.isEmpty ? '' : ' ${command.argHint}';
      lines.add('/${command.name}$tail — ${command.summary}');
    }
    lines.add('输入 /help 查看完整说明。');
    return lines.join('\n');
  }
}
