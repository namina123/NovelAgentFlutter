import '../../output/terminal_printer.dart';

class CliHelpContract {
  const CliHelpContract._();

  static void printHelpBlock(
    TerminalPrinter printer,
    String title,
    List<String> lines,
  ) {
    // 中文注释: CLI 的 help 统一由共享格式器输出，避免每个命令自己拼接块标题与换行格式。
    printer.block(title, lines.join('\n'));
  }
}
