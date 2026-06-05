import '../common/json_types.dart';
import '../continuity/narrative_state/narrative_profile_proposal.dart';
import '../continuity/narrative_state/narrative_semantic_review.dart';
import '../continuity/narrative_state/narrative_state_claim.dart';
import '../information/design_element_card.dart';
import '../information/project_knowledge_card.dart';
import '../information/reference_work_record.dart';
import '../information/research_note.dart';

class BookDeconstructionNarrativeArtifactBundle {
  const BookDeconstructionNarrativeArtifactBundle({
    this.claims = const <NarrativeStateClaim>[],
    this.profileProposals = const <NarrativeProfileProposal>[],
    this.semanticReviews = const <NarrativeSemanticReview>[],
    this.knowledgeCards = const <ProjectKnowledgeCard>[],
    this.designElements = const <DesignElementCard>[],
    this.researchNotes = const <ResearchNote>[],
    this.referenceWorks = const <ReferenceWorkRecord>[],
    this.metadata = const <String, Object?>{},
  });

  final List<NarrativeStateClaim> claims;
  final List<NarrativeProfileProposal> profileProposals;
  final List<NarrativeSemanticReview> semanticReviews;
  final List<ProjectKnowledgeCard> knowledgeCards;
  final List<DesignElementCard> designElements;
  final List<ResearchNote> researchNotes;
  final List<ReferenceWorkRecord> referenceWorks;
  final JsonMap metadata;

  bool get isEmpty {
    return claims.isEmpty &&
        profileProposals.isEmpty &&
        semanticReviews.isEmpty &&
        knowledgeCards.isEmpty &&
        designElements.isEmpty &&
        researchNotes.isEmpty &&
        referenceWorks.isEmpty &&
        metadata.isEmpty;
  }

  BookDeconstructionNarrativeArtifactBundle copyWith({
    List<NarrativeStateClaim>? claims,
    List<NarrativeProfileProposal>? profileProposals,
    List<NarrativeSemanticReview>? semanticReviews,
    List<ProjectKnowledgeCard>? knowledgeCards,
    List<DesignElementCard>? designElements,
    List<ResearchNote>? researchNotes,
    List<ReferenceWorkRecord>? referenceWorks,
    JsonMap? metadata,
  }) {
    return BookDeconstructionNarrativeArtifactBundle(
      claims: claims ?? this.claims,
      profileProposals: profileProposals ?? this.profileProposals,
      semanticReviews: semanticReviews ?? this.semanticReviews,
      knowledgeCards: knowledgeCards ?? this.knowledgeCards,
      designElements: designElements ?? this.designElements,
      researchNotes: researchNotes ?? this.researchNotes,
      referenceWorks: referenceWorks ?? this.referenceWorks,
      metadata: metadata ?? this.metadata,
    );
  }
}
