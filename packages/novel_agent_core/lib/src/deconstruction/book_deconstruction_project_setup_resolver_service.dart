import 'book_deconstruction_continuation_direction.dart';
import 'book_deconstruction_project_setup.dart';

class BookDeconstructionProjectSetupResolverService {
  const BookDeconstructionProjectSetupResolverService();

  static const String continuationRouteId = 'continuation';
  static const String fanficRouteId = 'fanfic';

  BookDeconstructionProjectSetup resolve({
    String followupRouteId = continuationRouteId,
  }) {
    switch (followupRouteId.trim()) {
      case fanficRouteId:
        return const BookDeconstructionProjectSetup(
          followupRouteId: fanficRouteId,
          preferredFollowupOptionId: 'fanfic_seed_autopilot_novel',
          preferredContinuationDirection:
              BookDeconstructionContinuationDirection.longTaskPreferred,
        );
      case continuationRouteId:
      default:
        return const BookDeconstructionProjectSetup(
          followupRouteId: continuationRouteId,
          preferredFollowupOptionId: 'continuation_novel',
          preferredContinuationDirection:
              BookDeconstructionContinuationDirection.generalNovelPreferred,
        );
    }
  }

  String normalizeRouteId(String followupRouteId) {
    final cleanId = followupRouteId.trim();
    if (cleanId == fanficRouteId) {
      return fanficRouteId;
    }
    return continuationRouteId;
  }
}
