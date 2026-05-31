class SkillLoadMemory {
  SkillLoadMemory({this.scopeId = ''});

  final String scopeId;
  final Map<String, String> _detailBySkill = <String, String>{};
  final Map<String, Set<String>> _referencesBySkill = <String, Set<String>>{};

  bool hasSummary(String skillId) {
    // 中文注释: 只要这个技能读过摘要、全文或 reference，都视为已具备摘要级记忆。
    return _detailBySkill.containsKey(skillId.trim());
  }

  bool hasFull(String skillId) {
    // 中文注释: full 级别单独判断，避免摘要和全文混成同一层。
    return _detailBySkill[skillId.trim()] == 'full';
  }

  bool hasReference(String skillId, String referencePath) {
    // 中文注释: reference 记忆按技能内相对路径精确去重，防止重复细读同一份说明。
    final references = _referencesBySkill[skillId.trim()];
    if (references == null) {
      return false;
    }
    return references.contains(referencePath.trim());
  }

  void markSummary(String skillId) {
    // 中文注释: 摘要标记不覆盖 full，只在首次加载时补记。
    final normalized = skillId.trim();
    if (normalized.isEmpty || _detailBySkill.containsKey(normalized)) {
      return;
    }
    _detailBySkill[normalized] = 'summary';
  }

  void markFull(String skillId) {
    // 中文注释: full 一旦成立，就提升这个技能的已读层级。
    final normalized = skillId.trim();
    if (normalized.isEmpty) {
      return;
    }
    _detailBySkill[normalized] = 'full';
  }

  void markReference(String skillId, String referencePath) {
    // 中文注释: reference 默认也意味着摘要已可用，因为调用前必须已经定位到这个技能。
    final normalizedSkillId = skillId.trim();
    final normalizedReferencePath = referencePath.trim();
    if (normalizedSkillId.isEmpty || normalizedReferencePath.isEmpty) {
      return;
    }
    markSummary(normalizedSkillId);
    _referencesBySkill.putIfAbsent(normalizedSkillId, () => <String>{}).add(
      normalizedReferencePath,
    );
  }

  List<String> loadedSkillIds() {
    // 中文注释: 这里给提示构建层提供稳定顺序的已加载技能列表。
    return _detailBySkill.keys.toList(growable: false);
  }

  String detailLevelForSkill(String skillId) {
    return _detailBySkill[skillId.trim()] ?? '';
  }

  List<String> loadedReferencesForSkill(String skillId) {
    final references = _referencesBySkill[skillId.trim()];
    if (references == null) {
      return const <String>[];
    }
    return references.toList(growable: false);
  }
}
