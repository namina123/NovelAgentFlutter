class RelationshipRecord {
  const RelationshipRecord({
    required this.id,
    required this.displayName,
    required this.leftEntityId,
    required this.rightEntityId,
    this.summary = '',
    this.relationshipType = '',
    this.status = 'active',
    this.relatedEntityIds = const <String>[],
    this.relatedForeshadowIds = const <String>[],
    this.relatedTimelineIds = const <String>[],
    this.tags = const <String>[],
    this.notes = '',
    this.sourcePath = '',
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String displayName;
  final String leftEntityId;
  final String rightEntityId;
  final String summary;
  final String relationshipType;
  final String status;
  final List<String> relatedEntityIds;
  final List<String> relatedForeshadowIds;
  final List<String> relatedTimelineIds;
  final List<String> tags;
  final String notes;
  final String sourcePath;
  final Map<String, Object?> metadata;
}
