class ProjectAgentGroupSelection {
  const ProjectAgentGroupSelection({
    required this.groupId,
    this.displayName = '',
    this.enabled = true,
    this.selectedByDefault = false,
    this.taskFamilyIds = const <String>[],
    this.modeIds = const <String>[],
    this.stageIds = const <String>[],
    this.metadata = const <String, Object?>{},
  });

  final String groupId;
  final String displayName;
  final bool enabled;
  final bool selectedByDefault;
  final List<String> taskFamilyIds;
  final List<String> modeIds;
  final List<String> stageIds;
  final Map<String, Object?> metadata;
}
