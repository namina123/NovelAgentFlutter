enum AgentSkillLoadoutSource {
  agentDefault,
  projectSelection,
  historyRestore,
  savedPreset,
  adHoc,
}

extension AgentSkillLoadoutSourceValue on AgentSkillLoadoutSource {
  String get id {
    switch (this) {
      case AgentSkillLoadoutSource.agentDefault:
        return 'agent_default';
      case AgentSkillLoadoutSource.projectSelection:
        return 'project_selection';
      case AgentSkillLoadoutSource.historyRestore:
        return 'history_restore';
      case AgentSkillLoadoutSource.savedPreset:
        return 'saved_preset';
      case AgentSkillLoadoutSource.adHoc:
        return 'ad_hoc';
    }
  }
}
