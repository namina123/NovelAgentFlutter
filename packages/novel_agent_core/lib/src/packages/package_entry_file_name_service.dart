class PackageEntryFileNameService {
  bool isAgentEntryFile(String fileName) {
    // 中文注释: 智能体入口文件名大小写不敏感，保证 Windows、Android 和手工拷贝场景都能稳定识别。
    final normalized = fileName.trim().toLowerCase();
    return normalized == 'agent.md' || normalized == 'agent.json';
  }

  bool isSkillEntryFile(String fileName) {
    // 中文注释: 技能入口文件名也按大小写不敏感处理，避免把包规范写成过于脆弱的大小写约束。
    final normalized = fileName.trim().toLowerCase();
    return normalized == 'skill.md' || normalized == 'skill.json';
  }
}
