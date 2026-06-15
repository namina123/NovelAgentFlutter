import '../continuity/continuity_build_spec.dart';
import 'book_deconstruction_continuation_direction.dart';
import 'book_deconstruction_source_inheritance_mode.dart';

class BookDeconstructionDerivedProjectPlan {
  const BookDeconstructionDerivedProjectPlan({
    required this.planId,
    required this.sourceExtractionId,
    required this.sourceProjectTitle,
    required this.followupOptionId,
    required this.targetProjectTypeId,
    required this.targetProjectStrategyId,
    this.targetModeId = '',
    this.sourceInheritanceMode =
        BookDeconstructionSourceInheritanceMode.continuation,
    this.preferredDirection =
        BookDeconstructionContinuationDirection.analysisFirst,
    this.recommendedBuildTier = ContinuityBuildTier.standardFoundation,
    this.suggestedProjectTitle = '',
    this.metadata = const <String, Object?>{},
  });

  final String planId;
  final String sourceExtractionId;
  final String sourceProjectTitle;
  final String followupOptionId;
  final String targetProjectTypeId;
  final String targetProjectStrategyId;
  final String targetModeId;
  final BookDeconstructionSourceInheritanceMode sourceInheritanceMode;
  final BookDeconstructionContinuationDirection preferredDirection;
  final ContinuityBuildTier recommendedBuildTier;
  final String suggestedProjectTitle;
  final Map<String, Object?> metadata;
}
