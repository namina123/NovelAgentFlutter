import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

import 'cli_json_output_writer.dart';
import 'cli_log_level.dart';
import 'cli_output_mode.dart';
import 'cli_output_settings.dart';

class TerminalPrinter {
  const TerminalPrinter({
    this.settings = const CliOutputSettings(),
    this.jsonWriter,
    this.stdoutSink,
    this.stderrSink,
  });

  final CliOutputSettings settings;
  final CliJsonOutputWriter? jsonWriter;
  final CliSink? stdoutSink;
  final CliSink? stderrSink;

  void info(String message) {
    // 中文注释: 普通信息输出统一收口，便于后续替换颜色或日志等级策略。
    if (settings.logLevel == CliLogLevel.quiet) {
      return;
    }
    _writeStdout(<String, Object?>{
      'type': 'info',
      'message': message,
    }, message);
  }

  void success(String message) {
    // 中文注释: 成功信息目前沿用纯文本前缀，保持跨终端兼容而不引入额外依赖。
    if (settings.logLevel == CliLogLevel.quiet) {
      return;
    }
    _writeStdout(<String, Object?>{
      'type': 'success',
      'message': message,
    }, '[OK] $message');
  }

  void debug(String message) {
    // 中文注释: 调试信息仅在显式 debug 模式下输出，避免污染普通用户终端。
    if (settings.logLevel != CliLogLevel.debug) {
      return;
    }
    _writeStdout(<String, Object?>{
      'type': 'debug',
      'message': message,
    }, '[DBG] $message');
  }

  void error(String message) {
    // 中文注释: 错误输出走 stderr，保证脚本调用 CLI 时能区分正常文本与失败信息。
    _writeStderr(<String, Object?>{
      'type': 'error',
      'message': message,
    }, '[ERR] $message');
  }

  void block(String title, String content) {
    // 中文注释: 大段文本展示由统一块输出包装，避免各命令自己拼接分隔符。
    if (settings.logLevel == CliLogLevel.quiet) {
      return;
    }
    _writeStdout(<String, Object?>{
      'type': 'block',
      'title': title,
      'content': content,
    }, '== $title ==\n$content');
  }

  void _writeStdout(JsonMap payload, String text) {
    if (settings.mode == CliOutputMode.json) {
      (jsonWriter ?? CliJsonOutputWriter()).writeStdout(payload);
      return;
    }
    (stdoutSink ?? _defaultStdoutSink)(text);
  }

  void _writeStderr(JsonMap payload, String text) {
    if (settings.mode == CliOutputMode.json) {
      (jsonWriter ?? CliJsonOutputWriter()).writeStderr(payload);
      return;
    }
    (stderrSink ?? _defaultStderrSink)(text);
  }

  static void _defaultStdoutSink(String message) {
    print(message);
  }

  static void _defaultStderrSink(String message) {
    stderr.writeln(message);
  }
}
