import '../common/host_platform.dart';
import '../project/project_storage_strategy.dart';

class ProjectToolExposureContext {
  const ProjectToolExposureContext({
    this.projectType = '',
    this.storageStrategy = ProjectStorageStrategy.markdownProjectStore,
    this.hostPlatform = HostPlatform.unknown,
    this.isSubAgent = false,
  });

  final String projectType;
  final ProjectStorageStrategy storageStrategy;
  final HostPlatform hostPlatform;
  final bool isSubAgent;

  bool get isSqliteProject =>
      storageStrategy == ProjectStorageStrategy.sqliteProjectStore;
}
