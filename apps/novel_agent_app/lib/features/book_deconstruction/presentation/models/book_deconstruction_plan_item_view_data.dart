class BookDeconstructionPlanItemViewData {
  const BookDeconstructionPlanItemViewData({
    required this.id,
    required this.title,
    required this.summary,
    required this.relativePathHint,
    required this.actionLabel,
    required this.isSelected,
  });

  final String id;
  final String title;
  final String summary;
  final String relativePathHint;
  final String actionLabel;
  final bool isSelected;
}
