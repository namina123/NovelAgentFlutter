class ResourceEntryViewData {
  const ResourceEntryViewData({
    required this.id,
    required this.title,
    required this.depth,
    required this.isDirectory,
    this.isSelected = false,
  });

  final String id;
  final String title;
  final int depth;
  final bool isDirectory;
  final bool isSelected;
}
