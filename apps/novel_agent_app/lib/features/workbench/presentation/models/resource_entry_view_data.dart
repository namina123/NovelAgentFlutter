class ResourceEntryViewData {
  const ResourceEntryViewData({
    required this.id,
    required this.title,
    required this.relativePath,
    required this.depth,
    required this.isDirectory,
    this.childCount = 0,
    this.hasChildren = false,
    this.isExpanded = false,
    this.isSelected = false,
  });

  final String id;
  final String title;
  final String relativePath;
  final int depth;
  final bool isDirectory;
  final int childCount;
  final bool hasChildren;
  final bool isExpanded;
  final bool isSelected;

  ResourceEntryViewData copyWith({
    String? id,
    String? title,
    String? relativePath,
    int? depth,
    bool? isDirectory,
    int? childCount,
    bool? hasChildren,
    bool? isExpanded,
    bool? isSelected,
  }) {
    // 中文注释: 资源树条目作为纯展示模型，也需要最小 copy 能力给控制器做投影变换。
    return ResourceEntryViewData(
      id: id ?? this.id,
      title: title ?? this.title,
      relativePath: relativePath ?? this.relativePath,
      depth: depth ?? this.depth,
      isDirectory: isDirectory ?? this.isDirectory,
      childCount: childCount ?? this.childCount,
      hasChildren: hasChildren ?? this.hasChildren,
      isExpanded: isExpanded ?? this.isExpanded,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
