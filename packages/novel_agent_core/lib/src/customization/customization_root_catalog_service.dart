class CustomizationRootCatalogService {
  const CustomizationRootCatalogService();

  static const String agentsRoot = 'agents';
  static const String skillsRoot = 'skills';
  static const String skillGroupsRoot = 'skill_groups';
  static const String agentGroupsRoot = 'agent_groups';

  List<Map<String, String>> roots() {
    return const <Map<String, String>>[
      <String, String>{
        'root': agentsRoot,
        'entry_file': 'AGENT.md',
        'legacy_file': 'agent.json',
        'description': '用户自定义单体智能体。',
      },
      <String, String>{
        'root': skillsRoot,
        'entry_file': 'SKILL.md',
        'legacy_file': 'skill.json',
        'description': '用户自定义技能定义。',
      },
      <String, String>{
        'root': skillGroupsRoot,
        'entry_file': 'skill_group.json',
        'legacy_file': 'skill_group.json',
        'description': '用户自定义技能组。',
      },
      <String, String>{
        'root': agentGroupsRoot,
        'entry_file': 'agent_group.json',
        'legacy_file': 'agent_group.json',
        'description': '用户自定义智能体组与编排预设。',
      },
    ];
  }
}
