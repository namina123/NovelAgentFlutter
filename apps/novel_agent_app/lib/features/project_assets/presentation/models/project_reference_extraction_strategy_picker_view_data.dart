class ProjectReferenceExtractionStrategyPickerViewData {
  const ProjectReferenceExtractionStrategyPickerViewData({
    required this.selectedProfileId,
    required this.summary,
    required this.options,
  });

  final String selectedProfileId;
  final String summary;
  final List<ProjectReferenceExtractionStrategyOptionViewData> options;

  factory ProjectReferenceExtractionStrategyPickerViewData.empty() {
    return const ProjectReferenceExtractionStrategyPickerViewData(
      selectedProfileId: '',
      summary: '',
      options: <ProjectReferenceExtractionStrategyOptionViewData>[],
    );
  }
}

class ProjectReferenceExtractionStrategyOptionViewData {
  const ProjectReferenceExtractionStrategyOptionViewData({
    required this.profileId,
    required this.displayName,
    required this.summary,
    required this.proposalCountLabel,
    required this.entryKindsLabel,
    required this.reviewPolicyLabel,
    required this.badgeLabel,
  });

  final String profileId;
  final String displayName;
  final String summary;
  final String proposalCountLabel;
  final String entryKindsLabel;
  final String reviewPolicyLabel;
  final String badgeLabel;
}
