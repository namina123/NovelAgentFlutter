import 'narrative_constraint_binding_proposal.dart';
import 'narrative_profile.dart';
import 'narrative_semantic_review.dart';
import 'narrative_state_claim.dart';
import 'narrative_state_ledger.dart';

class NarrativeStateProjectionSource {
  const NarrativeStateProjectionSource({
    this.profiles = const <NarrativeProfile>[],
    this.claims = const <NarrativeStateClaim>[],
    this.ledgers = const <NarrativeStateLedger>[],
    this.reviews = const <NarrativeSemanticReview>[],
    this.bindings = const <NarrativeConstraintBindingProposal>[],
  });

  final List<NarrativeProfile> profiles;
  final List<NarrativeStateClaim> claims;
  final List<NarrativeStateLedger> ledgers;
  final List<NarrativeSemanticReview> reviews;
  final List<NarrativeConstraintBindingProposal> bindings;
}
