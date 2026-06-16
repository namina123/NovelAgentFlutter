import '../commands/shared/cli_arguments.dart';
import 'cli_log_level.dart';
import 'cli_output_mode.dart';

class CliOutputSettings {
  const CliOutputSettings({
    this.mode = CliOutputMode.text,
    this.logLevel = CliLogLevel.normal,
    this.noColor = false,
  });

  final CliOutputMode mode;
  final CliLogLevel logLevel;
  final bool noColor;

  static CliOutputSettings fromArgs(List<String> args) {
    // 中文注释: 全局输出协议只在 bootstrap 层解析一次，后续命令复用统一结果。
    final parsed = CliArguments(args);
    final mode = parsed.has('--json') ? CliOutputMode.json : CliOutputMode.text;
    final logLevel = parsed.has('--debug')
        ? CliLogLevel.debug
        : parsed.has('--verbose')
        ? CliLogLevel.verbose
        : parsed.has('--quiet')
        ? CliLogLevel.quiet
        : CliLogLevel.normal;
    return CliOutputSettings(
      mode: mode,
      logLevel: logLevel,
      noColor: parsed.has('--no-color'),
    );
  }

  static List<String> stripGlobalFlags(List<String> args) {
    // 中文注释: 输出协议 flag 在 bootstrap 层剥离，避免命令子解析器把它们当成未知参数。
    return CliArguments(args).withoutFlags(const <String>{
      '--json',
      '--quiet',
      '--verbose',
      '--debug',
      '--no-color',
    });
  }
}
