import '../continuity/narrative_state/narrative_semantic_review.dart';
import '../project/project_descriptor.dart';

abstract class SemanticReviewRepository {
  Future<void> appendReview(
    ProjectDescriptor project,
    NarrativeSemanticReview review,
  );

  Future<NarrativeSemanticReview?> readReview(
    ProjectDescriptor project, {
    required String reviewId,
  });

  Future<List<NarrativeSemanticReview>> listReviews(ProjectDescriptor project);
}
