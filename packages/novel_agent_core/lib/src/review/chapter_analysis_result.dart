import 'chapter_analysis_issue.dart';
import 'chapter_analysis_suggestion.dart';

class ChapterAnalysisResult {
  const ChapterAnalysisResult({
    required this.id,
    required this.analysisType,
    required this.title,
    this.chapterPath = '',
    this.summary = '',
    this.overallAssessment = '',
    this.issues = const <ChapterAnalysisIssue>[],
    this.suggestions = const <ChapterAnalysisSuggestion>[],
    this.sourcePaths = const <String>[],
    this.relatedPaths = const <String>[],
    this.createdAt = '',
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String analysisType;
  final String title;
  final String chapterPath;
  final String summary;
  final String overallAssessment;
  final List<ChapterAnalysisIssue> issues;
  final List<ChapterAnalysisSuggestion> suggestions;
  final List<String> sourcePaths;
  final List<String> relatedPaths;
  final String createdAt;
  final Map<String, Object?> metadata;
}
