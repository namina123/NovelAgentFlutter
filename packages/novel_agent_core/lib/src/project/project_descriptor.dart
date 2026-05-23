class ProjectDescriptor {
  const ProjectDescriptor({
    required this.id,
    required this.name,
    required this.rootPath,
    this.projectType = 'novel',
  });

  final String id;
  final String name;
  final String rootPath;
  final String projectType;
}
