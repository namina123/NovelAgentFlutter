class BookDeconstructionAssetStatusViewData {
  const BookDeconstructionAssetStatusViewData({
    required this.id,
    required this.title,
    required this.count,
    required this.statusLabel,
    required this.summary,
  });

  final String id;
  final String title;
  final int count;
  final String statusLabel;
  final String summary;
}
