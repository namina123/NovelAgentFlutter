class AgentEffortService {
  String normalizeEffort(String value) {
    // 中文注释: 推理强度只接受核心支持的枚举，未知值统一回到 high，避免运行参数飘散。
    final normalized = value.trim().toLowerCase();
    if (const <String>{'low', 'medium', 'high', 'xhigh'}.contains(normalized)) {
      return normalized;
    }
    return 'high';
  }
}
