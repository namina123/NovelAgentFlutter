import 'project_storage_strategy.dart';

class ProjectManifest {
  const ProjectManifest({
    required this.title,
    required this.projectType,
    this.storageStrategy = ProjectStorageStrategy.markdownProjectStore,
    this.runtimeBaselineId = '',
    this.schemaVersion = 1,
  });

  final String title;
  final String projectType;
  final ProjectStorageStrategy storageStrategy;
  final String runtimeBaselineId;
  final int schemaVersion;
}
