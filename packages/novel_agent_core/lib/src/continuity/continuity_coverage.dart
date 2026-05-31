class ContinuityCoverage {
  const ContinuityCoverage({
    this.sourceLabel = '',
    this.sourcePaths = const <String>[],
    this.chapterStart = 0,
    this.chapterEnd = 0,
    this.isPartial = false,
    this.inferredSections = const <String>[],
    this.notes = '',
    this.metadata = const <String, Object?>{},
  });

  final String sourceLabel;
  final List<String> sourcePaths;
  final int chapterStart;
  final int chapterEnd;
  final bool isPartial;
  final List<String> inferredSections;
  final String notes;
  final Map<String, Object?> metadata;
}
