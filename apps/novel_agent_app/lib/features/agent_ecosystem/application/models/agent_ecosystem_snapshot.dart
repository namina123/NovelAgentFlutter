import 'package:novel_agent_core/novel_agent_core.dart';

class AgentEcosystemSnapshot {
  const AgentEcosystemSnapshot({
    required this.activeTabId,
    required this.selectedEntryIds,
    required this.agents,
    required this.skills,
    required this.skillGroups,
    required this.agentGroups,
  });

  final String activeTabId;
  final Map<String, String> selectedEntryIds;
  final List<JsonMap> agents;
  final List<JsonMap> skills;
  final List<JsonMap> skillGroups;
  final List<JsonMap> agentGroups;

  factory AgentEcosystemSnapshot.initial() {
    return const AgentEcosystemSnapshot(
      activeTabId: 'agents',
      selectedEntryIds: <String, String>{},
      agents: <JsonMap>[],
      skills: <JsonMap>[],
      skillGroups: <JsonMap>[],
      agentGroups: <JsonMap>[],
    );
  }

  AgentEcosystemSnapshot copyWith({
    String? activeTabId,
    Map<String, String>? selectedEntryIds,
    List<JsonMap>? agents,
    List<JsonMap>? skills,
    List<JsonMap>? skillGroups,
    List<JsonMap>? agentGroups,
  }) {
    // 中文注释: 生态快照和展示态分离后，控制器只维护原始目录数据，不需要在多个回调里反复手工拼 view data。
    return AgentEcosystemSnapshot(
      activeTabId: activeTabId ?? this.activeTabId,
      selectedEntryIds: selectedEntryIds ?? this.selectedEntryIds,
      agents: agents ?? this.agents,
      skills: skills ?? this.skills,
      skillGroups: skillGroups ?? this.skillGroups,
      agentGroups: agentGroups ?? this.agentGroups,
    );
  }

  List<JsonMap> entriesForTab(String tabId) {
    switch (tabId) {
      case 'skills':
        return skills;
      case 'skill-groups':
        return skillGroups;
      case 'agent-groups':
        return agentGroups;
      case 'skill-loadouts':
        return agents;
      case 'agents':
      default:
        return agents;
    }
  }

  String selectedEntryIdForTab(String tabId) {
    return selectedEntryIds[tabId] ?? '';
  }
}
