class ProjectTypeDefinition {
  const ProjectTypeDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.defaultTitle,
    this.enabled = true,
  });

  final String id;
  final String name;
  final String description;
  final String defaultTitle;
  final bool enabled;
}
