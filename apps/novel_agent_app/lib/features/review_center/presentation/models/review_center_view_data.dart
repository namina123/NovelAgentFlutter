class ReviewCenterViewData {
  const ReviewCenterViewData({
    required this.title,
    required this.description,
    required this.status,
    required this.entries,
    required this.selectedEntryId,
    required this.detailBody,
    required this.reviewTypes,
    required this.initialReviewTypeFilter,
    required this.initialScopeFilter,
    required this.initialSourceFilter,
    required this.analysis,
  });

  final String title;
  final String description;
  final String status;
  final List<ReviewCenterEntryViewData> entries;
  final String selectedEntryId;
  final String detailBody;
  final List<ReviewTypeOptionViewData> reviewTypes;
  final String initialReviewTypeFilter;
  final String initialScopeFilter;
  final String initialSourceFilter;
  final ReviewCenterAnalysisViewData analysis;

  factory ReviewCenterViewData.initial() {
    return ReviewCenterViewData(
      title: '审稿报告',
      description: '',
      status: '',
      entries: <ReviewCenterEntryViewData>[],
      selectedEntryId: '',
      detailBody: '',
      reviewTypes: <ReviewTypeOptionViewData>[],
      initialReviewTypeFilter: '',
      initialScopeFilter: '',
      initialSourceFilter: '',
      analysis: ReviewCenterAnalysisViewData.empty(),
    );
  }
}

class ReviewCenterEntryViewData {
  const ReviewCenterEntryViewData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.relativePath,
    this.isSelected = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final String badge;
  final String relativePath;
  final bool isSelected;
}

class ReviewTypeOptionViewData {
  const ReviewTypeOptionViewData({required this.id, required this.label});

  final String id;
  final String label;
}

class ReviewCenterAnalysisViewData {
  const ReviewCenterAnalysisViewData({
    required this.title,
    required this.summary,
    required this.overallAssessment,
    required this.analysisTypeLabel,
    required this.issueCountLabel,
    required this.rewriteActions,
    required this.issues,
    required this.suggestions,
    required this.segments,
    required this.plan,
    required this.playback,
  });

  final String title;
  final String summary;
  final String overallAssessment;
  final String analysisTypeLabel;
  final String issueCountLabel;
  final List<ReviewCenterRewriteActionViewData> rewriteActions;
  final List<ReviewCenterIssueViewData> issues;
  final List<ReviewCenterSuggestionViewData> suggestions;
  final List<ReviewCenterSegmentViewData> segments;
  final ReviewCenterPlanViewData plan;
  final ReviewCenterPlaybackViewData playback;

  factory ReviewCenterAnalysisViewData.empty() {
    return ReviewCenterAnalysisViewData(
      title: '分析结果',
      summary: '',
      overallAssessment: '',
      analysisTypeLabel: '',
      issueCountLabel: '',
      rewriteActions: const <ReviewCenterRewriteActionViewData>[
        ReviewCenterRewriteActionViewData(
          id: 'rewrite_full',
          label: '整章重写',
          description: '',
          isSelected: false,
        ),
        ReviewCenterRewriteActionViewData(
          id: 'rewrite_partial',
          label: '局部重写',
          description: '',
          isSelected: false,
        ),
        ReviewCenterRewriteActionViewData(
          id: 'suggestions_only',
          label: '只生成建议',
          description: '',
          isSelected: true,
        ),
      ],
      issues: const <ReviewCenterIssueViewData>[],
      suggestions: const <ReviewCenterSuggestionViewData>[],
      segments: const <ReviewCenterSegmentViewData>[],
      plan: ReviewCenterPlanViewData.empty(),
      playback: ReviewCenterPlaybackViewData.empty(),
    );
  }
}

class ReviewCenterRewriteActionViewData {
  const ReviewCenterRewriteActionViewData({
    required this.id,
    required this.label,
    required this.description,
    required this.isSelected,
  });

  final String id;
  final String label;
  final String description;
  final bool isSelected;
}

class ReviewCenterIssueViewData {
  const ReviewCenterIssueViewData({
    required this.id,
    required this.title,
    required this.severityLabel,
    required this.summary,
    required this.suggestion,
    required this.rangeLabel,
  });

  final String id;
  final String title;
  final String severityLabel;
  final String summary;
  final String suggestion;
  final String rangeLabel;
}

class ReviewCenterSuggestionViewData {
  const ReviewCenterSuggestionViewData({
    required this.id,
    required this.title,
    required this.summary,
    required this.actionKindLabel,
    required this.isSelected,
    required this.segmentCountLabel,
  });

  final String id;
  final String title;
  final String summary;
  final String actionKindLabel;
  final bool isSelected;
  final String segmentCountLabel;
}

class ReviewCenterSegmentViewData {
  const ReviewCenterSegmentViewData({
    required this.id,
    required this.label,
    required this.rangeLabel,
    required this.sourcePath,
    required this.isSelected,
  });

  final String id;
  final String label;
  final String rangeLabel;
  final String sourcePath;
  final bool isSelected;
}

class ReviewCenterPlanViewData {
  const ReviewCenterPlanViewData({
    required this.title,
    required this.summary,
    required this.instructions,
    required this.actionLabel,
    required this.outputPaths,
    required this.canCreateTask,
    required this.confirmButtonLabel,
  });

  final String title;
  final String summary;
  final String instructions;
  final String actionLabel;
  final List<String> outputPaths;
  final bool canCreateTask;
  final String confirmButtonLabel;

  factory ReviewCenterPlanViewData.empty() {
    return const ReviewCenterPlanViewData(
      title: '重写计划',
      summary: '',
      instructions: '',
      actionLabel: '',
      outputPaths: <String>[],
      canCreateTask: false,
      confirmButtonLabel: '生成建议',
    );
  }
}

class ReviewCenterPlaybackViewData {
  const ReviewCenterPlaybackViewData({
    required this.title,
    required this.sourcePath,
    required this.body,
  });

  final String title;
  final String sourcePath;
  final String body;

  factory ReviewCenterPlaybackViewData.empty() {
    return const ReviewCenterPlaybackViewData(
      title: '回放预览',
      sourcePath: '',
      body: '',
    );
  }
}
