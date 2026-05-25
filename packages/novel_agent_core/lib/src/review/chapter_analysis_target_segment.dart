class ChapterAnalysisTargetSegment {
  const ChapterAnalysisTargetSegment({
    required this.id,
    required this.sourcePath,
    this.label = '',
    this.startLine = 0,
    this.endLine = 0,
    this.summary = '',
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String sourcePath;
  final String label;
  final int startLine;
  final int endLine;
  final String summary;
  final Map<String, Object?> metadata;
}
