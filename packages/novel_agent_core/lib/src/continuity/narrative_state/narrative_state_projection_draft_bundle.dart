import 'narrative_constraint_binding_proposal.dart';
import 'narrative_profile_proposal.dart';
import 'narrative_semantic_review.dart';
import 'narrative_state_claim.dart';

class NarrativeStateProjectionDraftBundle {
  const NarrativeStateProjectionDraftBundle({
    required this.projectionId,
    required this.relativePath,
    this.projectionOnly = true,
    this.profileProposalDrafts = const <NarrativeProfileProposal>[],
    this.claimDrafts = const <NarrativeStateClaim>[],
    this.constraintBindingDrafts = const <NarrativeConstraintBindingProposal>[],
    this.semanticReviewDrafts = const <NarrativeSemanticReview>[],
    this.warnings = const <String>[],
  });

  final String projectionId;
  final String relativePath;
  final bool projectionOnly;
  final List<NarrativeProfileProposal> profileProposalDrafts;
  final List<NarrativeStateClaim> claimDrafts;
  final List<NarrativeConstraintBindingProposal> constraintBindingDrafts;
  final List<NarrativeSemanticReview> semanticReviewDrafts;
  final List<String> warnings;

  bool get isEmpty =>
      profileProposalDrafts.isEmpty &&
      claimDrafts.isEmpty &&
      constraintBindingDrafts.isEmpty &&
      semanticReviewDrafts.isEmpty;
}
