class ConversationGroupDisplayTextPolicy {
  const ConversationGroupDisplayTextPolicy();

  static const String unresolvedGroupLabel = '未确定智能体组';
  static const String defaultPrimaryAgentLabel = '综合创作智能体';

  String currentGroupLabel(String? label) {
    final cleanLabel = label?.trim() ?? '';
    if (cleanLabel.isEmpty) {
      return unresolvedGroupLabel;
    }
    return cleanLabel;
  }

  String? headerSubtitle(String? groupLabel) {
    final resolvedLabel = currentGroupLabel(groupLabel);
    if (resolvedLabel == unresolvedGroupLabel) {
      return null;
    }
    return resolvedLabel;
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

  String primaryAgentDescription(String? role) {
    return role?.trim() ?? '';
  }

  bool hasResolvedGroup(String? groupLabel) {
    return headerSubtitle(groupLabel) != null;
  }

  String configuredProjectSummary() {
    return '当前项目已绑定默认协作组，新会话会沿用这套协作基线。';
  }

  String unconfiguredProjectSummary() {
    return '当前项目还没有确定默认协作组。';
  }

  String configureProjectActionDescription({required bool hasResolvedGroup}) {
    if (hasResolvedGroup) {
      return '查看当前项目支持的智能体组，并调整默认协作基线。';
    }
    return '查看当前项目支持的智能体组，并确定默认协作基线。';
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
