import '../continuity/narrative_state/narrative_state_claim.dart';
import 'book_deconstruction_artifact_kind.dart';
import 'book_deconstruction_draft_build_result.dart';
import 'book_deconstruction_narrative_artifact_bundle.dart';

/// Restricts durable analysis artifacts to the application items the user chose.
///
/// Claims map one-to-one to visible application items. Aggregate artifacts (a
/// profile proposal, review, and information bridge output) only remain valid
/// when the entire application plan is selected, because they summarize all
/// extracted facts rather than one selected item.
class BookDeconstructionNarrativeArtifactSelectionService {
  const BookDeconstructionNarrativeArtifactSelectionService();

  BookDeconstructionNarrativeArtifactBundle select({
    required BookDeconstructionDraftBuildResult buildResult,
    required Set<String> selectedItemIds,
  }) {
    final planItems = buildResult.applicationPlan.items;
    final selectedArtifactKeys = planItems
        .where((item) => selectedItemIds.contains(item.id))
        .map((item) => _artifactKey(item.sourceKind, item.sourceId))
        .toSet();
    final selectedEverything =
        planItems.isNotEmpty &&
        planItems.every((item) => selectedItemIds.contains(item.id));
    if (selectedEverything) {
      return buildResult.narrativeArtifacts;
    }

    return BookDeconstructionNarrativeArtifactBundle(
      claims: buildResult.narrativeArtifacts.claims
          .where(
            (claim) =>
                selectedArtifactKeys.contains(_artifactKeyForClaim(claim)),
          )
          .toList(growable: false),
    );
  }

  String? _artifactKeyForClaim(NarrativeStateClaim claim) {
    final payload = claim.claimPayload;
    switch (claim.claimNamespace) {
      case 'analysis.deconstruction.premise':
        return _artifactKey(
          BookDeconstructionArtifactKind.premise,
          _stringValue(payload['premise_id']),
        );
      case 'analysis.deconstruction.story_outline':
        return _artifactKey(
          BookDeconstructionArtifactKind.storyOutline,
          'main',
        );
      case 'analysis.deconstruction.chapter_outline':
        return _artifactKey(
          BookDeconstructionArtifactKind.chapterOutline,
          _stringValue(payload['chapter_id']),
        );
      case 'analysis.deconstruction.style_profile':
        return _artifactKey(
          BookDeconstructionArtifactKind.styleProfile,
          _stringValue(payload['profile_id']),
        );
      case 'analysis.deconstruction.world_rule_set':
        return _artifactKey(
          BookDeconstructionArtifactKind.worldRuleSet,
          _stringValue(payload['rule_set_id']),
        );
      case 'analysis.deconstruction.character_profile':
        return _artifactKey(
          BookDeconstructionArtifactKind.characterProfile,
          _stringValue(payload['character_id']),
        );
      case 'analysis.deconstruction.organization_profile':
        return _artifactKey(
          BookDeconstructionArtifactKind.organizationProfile,
          _stringValue(payload['organization_id']),
        );
      case 'analysis.deconstruction.foreshadow_record':
        return _artifactKey(
          BookDeconstructionArtifactKind.foreshadowRecord,
          _stringValue(payload['foreshadow_id']),
        );
      case 'analysis.deconstruction.timeline_record':
        return _artifactKey(
          BookDeconstructionArtifactKind.timelineRecord,
          _stringValue(payload['timeline_id']),
        );
      case 'analysis.deconstruction.relationship_record':
        return _artifactKey(
          BookDeconstructionArtifactKind.relationshipRecord,
          _stringValue(payload['relationship_id']),
        );
      default:
        return null;
    }
  }

  String _artifactKey(String kind, String sourceId) {
    final cleanKind = kind.trim();
    final cleanSourceId = sourceId.trim();
    if (cleanKind.isEmpty || cleanSourceId.isEmpty) {
      return '';
    }
    return '$cleanKind:$cleanSourceId';
  }

  String _stringValue(Object? value) => value is String ? value.trim() : '';
}
