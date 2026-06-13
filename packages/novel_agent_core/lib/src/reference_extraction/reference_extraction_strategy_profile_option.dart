class ReferenceExtractionStrategyProfileOption {
  const ReferenceExtractionStrategyProfileOption({
    required this.profileId,
    required this.displayName,
    required this.summary,
    required this.proposalCountLabel,
    required this.entryKindsLabel,
    required this.reviewPolicyLabel,
    required this.isBuiltin,
  });

  final String profileId;
  final String displayName;
  final String summary;
  final String proposalCountLabel;
  final String entryKindsLabel;
  final String reviewPolicyLabel;
  final bool isBuiltin;
}
