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
    return '当前项目已确定默认协作组，写作时会沿用这套协作摘要。';
  }

  String unconfiguredProjectPanelSummary() {
    return '当前项目还没有确定默认协作组，建议先补上再开始正式写作。';
  }

  String configureProjectPanelActionDescription({
    required bool hasResolvedGroup,
  }) {
    if (hasResolvedGroup) {
      return '查看当前项目协作摘要，并按需调整默认协作组。';
    }
    return '先确认当前项目该由哪组协作方式负责开局和后续写作。';
  }

  String workspaceSelectionHint() {
    return '这里负责当前项目的默认智能体组配置；当前会话实际使用的智能体由会话层单独决定。';
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
