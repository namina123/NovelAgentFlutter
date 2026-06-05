import '../common/value_readers.dart';
import '../continuity/narrative_state/narrative_profile_lifecycle_status.dart';
import '../continuity/narrative_state/narrative_profile_proposal.dart';
import '../continuity/narrative_state/narrative_semantic_review.dart';
import '../continuity/narrative_state/narrative_state_claim.dart';
import 'book_deconstruction_narrative_artifact_bundle.dart';
import 'book_deconstruction_narrative_bridge_constants.dart';

class BookDeconstructionNarrativePromotionService {
  const BookDeconstructionNarrativePromotionService();

  BookDeconstructionNarrativeArtifactBundle promote({
    required BookDeconstructionNarrativeArtifactBundle analysisBundle,
    String claimStatus =
        BookDeconstructionNarrativeBridgeConstants.acceptedStatus,
    NarrativeProfileLifecycleStatus proposalStatus =
        NarrativeProfileLifecycleStatus.accepted,
    bool includeSemanticReviews = true,
    String promotedBy = 'user_confirmation',
  }) {
    return BookDeconstructionNarrativeArtifactBundle(
      claims: analysisBundle.claims
          .map(
            (claim) => _promotedClaim(
              claim,
              claimStatus: claimStatus,
              promotedBy: promotedBy,
            ),
          )
          .toList(growable: false),
      profileProposals: analysisBundle.profileProposals
          .map(
            (proposal) => _promotedProposal(
              proposal,
              proposalStatus: proposalStatus,
              promotedBy: promotedBy,
            ),
          )
          .toList(growable: false),
      semanticReviews: includeSemanticReviews
          ? analysisBundle.semanticReviews
                .map(
                  (review) => _promotedReview(
                    review,
                    claimStatus: claimStatus,
                    promotedBy: promotedBy,
                  ),
                )
                .toList(growable: false)
          : const <NarrativeSemanticReview>[],
      knowledgeCards: analysisBundle.knowledgeCards,
      designElements: analysisBundle.designElements,
      researchNotes: analysisBundle.researchNotes,
      referenceWorks: analysisBundle.referenceWorks,
      metadata: <String, Object?>{
        ...analysisBundle.metadata,
        BookDeconstructionNarrativeBridgeConstants.metadataAnalysisStatus:
            claimStatus,
        BookDeconstructionNarrativeBridgeConstants.metadataPromotedBy:
            promotedBy,
      },
    );
  }

  NarrativeStateClaim _promotedClaim(
    NarrativeStateClaim claim, {
    required String claimStatus,
    required String promotedBy,
  }) {
    final metadata = ValueReaders.deepCopyMap(claim.metadata);
    final targetNamespace = ValueReaders.stringValue(
      metadata[BookDeconstructionNarrativeBridgeConstants
          .metadataPromotionTargetNamespace],
      _fallbackTargetNamespace(claim.claimNamespace),
    );
    return claim.copyWith(
      claimId: '${claim.claimId}_promoted',
      claimNamespace: targetNamespace,
      metadata: <String, Object?>{
        ...metadata,
        BookDeconstructionNarrativeBridgeConstants.metadataAnalysisStatus:
            claimStatus,
        BookDeconstructionNarrativeBridgeConstants.metadataPromotedBy:
            promotedBy,
        BookDeconstructionNarrativeBridgeConstants
                .metadataPromotedFromArtifactId:
            claim.claimId,
        BookDeconstructionNarrativeBridgeConstants
                .metadataPromotedFromNamespace:
            claim.claimNamespace,
      },
    );
  }

  NarrativeProfileProposal _promotedProposal(
    NarrativeProfileProposal proposal, {
    required NarrativeProfileLifecycleStatus proposalStatus,
    required String promotedBy,
  }) {
    final metadata = ValueReaders.deepCopyMap(proposal.metadata);
    return proposal.copyWith(
      proposalId: '${proposal.proposalId}_promoted',
      proposalStatus: proposalStatus,
      metadata: <String, Object?>{
        ...metadata,
        BookDeconstructionNarrativeBridgeConstants.metadataAnalysisStatus:
            proposalStatus.id,
        BookDeconstructionNarrativeBridgeConstants.metadataPromotedBy:
            promotedBy,
        BookDeconstructionNarrativeBridgeConstants
                .metadataPromotedFromArtifactId:
            proposal.proposalId,
      },
    );
  }

  NarrativeSemanticReview _promotedReview(
    NarrativeSemanticReview review, {
    required String claimStatus,
    required String promotedBy,
  }) {
    final metadata = ValueReaders.deepCopyMap(review.metadata);
    return review.copyWith(
      reviewId: '${review.reviewId}_promoted',
      metadata: <String, Object?>{
        ...metadata,
        BookDeconstructionNarrativeBridgeConstants.metadataAnalysisStatus:
            claimStatus,
        BookDeconstructionNarrativeBridgeConstants.metadataPromotedBy:
            promotedBy,
        BookDeconstructionNarrativeBridgeConstants
                .metadataPromotedFromArtifactId:
            review.reviewId,
      },
    );
  }

  String _fallbackTargetNamespace(String namespace) {
    if (namespace.startsWith(
      BookDeconstructionNarrativeBridgeConstants.analysisNamespacePrefix,
    )) {
      return namespace.substring(
        BookDeconstructionNarrativeBridgeConstants
            .analysisNamespacePrefix
            .length,
      );
    }
    return namespace;
  }
}
