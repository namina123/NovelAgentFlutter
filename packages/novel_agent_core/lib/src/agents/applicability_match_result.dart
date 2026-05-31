class ApplicabilityMatchResult {
  const ApplicabilityMatchResult({
    required this.matches,
    this.projectTypeAllowed = true,
    this.modeAllowed = true,
    this.stageAllowed = true,
    this.missingRequiredTraitIds = const <String>[],
    this.excludedTraitIds = const <String>[],
  });

  final bool matches;
  final bool projectTypeAllowed;
  final bool modeAllowed;
  final bool stageAllowed;
  final List<String> missingRequiredTraitIds;
  final List<String> excludedTraitIds;
}
