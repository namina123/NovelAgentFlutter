import '../session/session_descriptor.dart';

class StartSessionUseCase {
  const StartSessionUseCase();

  Future<SessionDescriptor> execute({
    required String sessionId,
    required String projectId,
    required String title,
  }) async {
    // 中文注释: 这里未来负责启动会话的核心规则，目前先保留统一用例入口。
    return SessionDescriptor(id: sessionId, projectId: projectId, title: title);
  }
}
