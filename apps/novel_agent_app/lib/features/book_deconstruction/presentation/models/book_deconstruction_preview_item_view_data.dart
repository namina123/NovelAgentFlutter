class BookDeconstructionPreviewItemViewData {
  const BookDeconstructionPreviewItemViewData({
    required this.id,
    required this.title,
    required this.summary,
    this.caption = '',
  });

  final String id;
  final String title;
  final String summary;
  final String caption;
}
