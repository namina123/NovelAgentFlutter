class ProjectSkillLoadoutWorkspaceViewData {
  const ProjectSkillLoadoutWorkspaceViewData({
    required this.browserItems,
    required this.detail,
    required this.projectAvailable,
    required this.statusMessage,
  });

  final List<ProjectSkillLoadoutBrowserItemViewData> browserItems;
  final ProjectSkillLoadoutDetailViewData? detail;
  final bool projectAvailable;
  final String statusMessage;
}

class ProjectSkillLoadoutBrowserItemViewData {
  const ProjectSkillLoadoutBrowserItemViewData({
    required this.agentId,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.description,
    required this.isSelected,
  });

  final String agentId;
  final String title;
  final String subtitle;
  final String badge;
  final String description;
  final bool isSelected;
}

class ProjectSkillLoadoutDetailViewData {
  const ProjectSkillLoadoutDetailViewData({
    required this.agentId,
    required this.agentName,
    required this.agentDescription,
    required this.sourceLabel,
    required this.summary,
    required this.expressionConstraintSummary,
    required this.hasPendingChanges,
    required this.skillGroups,
    required this.extraSkills,
    required this.resolvedSkills,
    required this.historyEntries,
    required this.issues,
  });

  final String agentId;
  final String agentName;
  final String agentDescription;
  final String sourceLabel;
  final String summary;
  final String expressionConstraintSummary;
  final bool hasPendingChanges;
  final List<ProjectSkillLoadoutSelectableItemViewData> skillGroups;
  final List<ProjectSkillLoadoutSelectableItemViewData> extraSkills;
  final List<ProjectSkillLoadoutResolvedSkillViewData> resolvedSkills;
  final List<ProjectSkillLoadoutHistoryItemViewData> historyEntries;
  final List<String> issues;
}

class ProjectSkillLoadoutSelectableItemViewData {
  const ProjectSkillLoadoutSelectableItemViewData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.selected,
  });

  final String id;
  final String title;
  final String subtitle;
  final bool selected;
}

class ProjectSkillLoadoutResolvedSkillViewData {
  const ProjectSkillLoadoutResolvedSkillViewData({
    required this.id,
    required this.title,
    required this.sourceSummary,
    required this.enabled,
    required this.isUnavailable,
    required this.statusLabel,
  });

  final String id;
  final String title;
  final String sourceSummary;
  final bool enabled;
  final bool isUnavailable;
  final String statusLabel;
}

class ProjectSkillLoadoutHistoryItemViewData {
  const ProjectSkillLoadoutHistoryItemViewData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.summary,
  });

  final String id;
  final String title;
  final String subtitle;
  final String summary;
}
