import 'conversation_command.dart';

/// 斜杠指令注册表。
///
/// 按 [ConversationCommand.name] 与别名索引；`all()` 返回去重后按名字排序的清单，
/// 供 `/help` 与 GUI 自动补全使用。排序保证两端展示稳定。
class ConversationCommandRegistry {
  ConversationCommandRegistry();

  final Map<String, ConversationCommand> _byKey = <String, ConversationCommand>{};

  void register(ConversationCommand command) {
    // 中文注释: 主名与别名都建索引，查找时一次命中；同名后注册者覆盖前者。
    _byKey[command.name] = command;
    for (final alias in command.aliases) {
      _byKey[alias] = command;
    }
  }

  ConversationCommand? lookup(String name) {
    final key = name.trim();
    if (key.isEmpty) {
      return null;
    }
    return _byKey[key];
  }

  List<ConversationCommand> all() {
    // 中文注释: 别名会让同一个命令在 map 里出现多次，按主名去重再排序，保证 help/补全干净稳定。
    final seen = <String>{};
    final unique = <ConversationCommand>[];
    for (final command in _byKey.values) {
      if (seen.add(command.name)) {
        unique.add(command);
      }
    }
    unique.sort((a, b) => a.name.compareTo(b.name));
    return unique;
  }
}
