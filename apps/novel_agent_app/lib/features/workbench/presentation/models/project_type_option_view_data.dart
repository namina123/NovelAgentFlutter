class ProjectTypeOptionViewData {
  const ProjectTypeOptionViewData({
    required this.id,
    required this.title,
    required this.description,
    required this.defaultTitle,
    required this.requiresRuntimeBaselineSelection,
  });

  final String id;
  final String title;
  final String description;
  final String defaultTitle;
  final bool requiresRuntimeBaselineSelection;
}
