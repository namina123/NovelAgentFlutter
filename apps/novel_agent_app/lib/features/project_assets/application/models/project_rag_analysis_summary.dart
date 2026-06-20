class ProjectRagAnalysisSummary {
  const ProjectRagAnalysisSummary({
    required this.storyOutlineSummary,
    required this.premiseSummary,
    required this.styleSummary,
    required this.chapterTitles,
    required this.characterNames,
    required this.organizationNames,
    required this.worldRuleTitles,
    required this.relationshipPairs,
    required this.timelineLabels,
    required this.foreshadowTitles,
  });

  final String storyOutlineSummary;
  final String premiseSummary;
  final String styleSummary;
  final List<String> chapterTitles;
  final List<String> characterNames;
  final List<String> organizationNames;
  final List<String> worldRuleTitles;
  final List<String> relationshipPairs;
  final List<String> timelineLabels;
  final List<String> foreshadowTitles;

  bool get isEmpty =>
      storyOutlineSummary.trim().isEmpty &&
      premiseSummary.trim().isEmpty &&
      styleSummary.trim().isEmpty &&
      chapterTitles.isEmpty &&
      characterNames.isEmpty &&
      organizationNames.isEmpty &&
      worldRuleTitles.isEmpty &&
      relationshipPairs.isEmpty &&
      timelineLabels.isEmpty &&
      foreshadowTitles.isEmpty;

  factory ProjectRagAnalysisSummary.empty() {
    return const ProjectRagAnalysisSummary(
      storyOutlineSummary: '',
      premiseSummary: '',
      styleSummary: '',
      chapterTitles: <String>[],
      characterNames: <String>[],
      organizationNames: <String>[],
      worldRuleTitles: <String>[],
      relationshipPairs: <String>[],
      timelineLabels: <String>[],
      foreshadowTitles: <String>[],
    );
  }
}
