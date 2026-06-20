import 'source_analysis_chapter_summary.dart';

class SourceAnalysisOutline {
  const SourceAnalysisOutline({
    this.chapterSummaries = const <SourceAnalysisChapterSummary>[],
    this.storyOutlineSummary = '',
    this.premiseSummary = '',
  });

  final List<SourceAnalysisChapterSummary> chapterSummaries;
  final String storyOutlineSummary;
  final String premiseSummary;
}
