class ForeshadowStateUpdateRequest {
  const ForeshadowStateUpdateRequest({
    this.id = '',
    required this.title,
    this.status = '',
    this.summary = '',
    this.plantedChapterPath = '',
    this.targetPayoffPath = '',
    this.relatedEntityIds = const <String>[],
    this.relatedTimelineIds = const <String>[],
    this.relatedRelationshipIds = const <String>[],
    this.relatedPaths = const <String>[],
    this.triggerConditions = const <String>[],
    this.payoffExpectations = const <String>[],
    this.tags = const <String>[],
    this.notes = '',
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String title;
  final String status;
  final String summary;
  final String plantedChapterPath;
  final String targetPayoffPath;
  final List<String> relatedEntityIds;
  final List<String> relatedTimelineIds;
  final List<String> relatedRelationshipIds;
  final List<String> relatedPaths;
  final List<String> triggerConditions;
  final List<String> payoffExpectations;
  final List<String> tags;
  final String notes;
  final Map<String, Object?> metadata;
}
