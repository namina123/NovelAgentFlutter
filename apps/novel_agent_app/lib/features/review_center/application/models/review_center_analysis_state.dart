import 'package:novel_agent_core/novel_agent_core.dart';

class ReviewCenterAnalysisState {
  const ReviewCenterAnalysisState({
    this.analysisResult,
    this.analysisPath = '',
    this.rewriteMode = ChapterRewriteActionKind.suggestionsOnly,
    this.selectedSuggestionIds = const <String>[],
    this.selectedSegmentIds = const <String>[],
    this.playbackBody = '',
    this.playbackSourcePath = '',
    this.currentPlan,
  });

  final ChapterAnalysisResult? analysisResult;
  final String analysisPath;
  final String rewriteMode;
  final List<String> selectedSuggestionIds;
  final List<String> selectedSegmentIds;
  final String playbackBody;
  final String playbackSourcePath;
  final ChapterRewritePlan? currentPlan;

  factory ReviewCenterAnalysisState.initial() {
    return const ReviewCenterAnalysisState();
  }

  ReviewCenterAnalysisState copyWith({
    ChapterAnalysisResult? analysisResult,
    String? analysisPath,
    String? rewriteMode,
    List<String>? selectedSuggestionIds,
    List<String>? selectedSegmentIds,
    String? playbackBody,
    String? playbackSourcePath,
    ChapterRewritePlan? currentPlan,
    bool clearCurrentPlan = false,
  }) {
    return ReviewCenterAnalysisState(
      analysisResult: analysisResult ?? this.analysisResult,
      analysisPath: analysisPath ?? this.analysisPath,
      rewriteMode: rewriteMode ?? this.rewriteMode,
      selectedSuggestionIds: selectedSuggestionIds ?? this.selectedSuggestionIds,
      selectedSegmentIds: selectedSegmentIds ?? this.selectedSegmentIds,
      playbackBody: playbackBody ?? this.playbackBody,
      playbackSourcePath: playbackSourcePath ?? this.playbackSourcePath,
      currentPlan: clearCurrentPlan ? null : (currentPlan ?? this.currentPlan),
    );
  }
}
