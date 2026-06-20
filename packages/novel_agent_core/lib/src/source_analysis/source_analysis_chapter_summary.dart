class SourceAnalysisChapterSummary {
  const SourceAnalysisChapterSummary({
    required this.sequence,
    required this.title,
    required this.summary,
    this.sectionId = '',
    this.structureKind = '',
    this.keywords = const <String>[],
    this.metadata = const <String, Object?>{},
  });

  final int sequence;
  final String title;
  final String summary;
  final String sectionId;
  final String structureKind;
  final List<String> keywords;
  final Map<String, Object?> metadata;
}
