import 'dart:convert';
import 'dart:io';

typedef CliSink = void Function(String message);

class CliJsonOutputWriter {
  CliJsonOutputWriter({CliSink? stdoutSink, CliSink? stderrSink})
    : _stdoutSink = stdoutSink ?? _defaultStdoutSink,
      _stderrSink = stderrSink ?? _defaultStderrSink;

  final CliSink _stdoutSink;
  final CliSink _stderrSink;

  void writeStdout(Map<String, Object?> payload) {
    // 中文注释: JSON 模式默认输出单行结构化事件到 stdout，便于脚本消费。
    _stdoutSink(jsonEncode(payload));
  }

  void writeStderr(Map<String, Object?> payload) {
    // 中文注释: 错误事件在 JSON 模式下走 stderr，保持 stdout 可用于正常结构化结果。
    _stderrSink(jsonEncode(payload));
  }

  static void _defaultStdoutSink(String message) => print(message);

  static void _defaultStderrSink(String message) => stderr.writeln(message);
}
