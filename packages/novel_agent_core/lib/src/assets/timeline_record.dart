class TimelineRecord {
  const TimelineRecord({
    required this.id,
    required this.displayName,
    this.summary = '',
    this.eventType = '',
    this.status = 'planned',
    this.phaseLabel = '',
    this.sequence = 0,
    this.relatedEntityIds = const <String>[],
    this.relatedForeshadowIds = const <String>[],
    this.relatedRelationshipIds = const <String>[],
    this.relatedPaths = const <String>[],
    this.notes = '',
    this.sourcePath = '',
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String displayName;
  final String summary;
  final String eventType;
  final String status;
  final String phaseLabel;
  final int sequence;
  final List<String> relatedEntityIds;
  final List<String> relatedForeshadowIds;
  final List<String> relatedRelationshipIds;
  final List<String> relatedPaths;
  final String notes;
  final String sourcePath;
  final Map<String, Object?> metadata;
}
