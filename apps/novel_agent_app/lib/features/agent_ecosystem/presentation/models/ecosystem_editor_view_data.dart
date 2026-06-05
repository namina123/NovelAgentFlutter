class EcosystemEditorViewData {
  const EcosystemEditorViewData({
    required this.kind,
    required this.title,
    required this.entryId,
    required this.name,
    required this.description,
    required this.role,
    required this.objective,
    required this.bodyMarkdown,
    required this.badge,
    required this.projectRelativePath,
    required this.skillsText,
    required this.skillGroupsText,
    required this.agentsText,
    required this.activationHintsText,
    required this.inputsText,
    required this.outputsText,
    required this.canDoText,
    required this.mustNotDoText,
    required this.knowledgeSourcesText,
    required this.requiredCapabilitiesText,
    required this.optionalCapabilitiesText,
    required this.preferredOutput,
    required this.orchestration,
    required this.enabled,
    required this.statusMessage,
    required this.isProjectEntry,
    this.isBuiltinEntry = false,
    this.sourceSummary = '',
    this.permissionBoundarySummary = '',
    this.validationIssues = const <String>[],
    this.primaryAgentIdText = '',
    this.requiredAgentIdsText = '',
    this.optionalAgentIdsText = '',
    this.saveActionLabel = '保存',
    this.deleteActionLabel = '删除项目覆盖',
  });

  final String kind;
  final String title;
  final String entryId;
  final String name;
  final String description;
  final String role;
  final String objective;
  final String bodyMarkdown;
  final String badge;
  final String projectRelativePath;
  final String skillsText;
  final String skillGroupsText;
  final String agentsText;
  final String activationHintsText;
  final String inputsText;
  final String outputsText;
  final String canDoText;
  final String mustNotDoText;
  final String knowledgeSourcesText;
  final String requiredCapabilitiesText;
  final String optionalCapabilitiesText;
  final String preferredOutput;
  final String orchestration;
  final bool enabled;
  final String statusMessage;
  final bool isProjectEntry;
  final bool isBuiltinEntry;
  final String sourceSummary;
  final String permissionBoundarySummary;
  final List<String> validationIssues;
  final String primaryAgentIdText;
  final String requiredAgentIdsText;
  final String optionalAgentIdsText;
  final String saveActionLabel;
  final String deleteActionLabel;

  EcosystemEditorViewData copyWith({
    String? kind,
    String? title,
    String? entryId,
    String? name,
    String? description,
    String? role,
    String? objective,
    String? bodyMarkdown,
    String? badge,
    String? projectRelativePath,
    String? skillsText,
    String? skillGroupsText,
    String? agentsText,
    String? activationHintsText,
    String? inputsText,
    String? outputsText,
    String? canDoText,
    String? mustNotDoText,
    String? knowledgeSourcesText,
    String? requiredCapabilitiesText,
    String? optionalCapabilitiesText,
    String? preferredOutput,
    String? orchestration,
    bool? enabled,
    String? statusMessage,
    bool? isProjectEntry,
    bool? isBuiltinEntry,
    String? sourceSummary,
    String? permissionBoundarySummary,
    List<String>? validationIssues,
    String? primaryAgentIdText,
    String? requiredAgentIdsText,
    String? optionalAgentIdsText,
    String? saveActionLabel,
    String? deleteActionLabel,
  }) {
    // 中文注释: 编辑器状态允许只替换局部字段，避免每次提交前都整体重建表单默认值。
    return EcosystemEditorViewData(
      kind: kind ?? this.kind,
      title: title ?? this.title,
      entryId: entryId ?? this.entryId,
      name: name ?? this.name,
      description: description ?? this.description,
      role: role ?? this.role,
      objective: objective ?? this.objective,
      bodyMarkdown: bodyMarkdown ?? this.bodyMarkdown,
      badge: badge ?? this.badge,
      projectRelativePath: projectRelativePath ?? this.projectRelativePath,
      skillsText: skillsText ?? this.skillsText,
      skillGroupsText: skillGroupsText ?? this.skillGroupsText,
      agentsText: agentsText ?? this.agentsText,
      activationHintsText: activationHintsText ?? this.activationHintsText,
      inputsText: inputsText ?? this.inputsText,
      outputsText: outputsText ?? this.outputsText,
      canDoText: canDoText ?? this.canDoText,
      mustNotDoText: mustNotDoText ?? this.mustNotDoText,
      knowledgeSourcesText: knowledgeSourcesText ?? this.knowledgeSourcesText,
      requiredCapabilitiesText:
          requiredCapabilitiesText ?? this.requiredCapabilitiesText,
      optionalCapabilitiesText:
          optionalCapabilitiesText ?? this.optionalCapabilitiesText,
      preferredOutput: preferredOutput ?? this.preferredOutput,
      orchestration: orchestration ?? this.orchestration,
      enabled: enabled ?? this.enabled,
      statusMessage: statusMessage ?? this.statusMessage,
      isProjectEntry: isProjectEntry ?? this.isProjectEntry,
      isBuiltinEntry: isBuiltinEntry ?? this.isBuiltinEntry,
      sourceSummary: sourceSummary ?? this.sourceSummary,
      permissionBoundarySummary:
          permissionBoundarySummary ?? this.permissionBoundarySummary,
      validationIssues: validationIssues ?? this.validationIssues,
      primaryAgentIdText: primaryAgentIdText ?? this.primaryAgentIdText,
      requiredAgentIdsText: requiredAgentIdsText ?? this.requiredAgentIdsText,
      optionalAgentIdsText: optionalAgentIdsText ?? this.optionalAgentIdsText,
      saveActionLabel: saveActionLabel ?? this.saveActionLabel,
      deleteActionLabel: deleteActionLabel ?? this.deleteActionLabel,
    );
  }
}

class EcosystemEditorRequestViewData {
  const EcosystemEditorRequestViewData({
    required this.kind,
    required this.originalEntryId,
    required this.originalRelativePath,
    required this.entryId,
    required this.name,
    required this.description,
    required this.role,
    required this.objective,
    required this.bodyMarkdown,
    required this.skillsText,
    required this.skillGroupsText,
    required this.agentsText,
    required this.activationHintsText,
    required this.inputsText,
    required this.outputsText,
    required this.canDoText,
    required this.mustNotDoText,
    required this.knowledgeSourcesText,
    required this.requiredCapabilitiesText,
    required this.optionalCapabilitiesText,
    required this.preferredOutput,
    required this.orchestration,
    required this.enabled,
    this.primaryAgentIdText = '',
    this.requiredAgentIdsText = '',
    this.optionalAgentIdsText = '',
  });

  final String kind;
  final String originalEntryId;
  final String originalRelativePath;
  final String entryId;
  final String name;
  final String description;
  final String role;
  final String objective;
  final String bodyMarkdown;
  final String skillsText;
  final String skillGroupsText;
  final String agentsText;
  final String activationHintsText;
  final String inputsText;
  final String outputsText;
  final String canDoText;
  final String mustNotDoText;
  final String knowledgeSourcesText;
  final String requiredCapabilitiesText;
  final String optionalCapabilitiesText;
  final String preferredOutput;
  final String orchestration;
  final bool enabled;
  final String primaryAgentIdText;
  final String requiredAgentIdsText;
  final String optionalAgentIdsText;
}
