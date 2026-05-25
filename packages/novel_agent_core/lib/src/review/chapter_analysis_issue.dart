class ChapterAnalysisIssue {
  const ChapterAnalysisIssue({
    required this.id,
    required this.title,
    this.category = '',
    this.severity = 'normal',
    this.summary = '',
    this.detail = '',
    this.evidence = '',
    this.suggestion = '',
    this.sourcePath = '',
    this.startLine = 0,
    this.endLine = 0,
    this.relatedEntityIds = const <String>[],
    this.relatedForeshadowIds = const <String>[],
    this.relatedTimelineIds = const <String>[],
    this.relatedRelationshipIds = const <String>[],
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String title;
  final String category;
  final String severity;
  final String summary;
  final String detail;
  final String evidence;
  final String suggestion;
  final String sourcePath;
  final int startLine;
  final int endLine;
  final List<String> relatedEntityIds;
  final List<String> relatedForeshadowIds;
  final List<String> relatedTimelineIds;
  final List<String> relatedRelationshipIds;
  final Map<String, Object?> metadata;
}
