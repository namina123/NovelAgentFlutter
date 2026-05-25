class ProjectRuntimeBaselineDefinition {
  const ProjectRuntimeBaselineDefinition({
    required this.id,
    required this.title,
    required this.description,
    this.enabled = true,
  });

  final String id;
  final String title;
  final String description;
  final bool enabled;
}
