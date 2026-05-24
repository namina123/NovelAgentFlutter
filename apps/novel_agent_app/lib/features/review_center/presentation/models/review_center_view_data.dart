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

  factory ReviewCenterViewData.initial() {
    return const ReviewCenterViewData(
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
  const ReviewTypeOptionViewData({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}
