class ForeshadowRecord {
  const ForeshadowRecord({
    required this.id,
    required this.title,
    required this.status,
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
    this.sourcePath = '',
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
  final String sourcePath;
  final Map<String, Object?> metadata;
}
