import '../../output/terminal_printer.dart';

class SessionCommand {
  const SessionCommand({required TerminalPrinter printer}) : _printer = printer;

  final TerminalPrinter _printer;

  int run(List<String> args) {
    // 中文注释: 会话命令当前先明确告知迁移边界，避免用户误以为桌面自动会话已经完整接通。
    _printer.info(
      'session 子命令仍在迁移中，当前优先保证 workflow draft 与 project summary 可用。',
    );
    return 0;
  }
}
