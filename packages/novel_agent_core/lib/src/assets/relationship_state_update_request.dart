class RelationshipStateUpdateRequest {
  const RelationshipStateUpdateRequest({
    this.id = '',
    required this.displayName,
    required this.leftEntityId,
    required this.rightEntityId,
    this.summary = '',
    this.relationshipType = '',
    this.status = '',
    this.relatedForeshadowIds = const <String>[],
    this.relatedTimelineIds = const <String>[],
    this.tags = const <String>[],
    this.notes = '',
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String displayName;
  final String leftEntityId;
  final String rightEntityId;
  final String summary;
  final String relationshipType;
  final String status;
  final List<String> relatedForeshadowIds;
  final List<String> relatedTimelineIds;
  final List<String> tags;
  final String notes;
  final Map<String, Object?> metadata;
}
