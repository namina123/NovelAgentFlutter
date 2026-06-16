import 'dart:convert';

import 'package:novel_agent_core/novel_agent_core.dart';

import '../shared/cli_arguments.dart';
import '../shared/cli_exit_codes.dart';
import '../shared/cli_help_contract.dart';
import '../../output/terminal_printer.dart';

part 'config_command_dispatch.dart';
part 'config_command_output.dart';
part 'config_command_state.dart';

class ConfigCommand {
  const ConfigCommand({
    required SettingsRepository settingsRepository,
    required TerminalPrinter printer,
  }) : _settingsRepository = settingsRepository,
       _printer = printer;

  final SettingsRepository _settingsRepository;
  final TerminalPrinter _printer;

  Future<int> run(List<String> args) async {
    // 中文注释: config 命令组只负责 settings 的读写壳层，不在 CLI 里自行发明配置中心。
    return configCommandDispatch(this, args);
  }
}
