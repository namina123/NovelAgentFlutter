import '../continuity/narrative_state/narrative_constraint_binding_proposal.dart';
import '../project/project_descriptor.dart';

abstract class ConstraintBindingRepository {
  Future<void> appendBinding(
    ProjectDescriptor project,
    NarrativeConstraintBindingProposal binding,
  );

  Future<NarrativeConstraintBindingProposal?> readBinding(
    ProjectDescriptor project, {
    required String bindingId,
  });

  Future<List<NarrativeConstraintBindingProposal>> listBindings(
    ProjectDescriptor project, {
    String? constraintType,
  });
}
