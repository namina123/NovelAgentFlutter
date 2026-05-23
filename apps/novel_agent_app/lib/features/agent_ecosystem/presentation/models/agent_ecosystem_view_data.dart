class AgentEcosystemViewData {
  const AgentEcosystemViewData({
    required this.activeTabId,
    required this.tabs,
    required this.entries,
  });

  final String activeTabId;
  final List<EcosystemTabViewData> tabs;
  final List<EcosystemEntryViewData> entries;

  factory AgentEcosystemViewData.initial() {
    return const AgentEcosystemViewData(
      activeTabId: 'agents',
      tabs: [
        EcosystemTabViewData(id: 'agents', label: '智能体'),
        EcosystemTabViewData(id: 'skills', label: '技能'),
        EcosystemTabViewData(id: 'skill-groups', label: '技能组'),
        EcosystemTabViewData(id: 'agent-groups', label: '智能体组'),
      ],
      entries: [],
    );
  }

  factory AgentEcosystemViewData.demo() {
    return AgentEcosystemViewData.initial();
  }

  AgentEcosystemViewData copyWith({
    String? activeTabId,
    List<EcosystemTabViewData>? tabs,
    List<EcosystemEntryViewData>? entries,
  }) {
    // 中文注释: 生态状态通过局部 copy 保持稳定边界，避免某个 tab 行为影响整个应用壳层。
    return AgentEcosystemViewData(
      activeTabId: activeTabId ?? this.activeTabId,
      tabs: tabs ?? this.tabs,
      entries: entries ?? this.entries,
    );
  }
}

class EcosystemTabViewData {
  const EcosystemTabViewData({required this.id, required this.label});

  final String id;
  final String label;
}

class EcosystemEntryViewData {
  const EcosystemEntryViewData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.description,
    this.isSelected = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final String badge;
  final String description;
  final bool isSelected;
}
