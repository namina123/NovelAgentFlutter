class CharacterStageStateRecord {
  const CharacterStageStateRecord({
    required this.id,
    required this.characterId,
    required this.displayName,
    this.stageId = '',
    this.stageLabel = '',
    this.status = '',
    this.summary = '',
    this.sourcePaths = const <String>[],
    this.relatedTimelineIds = const <String>[],
    this.updatedAt = '',
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String characterId;
  final String displayName;
  final String stageId;
  final String stageLabel;
  final String status;
  final String summary;
  final List<String> sourcePaths;
  final List<String> relatedTimelineIds;
  final String updatedAt;
  final Map<String, Object?> metadata;
}
