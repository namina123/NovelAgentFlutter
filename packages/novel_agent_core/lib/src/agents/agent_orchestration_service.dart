class AgentOrchestrationService {
  String normalizeOrchestration(String value) {
    // 中文注释: 智能体组编排方式必须收敛到已知策略，避免不同宿主各自理解未知值。
    final normalized = value.trim().toLowerCase();
    if (const <String>{
      'manual',
      'supervised',
      'auto',
      'main_with_children',
      'pipeline',
      'debate',
      'voting',
    }.contains(normalized)) {
      return normalized;
    }
    return 'supervised';
  }
}
