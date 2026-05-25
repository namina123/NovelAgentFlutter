import 'project_storage_strategy.dart';

class ProjectDescriptor {
  const ProjectDescriptor({
    required this.id,
    required this.name,
    required this.rootPath,
    this.projectType = 'novel',
    this.storageStrategy = ProjectStorageStrategy.markdownProjectStore,
    this.runtimeBaselineId = '',
  });

  final String id;
  final String name;
  final String rootPath;
  final String projectType;
  final ProjectStorageStrategy storageStrategy;
  final String runtimeBaselineId;
}
