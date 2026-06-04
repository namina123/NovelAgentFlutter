import '../common/json_types.dart';
import '../continuity/narrative_state/narrative_profile_proposal.dart';
import '../continuity/narrative_state/narrative_semantic_review.dart';
import '../continuity/narrative_state/narrative_state_claim.dart';

class BookDeconstructionNarrativeArtifactBundle {
  const BookDeconstructionNarrativeArtifactBundle({
    this.claims = const <NarrativeStateClaim>[],
    this.profileProposals = const <NarrativeProfileProposal>[],
    this.semanticReviews = const <NarrativeSemanticReview>[],
    this.metadata = const <String, Object?>{},
  });

  final List<NarrativeStateClaim> claims;
  final List<NarrativeProfileProposal> profileProposals;
  final List<NarrativeSemanticReview> semanticReviews;
  final JsonMap metadata;

  bool get isEmpty {
    return claims.isEmpty &&
        profileProposals.isEmpty &&
        semanticReviews.isEmpty &&
        metadata.isEmpty;
  }

  BookDeconstructionNarrativeArtifactBundle copyWith({
    List<NarrativeStateClaim>? claims,
    List<NarrativeProfileProposal>? profileProposals,
    List<NarrativeSemanticReview>? semanticReviews,
    JsonMap? metadata,
  }) {
    return BookDeconstructionNarrativeArtifactBundle(
      claims: claims ?? this.claims,
      profileProposals: profileProposals ?? this.profileProposals,
      semanticReviews: semanticReviews ?? this.semanticReviews,
      metadata: metadata ?? this.metadata,
    );
  }
}
