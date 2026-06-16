part of 'config_command.dart';

Future<int> configCommandDispatch(ConfigCommand command, List<String> args) async {
  // 中文注释: config 根入口只分发读写动作，不把 settings 语义散落到 bootstrap。
  final action = args.isEmpty ? 'show' : args.first;
  final rest = args.isEmpty
      ? const <String>[]
      : args.skip(1).toList(growable: false);
  switch (action) {
    case 'show':
      return _runConfigShow(command);
    case 'get':
      return _runConfigGet(command, rest);
    case 'set':
      return _runConfigSet(command, rest);
    case 'provider':
      return _runConfigProvider(command, rest);
    case 'help':
    case '--help':
    case '-h':
      _printConfigHelp(command);
      return 0;
    default:
      command._printer.error('未知 config 子命令: $action');
      _printConfigHelp(command);
      return CliExitCodes.invalidInput;
  }
}
