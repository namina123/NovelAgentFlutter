import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

import '../shared/cli_exit_codes.dart';
import '../shared/cli_help_contract.dart';
import '../../output/terminal_printer.dart';

part 'doctor_command_dispatch.dart';
part 'doctor_command_output.dart';
part 'doctor_command_state.dart';

class DoctorCommand {
  const DoctorCommand({
    required SettingsRepository settingsRepository,
    required ProjectRepository projectRepository,
    required TerminalPrinter printer,
  }) : _settingsRepository = settingsRepository,
       _projectRepository = projectRepository,
       _printer = printer;

  final SettingsRepository _settingsRepository;
  final ProjectRepository _projectRepository;
  final TerminalPrinter _printer;

  Future<int> run(List<String> args) async {
    // 中文注释: doctor 命令组只做环境诊断壳层，不替宿主修复任何底层能力缺口。
    return doctorCommandDispatch(this, args);
  }
}
