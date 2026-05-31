class ExpressionConstraintScope {
  const ExpressionConstraintScope({
    this.projectTypeIds = const <String>[],
    this.agentIds = const <String>[],
    this.modeIds = const <String>[],
    this.stageIds = const <String>[],
  });

  final List<String> projectTypeIds;
  final List<String> agentIds;
  final List<String> modeIds;
  final List<String> stageIds;

  bool get isGlobal =>
      projectTypeIds.isEmpty &&
      agentIds.isEmpty &&
      modeIds.isEmpty &&
      stageIds.isEmpty;
}
