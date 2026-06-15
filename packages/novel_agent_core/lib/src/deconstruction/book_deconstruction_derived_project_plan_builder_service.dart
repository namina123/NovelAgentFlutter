import 'book_deconstruction_derived_project_plan.dart';
import 'book_deconstruction_derived_project_narrative_inheritance_service.dart';
import 'book_deconstruction_followup_menu.dart';
import 'book_deconstruction_followup_option.dart';
import 'book_deconstruction_input.dart';
import 'book_deconstruction_narrative_artifact_bundle.dart';

class BookDeconstructionDerivedProjectPlanBuilderService {
  const BookDeconstructionDerivedProjectPlanBuilderService({
    BookDeconstructionDerivedProjectNarrativeInheritanceService?
    narrativeInheritanceService,
  }) : _narrativeInheritanceService =
           narrativeInheritanceService ??
           const BookDeconstructionDerivedProjectNarrativeInheritanceService();

  final BookDeconstructionDerivedProjectNarrativeInheritanceService
  _narrativeInheritanceService;

  BookDeconstructionDerivedProjectPlan build({
    required BookDeconstructionInput input,
    required BookDeconstructionFollowupMenu followupMenu,
    required String followupOptionId,
    BookDeconstructionNarrativeArtifactBundle? narrativeArtifacts,
  }) {
    final option = _resolveOption(followupMenu, followupOptionId);
    final inheritedEntries = narrativeArtifacts == null
        ? const []
        : _narrativeInheritanceService.buildEntries(
            narrativeArtifacts: narrativeArtifacts,
          );
    return BookDeconstructionDerivedProjectPlan(
      planId: 'derive_${input.extractionId}_${option.id}',
      sourceExtractionId: input.extractionId,
      sourceProjectTitle: input.title,
      followupOptionId: option.id,
      targetProjectTypeId: option.targetProjectTypeId,
      targetProjectStrategyId: option.targetProjectStrategyId,
      targetModeId: option.targetModeId,
      sourceInheritanceMode: option.sourceInheritanceMode,
      preferredDirection: input.preferredContinuationDirection,
      recommendedBuildTier: option.recommendedBuildTier,
      suggestedProjectTitle: _suggestedProjectTitle(input.title, option),
      metadata: <String, Object?>{
        'source_project_type_id': input.targetProjectTypeId,
        'source_project_strategy_id': input.projectStrategyId,
        'source_inheritance_mode': option.sourceInheritanceMode.name,
        'inherited_narrative_artifacts': inheritedEntries
            .map((entry) => entry.toJson())
            .toList(growable: false),
      },
    );
  }

  BookDeconstructionFollowupOption _resolveOption(
    BookDeconstructionFollowupMenu followupMenu,
    String followupOptionId,
  ) {
    final cleanId = followupOptionId.trim();
    for (final group in followupMenu.groups) {
      for (final option in group.options) {
        if (option.id == cleanId) {
          return option;
        }
      }
    }
    throw StateError('未找到拆书后续路线：$cleanId');
  }

  String _suggestedProjectTitle(
    String sourceTitle,
    BookDeconstructionFollowupOption option,
  ) {
    final cleanSourceTitle = sourceTitle.trim().isEmpty
        ? '未命名拆书源'
        : sourceTitle.trim();
    final cleanMode = option.title.trim();
    return '$cleanSourceTitle - $cleanMode';
  }
}
