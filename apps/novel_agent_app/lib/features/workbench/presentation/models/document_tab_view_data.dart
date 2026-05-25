class DocumentTabViewData {
  const DocumentTabViewData({
    required this.id,
    required this.title,
    this.relativePath = '',
    this.isActive = false,
    this.isDirty = false,
  });

  final String id;
  final String title;
  final String relativePath;
  final bool isActive;
  final bool isDirty;
}
