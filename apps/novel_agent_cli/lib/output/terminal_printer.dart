import 'dart:io';

class TerminalPrinter {
  const TerminalPrinter();

  void info(String message) {
    // 中文注释: 普通信息输出统一收口，便于后续替换颜色或日志等级策略。
    print(message);
  }

  void success(String message) {
    // 中文注释: 成功信息目前沿用纯文本前缀，保持跨终端兼容而不引入额外依赖。
    print('[OK] $message');
  }

  void error(String message) {
    // 中文注释: 错误输出走 stderr，保证脚本调用 CLI 时能区分正常文本与失败信息。
    stderr.writeln('[ERR] $message');
  }

  void block(String title, String content) {
    // 中文注释: 大段文本展示由统一块输出包装，避免各命令自己拼接分隔符。
    print('== $title ==');
    print(content);
  }
}
