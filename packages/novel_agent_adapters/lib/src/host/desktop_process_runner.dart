import 'package:novel_agent_core/novel_agent_core.dart';

class DesktopProcessRunner implements ProcessRunner {
  @override
  Future<ProcessRunResult> run({
    required String executable,
    required List<String> arguments,
  }) {
    // 中文注释: 这里未来负责桌面端进程执行，移动端不得复用此实现。
    throw UnimplementedError('待实现桌面进程执行器。');
  }
}
