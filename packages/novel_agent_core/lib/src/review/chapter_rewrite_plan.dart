import 'chapter_analysis_target_segment.dart';

class ChapterRewritePlan {
  const ChapterRewritePlan({
    required this.id,
    required this.analysisResultId,
    required this.actionKind,
    required this.title,
    this.chapterPath = '',
    this.summary = '',
    this.instructions = '',
    this.sourcePaths = const <String>[],
    this.outputPaths = const <String>[],
    this.issueIds = const <String>[],
    this.suggestionIds = const <String>[],
    this.targetSegments = const <ChapterAnalysisTargetSegment>[],
    this.preserveNotes = const <String>[],
    this.createdAt = '',
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String analysisResultId;
  final String actionKind;
  final String title;
  final String chapterPath;
  final String summary;
  final String instructions;
  final List<String> sourcePaths;
  final List<String> outputPaths;
  final List<String> issueIds;
  final List<String> suggestionIds;
  final List<ChapterAnalysisTargetSegment> targetSegments;
  final List<String> preserveNotes;
  final String createdAt;
  final Map<String, Object?> metadata;
}
