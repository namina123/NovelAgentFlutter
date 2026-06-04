import 'package:novel_agent_core/novel_agent_core.dart';

import 'open_narrative_state_index_document_service.dart';
import 'open_narrative_state_path_service.dart';
import 'project_json_document_service.dart';

class LocalSemanticReviewRepository implements SemanticReviewRepository {
  LocalSemanticReviewRepository({
    required ProjectWorkspacePort workspacePort,
    ProjectJsonDocumentService? jsonDocumentService,
    OpenNarrativeStatePathService? pathService,
    NarrativeSemanticReviewCodecService? codecService,
  }) : _jsonDocumentService =
           jsonDocumentService ??
           ProjectJsonDocumentService(workspacePort: workspacePort),
       _pathService = pathService ?? OpenNarrativeStatePathService(),
       _codecService =
           codecService ?? const NarrativeSemanticReviewCodecService(),
       _indexDocumentService = OpenNarrativeStateIndexDocumentService(
         jsonDocumentService:
             jsonDocumentService ??
             ProjectJsonDocumentService(workspacePort: workspacePort),
       );

  final ProjectJsonDocumentService _jsonDocumentService;
  final OpenNarrativeStatePathService _pathService;
  final NarrativeSemanticReviewCodecService _codecService;
  final OpenNarrativeStateIndexDocumentService _indexDocumentService;

  @override
  Future<void> appendReview(
    ProjectDescriptor project,
    NarrativeSemanticReview review,
  ) async {
    await _jsonDocumentService.writeJsonMap(
      project.rootPath,
      _pathService.reviewPath(review.reviewId),
      _codecService.toJson(review),
    );
    final existingIds = await _readReviewIds(project);
    await _writeReviewIds(project, <String>[
      ...existingIds.where((id) => id != review.reviewId),
      review.reviewId,
    ]);
  }

  @override
  Future<List<NarrativeSemanticReview>> listReviews(
    ProjectDescriptor project,
  ) async {
    final result = <NarrativeSemanticReview>[];
    for (final reviewId in await _readReviewIds(project)) {
      final review = await readReview(project, reviewId: reviewId);
      if (review != null) {
        result.add(review);
      }
    }
    return result;
  }

  @override
  Future<NarrativeSemanticReview?> readReview(
    ProjectDescriptor project, {
    required String reviewId,
  }) async {
    final document = await _jsonDocumentService.readJsonMap(
      project.rootPath,
      _pathService.reviewPath(reviewId),
    );
    if (document.isEmpty) {
      return null;
    }
    return _codecService.fromJson(document);
  }

  Future<List<String>> _readReviewIds(ProjectDescriptor project) {
    return _indexDocumentService.readIds(
      project.rootPath,
      _pathService.reviewsIndexPath(),
      fieldName: 'review_ids',
    );
  }

  Future<void> _writeReviewIds(ProjectDescriptor project, List<String> ids) {
    return _indexDocumentService.writeIds(
      project.rootPath,
      _pathService.reviewsIndexPath(),
      fieldName: 'review_ids',
      ids: ids,
    );
  }
}
