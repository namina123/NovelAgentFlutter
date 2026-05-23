class ProjectManifest {
  const ProjectManifest({
    required this.title,
    required this.projectType,
    this.schemaVersion = 1,
  });

  final String title;
  final String projectType;
  final int schemaVersion;
}
