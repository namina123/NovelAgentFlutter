class DocumentTabViewData {
  const DocumentTabViewData({
    required this.id,
    required this.title,
    this.isActive = false,
  });

  final String id;
  final String title;
  final bool isActive;
}
