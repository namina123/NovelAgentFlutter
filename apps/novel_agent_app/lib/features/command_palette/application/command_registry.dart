import '../domain/command.dart';

/// 命令注册表。
///
/// 命令面板从这里读取全部可执行命令。各模块在启动期通过 [register] 注入自己的命令，
/// 面板打开时按 [visibleCommands] 过滤展示。注册表本身不做检索排序——那是
/// [searchCommands] 的职责；这里只负责「收纳 + 按 id 查找 + 过滤可用」。
class CommandRegistry {
  final Map<String, AppCommand> _commands = <String, AppCommand>{};

  /// 注册一条命令；id 重复时后者覆盖前者。
  void register(AppCommand command) {
    _commands[command.id] = command;
  }

  /// 当前已注册的全部命令（按注册顺序）。
  List<AppCommand> get all => _commands.values.toList(growable: false);

  /// 按 id 查找命令。
  AppCommand? findById(String id) => _commands[id];

  /// 仅返回当前可用的命令（[AppCommand.enabled] 为 true）。
  List<AppCommand> visibleCommands() {
    return _commands.values
        .where((AppCommand command) => command.enabled)
        .toList(growable: false);
  }

  /// 已注册命令总数。
  int get length => _commands.length;
}
