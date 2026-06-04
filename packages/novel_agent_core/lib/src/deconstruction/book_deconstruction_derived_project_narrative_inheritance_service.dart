import '../common/value_readers.dart';
import 'book_deconstruction_derived_narrative_inheritance_entry.dart';
import 'book_deconstruction_narrative_artifact_bundle.dart';
import 'book_deconstruction_narrative_bridge_constants.dart';

class BookDeconstructionDerivedProjectNarrativeInheritanceService {
  const BookDeconstructionDerivedProjectNarrativeInheritanceService();

  List<BookDeconstructionDerivedNarrativeInheritanceEntry> buildEntries({
    required BookDeconstructionNarrativeArtifactBundle narrativeArtifacts,
  }) {
    final entries = <BookDeconstructionDerivedNarrativeInheritanceEntry>[
      ...narrativeArtifacts.claims
          .map(_claimEntryOf)
          .whereType<BookDeconstructionDerivedNarrativeInheritanceEntry>(),
      ...narrativeArtifacts.profileProposals
          .map(_proposalEntryOf)
          .whereType<BookDeconstructionDerivedNarrativeInheritanceEntry>(),
      ...narrativeArtifacts.semanticReviews
          .map(_reviewEntryOf)
          .whereType<BookDeconstructionDerivedNarrativeInheritanceEntry>(),
    ];
    return List<
      BookDeconstructionDerivedNarrativeInheritanceEntry
    >.unmodifiable(entries);
  }

  BookDeconstructionDerivedNarrativeInheritanceEntry? _claimEntryOf(
    dynamic claim,
  ) {
    final metadata = ValueReaders.deepCopyMap(claim.metadata);
    final status = _normalizedStatus(
      metadata[BookDeconstructionNarrativeBridgeConstants
          .metadataAnalysisStatus],
      fallback:
          claim.claimNamespace.startsWith(
            BookDeconstructionNarrativeBridgeConstants.analysisNamespacePrefix,
          )
          ? BookDeconstructionNarrativeBridgeConstants.proposedStatus
          : BookDeconstructionNarrativeBridgeConstants.acceptedStatus,
    );
    if (!_isInheritable(status)) {
      return null;
    }
    return BookDeconstructionDerivedNarrativeInheritanceEntry(
      artifactType:
          BookDeconstructionNarrativeBridgeConstants.artifactTypeClaim,
      artifactId: claim.claimId,
      status: status,
      sourceType: claim.source.sourceType,
      namespace: claim.claimNamespace,
      promotionTarget: ValueReaders.stringValue(
        metadata[BookDeconstructionNarrativeBridgeConstants
            .metadataPromotionTargetNamespace],
      ),
      metadata: metadata,
    );
  }

  BookDeconstructionDerivedNarrativeInheritanceEntry? _proposalEntryOf(
    dynamic proposal,
  ) {
    final status = proposal.proposalStatus.id;
    if (!_isInheritable(status)) {
      return null;
    }
    return BookDeconstructionDerivedNarrativeInheritanceEntry(
      artifactType: BookDeconstructionNarrativeBridgeConstants
          .artifactTypeProfileProposal,
      artifactId: proposal.proposalId,
      status: status,
      sourceType: proposal.source.sourceType,
      namespace: ValueReaders.stringValue(
        proposal.metadata[BookDeconstructionNarrativeBridgeConstants
            .metadataAnalysisNamespace],
      ),
      promotionTarget: ValueReaders.stringValue(
        proposal.metadata[BookDeconstructionNarrativeBridgeConstants
            .metadataPromotionTargetProfileNamespace],
      ),
      metadata: ValueReaders.deepCopyMap(proposal.metadata),
    );
  }

  BookDeconstructionDerivedNarrativeInheritanceEntry? _reviewEntryOf(
    dynamic review,
  ) {
    final metadata = ValueReaders.deepCopyMap(review.metadata);
    final status = _normalizedStatus(
      metadata[BookDeconstructionNarrativeBridgeConstants
          .metadataAnalysisStatus],
      fallback: review.reviewId.contains('_promoted')
          ? BookDeconstructionNarrativeBridgeConstants.acceptedStatus
          : BookDeconstructionNarrativeBridgeConstants.proposedStatus,
    );
    if (!_isInheritable(status)) {
      return null;
    }
    return BookDeconstructionDerivedNarrativeInheritanceEntry(
      artifactType:
          BookDeconstructionNarrativeBridgeConstants.artifactTypeSemanticReview,
      artifactId: review.reviewId,
      status: status,
      sourceType: review.source.sourceType,
      namespace: ValueReaders.stringValue(
        metadata[BookDeconstructionNarrativeBridgeConstants
            .metadataAnalysisNamespace],
      ),
      promotionTarget: ValueReaders.stringValue(
        metadata[BookDeconstructionNarrativeBridgeConstants
            .metadataPromotionTargetNamespace],
      ),
      metadata: metadata,
    );
  }

  bool _isInheritable(String status) {
    return status ==
            BookDeconstructionNarrativeBridgeConstants.proposedStatus ||
        status == BookDeconstructionNarrativeBridgeConstants.acceptedStatus;
  }

  String _normalizedStatus(Object? raw, {required String fallback}) {
    final clean = ValueReaders.stringValue(raw).trim().toLowerCase();
    if (clean.isEmpty) {
      return fallback;
    }
    return clean;
  }
}
