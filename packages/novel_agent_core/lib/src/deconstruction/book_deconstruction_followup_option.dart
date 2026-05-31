import '../continuity/continuity_build_spec.dart';

class BookDeconstructionFollowupOption {
  const BookDeconstructionFollowupOption({
    required this.id,
    required this.title,
    required this.summary,
    required this.targetProjectTypeId,
    required this.targetProjectStrategyId,
    this.targetModeId = '',
    this.recommendedBuildTier = ContinuityBuildTier.standardFoundation,
    this.allowsMultipleDerivedProjects = true,
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String title;
  final String summary;
  final String targetProjectTypeId;
  final String targetProjectStrategyId;
  final String targetModeId;
  final ContinuityBuildTier recommendedBuildTier;
  final bool allowsMultipleDerivedProjects;
  final Map<String, Object?> metadata;
}
