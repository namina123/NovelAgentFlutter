import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

class DesktopProcessRunner implements ProcessRunner {
  @override
  Future<ProcessRunResult> run({
    required String executable,
    required List<String> arguments,
    String? workingDirectory,
    Duration? timeout,
  }) async {
    // 中文注释: 桌面端进程执行统一封在这里，GUI/CLI 的命令工具可以共用同一份宿主能力实现。
    final result = await Process.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      runInShell: false,
    ).timeout(timeout ?? const Duration(seconds: 60));
    return ProcessRunResult(
      exitCode: result.exitCode,
      stdout: '${result.stdout ?? ''}',
      stderr: '${result.stderr ?? ''}',
    );
  }
}
