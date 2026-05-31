class AgentSkillLoadoutScope {
  const AgentSkillLoadoutScope({
    this.projectTypeIds = const <String>[],
    this.agentGroupIds = const <String>[],
    this.modeIds = const <String>[],
    this.stageIds = const <String>[],
  });

  final List<String> projectTypeIds;
  final List<String> agentGroupIds;
  final List<String> modeIds;
  final List<String> stageIds;

  bool get isGlobal =>
      projectTypeIds.isEmpty &&
      agentGroupIds.isEmpty &&
      modeIds.isEmpty &&
      stageIds.isEmpty;
}
