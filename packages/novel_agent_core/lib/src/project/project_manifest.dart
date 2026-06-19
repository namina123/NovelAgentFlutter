import 'project_storage_strategy.dart';

class ProjectManifest {
  const ProjectManifest({
    required this.title,
    required this.projectType,
    this.storageStrategy = ProjectStorageStrategy.markdownProjectStore,
    this.projectBranchId = '',
    this.runtimeBaselineId = '',
    this.schemaVersion = 1,
  });

  final String title;
  final String projectType;
  final ProjectStorageStrategy storageStrategy;
  final String projectBranchId;
  final String runtimeBaselineId;
  final int schemaVersion;
}
