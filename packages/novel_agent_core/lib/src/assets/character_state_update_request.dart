class CharacterStateUpdateRequest {
  const CharacterStateUpdateRequest({
    required this.name,
    this.characterId = '',
    this.status = '',
    this.role = '',
    this.content = '',
    this.stageId = '',
    this.stageLabel = '',
    this.sourcePaths = const <String>[],
    this.relatedTimelineIds = const <String>[],
    this.metadata = const <String, Object?>{},
  });

  final String name;
  final String characterId;
  final String status;
  final String role;
  final String content;
  final String stageId;
  final String stageLabel;
  final List<String> sourcePaths;
  final List<String> relatedTimelineIds;
  final Map<String, Object?> metadata;
}
