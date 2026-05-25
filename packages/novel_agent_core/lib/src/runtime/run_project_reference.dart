import '../project/project_descriptor.dart';
import '../project/project_storage_strategy.dart';

class RunProjectReference {
  const RunProjectReference({
    required this.projectId,
    required this.projectKey,
    required this.rootPath,
    required this.title,
    required this.projectTypeId,
    required this.storageStrategy,
  });

  final String projectId;
  final String projectKey;
  final String rootPath;
  final String title;
  final String projectTypeId;
  final ProjectStorageStrategy storageStrategy;

  factory RunProjectReference.fromProject(ProjectDescriptor project) {
    // 中文注释: 全局运行实例不能依赖“当前页面打开着哪个项目”，因此这里把项目关联压成可持久化的最小引用。
    return RunProjectReference(
      projectId: project.id,
      projectKey: project.rootPath,
      rootPath: project.rootPath,
      title: project.name,
      projectTypeId: project.projectType,
      storageStrategy: project.storageStrategy,
    );
  }
}
