import 'chapter_analysis_target_segment.dart';

class ChapterAnalysisSuggestion {
  const ChapterAnalysisSuggestion({
    required this.id,
    required this.title,
    required this.actionKind,
    this.summary = '',
    this.priorityRank = 0,
    this.sourcePaths = const <String>[],
    this.outputPaths = const <String>[],
    this.issueIds = const <String>[],
    this.promptHints = const <String>[],
    this.targetSegments = const <ChapterAnalysisTargetSegment>[],
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String title;
  final String actionKind;
  final String summary;
  final int priorityRank;
  final List<String> sourcePaths;
  final List<String> outputPaths;
  final List<String> issueIds;
  final List<String> promptHints;
  final List<ChapterAnalysisTargetSegment> targetSegments;
  final Map<String, Object?> metadata;
}
