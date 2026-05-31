class AgentApplicabilityScope {
  const AgentApplicabilityScope({
    this.allowedProjectTypeIds = const <String>[],
    this.requiredTraitIds = const <String>[],
    this.excludedTraitIds = const <String>[],
    this.allowedModeIds = const <String>[],
    this.allowedStageIds = const <String>[],
  });

  final List<String> allowedProjectTypeIds;
  final List<String> requiredTraitIds;
  final List<String> excludedTraitIds;
  final List<String> allowedModeIds;
  final List<String> allowedStageIds;

  bool get isUnrestricted =>
      allowedProjectTypeIds.isEmpty &&
      requiredTraitIds.isEmpty &&
      excludedTraitIds.isEmpty &&
      allowedModeIds.isEmpty &&
      allowedStageIds.isEmpty;
}
