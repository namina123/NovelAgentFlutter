import 'package:novel_agent_core/novel_agent_core.dart';

import '../models/review_center_analysis_state.dart';

class ReviewCenterAnalysisStateService {
  const ReviewCenterAnalysisStateService();

  ReviewCenterAnalysisState createInitialState(
    ChapterAnalysisResult result, {
    required String analysisPath,
  }) {
    // 中文注释: 分析态默认选中所有建议，并预收集所有局部片段，让 GUI 一进来就能直接切动作看计划。
    final segmentIds = <String>[];
    for (final suggestion in result.suggestions) {
      for (final segment in suggestion.targetSegments) {
        if (!segmentIds.contains(segment.id)) {
          segmentIds.add(segment.id);
        }
      }
    }
    return ReviewCenterAnalysisState(
      analysisResult: result,
      analysisPath: analysisPath.trim(),
      rewriteMode: ChapterRewriteActionKind.suggestionsOnly,
      selectedSuggestionIds: result.suggestions
          .map((item) => item.id)
          .toList(growable: false),
      selectedSegmentIds: segmentIds,
    );
  }

  ReviewCenterAnalysisState updateRewriteMode(
    ReviewCenterAnalysisState state,
    String rewriteMode,
  ) {
    return state.copyWith(
      rewriteMode: rewriteMode.trim(),
      clearCurrentPlan: true,
    );
  }

  ReviewCenterAnalysisState toggleSuggestion(
    ReviewCenterAnalysisState state,
    String suggestionId,
    bool selected,
  ) {
    final next = List<String>.from(state.selectedSuggestionIds);
    if (selected) {
      if (!next.contains(suggestionId)) {
        next.add(suggestionId);
      }
    } else {
      next.remove(suggestionId);
    }
    return state.copyWith(selectedSuggestionIds: next, clearCurrentPlan: true);
  }

  ReviewCenterAnalysisState toggleSegment(
    ReviewCenterAnalysisState state,
    String segmentId,
    bool selected,
  ) {
    final next = List<String>.from(state.selectedSegmentIds);
    if (selected) {
      if (!next.contains(segmentId)) {
        next.add(segmentId);
      }
    } else {
      next.remove(segmentId);
    }
    return state.copyWith(selectedSegmentIds: next, clearCurrentPlan: true);
  }

  List<ChapterAnalysisSuggestion> selectedSuggestions(
    ReviewCenterAnalysisState state,
  ) {
    final result = state.analysisResult;
    if (result == null) {
      return const <ChapterAnalysisSuggestion>[];
    }
    if (state.selectedSuggestionIds.isEmpty) {
      return result.suggestions;
    }
    return result.suggestions
        .where((item) => state.selectedSuggestionIds.contains(item.id))
        .toList(growable: false);
  }

  List<ChapterAnalysisTargetSegment> selectedSegments(
    ReviewCenterAnalysisState state,
  ) {
    final suggestions = selectedSuggestions(state);
    final result = <ChapterAnalysisTargetSegment>[];
    for (final suggestion in suggestions) {
      for (final segment in suggestion.targetSegments) {
        if (state.selectedSegmentIds.contains(segment.id) &&
            !result.any((item) => item.id == segment.id)) {
          result.add(segment);
        }
      }
    }
    return result;
  }
}
