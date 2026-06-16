part of 'doctor_command.dart';

Future<int> doctorCommandDispatch(DoctorCommand command, List<String> args) async {
  // 中文注释: doctor 根入口默认执行检查，同时保留 help 作为显式入口。
  final action = args.isEmpty ? 'check' : args.first;
  switch (action) {
    case 'check':
      return _runDoctorCheck(command);
    case 'help':
    case '--help':
    case '-h':
      _printDoctorHelp(command);
      return 0;
    default:
      command._printer.error('未知 doctor 子命令: $action');
      _printDoctorHelp(command);
      return CliExitCodes.invalidInput;
  }
}
