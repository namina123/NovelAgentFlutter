import 'dart:io';

enum CliExecutionMode { interactive, nonInteractive, headless }

class CliModeDetectionService {
  const CliModeDetectionService({
    bool Function()? stdinHasTerminal,
    bool Function()? stdoutHasTerminal,
  }) : _stdinHasTerminal = stdinHasTerminal ?? _defaultStdinHasTerminal,
       _stdoutHasTerminal = stdoutHasTerminal ?? _defaultStdoutHasTerminal;

  final bool Function() _stdinHasTerminal;
  final bool Function() _stdoutHasTerminal;

  CliExecutionMode resolve({
    bool explicitInteractive = false,
    bool explicitNonInteractive = false,
  }) {
    // 中文注释: 终端模式由显式参数优先级和真实 TTY 状态共同决定，后续 session/headless 可以复用同一判断。
    if (explicitNonInteractive) {
      return CliExecutionMode.nonInteractive;
    }
    if (explicitInteractive) {
      return CliExecutionMode.interactive;
    }
    if (_stdinHasTerminal() && _stdoutHasTerminal()) {
      return CliExecutionMode.interactive;
    }
    return CliExecutionMode.headless;
  }

  bool get hasTerminal => _stdinHasTerminal() && _stdoutHasTerminal();

  static bool _defaultStdinHasTerminal() => stdin.hasTerminal;

  static bool _defaultStdoutHasTerminal() => stdout.hasTerminal;
}
