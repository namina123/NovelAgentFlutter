class ProjectAgentGroupDisplayTextPolicy {
  const ProjectAgentGroupDisplayTextPolicy();

  static const String unresolvedGroupLabel = '未确定智能体组';
  static const String defaultPrimaryAgentLabel = '综合创作智能体';

  String currentGroupLabel(String? label) {
    final cleanLabel = label?.trim() ?? '';
    if (cleanLabel.isEmpty) {
      return unresolvedGroupLabel;
    }
    return cleanLabel;
  }

  bool hasResolvedGroup(String? groupLabel) {
    return currentGroupLabel(groupLabel) != unresolvedGroupLabel;
  }

  String primaryAgentLabel(String? label, {String? fallbackLabel}) {
    final preferredLabel = _sanitizeUserFacingLabel(label);
    if (preferredLabel != null) {
      return preferredLabel;
    }
    final fallback = _sanitizeUserFacingLabel(fallbackLabel);
    if (fallback != null) {
      return fallback;
    }
    return defaultPrimaryAgentLabel;
  }

  String configuredProjectPanelSummary() {
    return '当前项目已确定默认协作组。';
  }

  String unconfiguredProjectPanelSummary() {
    return '当前项目还没有确定默认协作组。';
  }

  String workspaceSelectionHint() {
    return '这里用于设置当前项目的默认协作组。';
  }

  String? _sanitizeUserFacingLabel(String? rawLabel) {
    final cleanLabel = rawLabel?.trim() ?? '';
    if (cleanLabel.isEmpty) {
      return null;
    }
    if (_looksLikeInternalIdentifier(cleanLabel)) {
      return null;
    }
    return cleanLabel;
  }

  bool _looksLikeInternalIdentifier(String value) {
    final lowerValue = value.trim().toLowerCase();
    if (lowerValue.contains('_')) {
      return true;
    }
    if (lowerValue.startsWith('default-') ||
        lowerValue.startsWith('starter-') ||
        lowerValue.startsWith('seed-') ||
        lowerValue.startsWith('group-') ||
        lowerValue.startsWith('agent-')) {
      return true;
    }
    return RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+){2,}$').hasMatch(lowerValue);
  }
}
