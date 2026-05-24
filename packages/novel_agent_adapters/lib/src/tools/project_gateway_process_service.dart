import 'dart:async';
import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

class ProjectGatewayProcessService {
  ProjectGatewayProcessService({ProcessRunner? processRunner})
    : _processRunner = processRunner;

  final ProcessRunner? _processRunner;

  Future<GatewayProcessExecutionResult> runCommand(JsonMap arguments) async {
    // 中文注释: 命令执行只负责宿主进程调用本身，命令解析与工具结果格式化交给更外层协作类。
    if (!(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      throw UnsupportedError('当前平台不支持宿主命令执行。');
    }
    final executable = ValueReaders.stringValue(arguments['executable']).trim();
    final command = ValueReaders.stringValue(arguments['command']).trim();
    final timeoutMs = ValueReaders.intValue(arguments['timeout_ms'], 60000);
    final timeout = Duration(
      milliseconds: timeoutMs <= 0 ? 60000 : timeoutMs.clamp(1000, 300000),
    );
    final workingDirectory = ValueReaders.stringValue(
      arguments['working_directory'],
      ValueReaders.stringValue(arguments['cwd']),
    ).trim();
    final commandArguments = ValueReaders.stringList(
      arguments['args'] ?? arguments['arguments_list'],
    );
    if (executable.isEmpty && command.isEmpty) {
      throw ArgumentError('command or executable is required.');
    }
    final planned = executable.isNotEmpty
        ? (executable: executable, arguments: commandArguments)
        : _shellCommandPlan(command);
    if (_processRunner != null) {
      final result = await _processRunner
          .run(
            executable: planned.executable,
            arguments: planned.arguments,
            workingDirectory: workingDirectory.isEmpty
                ? null
                : workingDirectory,
            timeout: timeout,
          )
          .timeout(timeout + const Duration(seconds: 2));
      return GatewayProcessExecutionResult(
        exitCode: result.exitCode,
        stdout: result.stdout,
        stderr: result.stderr,
        executable: planned.executable,
        arguments: planned.arguments,
      );
    }
    final result = await Process.run(
      planned.executable,
      planned.arguments,
      workingDirectory: workingDirectory.isEmpty ? null : workingDirectory,
      runInShell: false,
    ).timeout(timeout);
    return GatewayProcessExecutionResult(
      exitCode: result.exitCode,
      stdout: '${result.stdout ?? ''}',
      stderr: '${result.stderr ?? ''}',
      executable: planned.executable,
      arguments: planned.arguments,
    );
  }

  ({String executable, List<String> arguments}) _shellCommandPlan(
    String command,
  ) {
    // 中文注释: 字符串命令统一包进宿主 shell，避免上层同时维护 Windows 和 Unix 两套分发规则。
    if (Platform.isWindows) {
      return (
        executable: 'powershell',
        arguments: <String>['-NoProfile', '-Command', command],
      );
    }
    return (executable: '/bin/sh', arguments: <String>['-lc', command]);
  }
}

class GatewayProcessExecutionResult {
  const GatewayProcessExecutionResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    required this.executable,
    required this.arguments,
  });

  final int exitCode;
  final String stdout;
  final String stderr;
  final String executable;
  final List<String> arguments;
}
