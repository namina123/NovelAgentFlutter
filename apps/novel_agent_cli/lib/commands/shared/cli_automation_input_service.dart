import 'dart:convert';
import 'dart:io';

import 'cli_arguments.dart';
import 'cli_mode_detection_service.dart';

class CliAutomationInputService {
  const CliAutomationInputService({
    CliModeDetectionService? modeDetectionService,
    bool Function()? stdinHasTerminal,
    Future<String> Function()? stdinReader,
  }) : _modeDetectionService =
           modeDetectionService ?? const CliModeDetectionService(),
       _stdinHasTerminal = stdinHasTerminal ?? _defaultStdinHasTerminal,
       _stdinReader = stdinReader ?? _defaultStdinReader;

  final CliModeDetectionService _modeDetectionService;
  final bool Function() _stdinHasTerminal;
  final Future<String> Function() _stdinReader;

  CliExecutionMode resolveMode(List<String> args) {
    // 中文注释: automation 模式只在共享层判定一次，命令层只消费结果，不重复理解 TTY 规则。
    final parsed = CliArguments(args);
    return _modeDetectionService.resolve(
      explicitInteractive: parsed.has('--interactive'),
      explicitNonInteractive:
          parsed.has('--non-interactive') || parsed.has('--yes'),
    );
  }

  bool get hasInteractiveTerminal => _modeDetectionService.hasTerminal;

  Future<String?> resolveTextInput(
    List<String> args, {
    required List<String> optionNames,
    bool allowPositional = true,
  }) async {
    // 中文注释: 文本输入先吃显式参数与位置参数，再在 pipe/headless 场景下回落到 stdin。
    final explicit = _explicitText(args, optionNames, allowPositional);
    if (explicit.isNotEmpty) {
      return explicit;
    }
    final mode = resolveMode(args);
    if (mode == CliExecutionMode.interactive || _stdinHasTerminal()) {
      return null;
    }
    final stdinText = (await _stdinReader()).trim();
    return stdinText.isEmpty ? null : stdinText;
  }

  String _explicitText(
    List<String> args,
    List<String> optionNames,
    bool allowPositional,
  ) {
    // 中文注释: 显式文本支持多种常见 flag 名称，避免命令层自己写重复提取逻辑。
    for (final name in optionNames) {
      final value = CliArguments(args).value(name);
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    if (!allowPositional) {
      return '';
    }
    return CliArguments(args).positionalText().trim();
  }

  static Future<String> _defaultStdinReader() async {
    // 中文注释: 默认 stdin 读取用于管道输入，只有在命令层确认不是交互式会话时才会调用。
    return utf8.decoder.bind(stdin).join();
  }

  static bool _defaultStdinHasTerminal() => stdin.hasTerminal;
}
