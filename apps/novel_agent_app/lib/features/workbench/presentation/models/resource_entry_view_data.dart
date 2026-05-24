class ResourceEntryViewData {
  const ResourceEntryViewData({
    required this.id,
    required this.title,
    required this.depth,
    required this.isDirectory,
    this.childCount = 0,
    this.hasChildren = false,
    this.isExpanded = false,
    this.isSelected = false,
  });

  final String id;
  final String title;
  final int depth;
  final bool isDirectory;
  final int childCount;
  final bool hasChildren;
  final bool isExpanded;
  final bool isSelected;
}
