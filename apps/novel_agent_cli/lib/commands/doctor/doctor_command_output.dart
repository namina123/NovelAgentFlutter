part of 'doctor_command.dart';

void _printDoctorHelp(DoctorCommand command) {
  // 中文注释: doctor help 只展示正式诊断入口，避免把临时 probe 误装成产品能力。
  CliHelpContract.printHelpBlock(command._printer, 'doctor help', [
    'doctor',
    'doctor check',
  ]);
}

String _prettyJson(JsonMap value) {
  // 中文注释: doctor 报告统一使用缩进 JSON，便于文本模式和 JSON 模式共享同一份稳定投影。
  return const JsonEncoder.withIndent('  ').convert(value);
}
