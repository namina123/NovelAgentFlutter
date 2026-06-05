class SkillCapabilityCatalogService {
  const SkillCapabilityCatalogService();

  static const String projectRead = 'project_read';
  static const String projectWrite = 'project_write';
  static const String networkAccess = 'network_access';
  static const String formalDelivery = 'formal_delivery';
  static const String userInteraction = 'user_interaction';
  static const String longTaskControl = 'long_task_control';
  static const String semanticReview = 'semantic_review';

  List<String> capabilityIds() {
    // 中文注释: 能力词表集中维护，避免技能校验、权限画像和兼容检查各自长出一套近义词。
    return const <String>[
      projectRead,
      projectWrite,
      networkAccess,
      formalDelivery,
      userInteraction,
      longTaskControl,
      semanticReview,
    ];
  }

  bool isKnownCapability(String capabilityId) {
    // 中文注释: 技能能力需求只接受当前受支持的抽象能力，未知值需要被显式暴露而不是静默吞掉。
    return capabilityIds().contains(capabilityId.trim());
  }

  String displayLabel(String capabilityId) {
    // 中文注释: 用户可理解文案也收口在能力目录里，避免多个服务各自拼不同说法。
    switch (capabilityId.trim()) {
      case projectRead:
        return '项目读取权限';
      case projectWrite:
        return '项目写入权限';
      case networkAccess:
        return '联网权限';
      case formalDelivery:
        return '正式交付权限';
      case userInteraction:
        return '用户交互权限';
      case longTaskControl:
        return '长任务控制权限';
      case semanticReview:
        return '语义审稿提交权限';
      default:
        return capabilityId.trim().isEmpty ? '未知能力' : capabilityId.trim();
    }
  }
}
