import '../continuity/narrative_state/narrative_state_claim.dart';
import '../project/project_descriptor.dart';

abstract class NarrativeClaimRepository {
  Future<void> appendClaim(
    ProjectDescriptor project,
    NarrativeStateClaim claim,
  );

  Future<NarrativeStateClaim?> readClaim(
    ProjectDescriptor project, {
    required String claimId,
  });

  Future<List<NarrativeStateClaim>> listClaims(
    ProjectDescriptor project, {
    String? claimNamespace,
  });
}
