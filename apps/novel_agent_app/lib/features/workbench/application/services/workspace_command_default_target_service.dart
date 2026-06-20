import 'package:novel_agent_core/novel_agent_core.dart';

class WorkspaceCommandDefaultTargetService {
  WorkspaceCommandDefaultTargetService({
    ProjectStorageStrategyPathPolicyService? storageStrategyPathPolicyService,
  }) : _storageStrategyPathPolicyService =
           storageStrategyPathPolicyService ??
           const ProjectStorageStrategyPathPolicyService();

  final ProjectStorageStrategyPathPolicyService
  _storageStrategyPathPolicyService;

  String createFileDirectory({
    ProjectStorageStrategy storageStrategy =
        ProjectStorageStrategy.markdownProjectStore,
  }) {
    // 中文注释: 工作区“新建文件”默认目标目录统一由这个轻量服务提供，避免控制器写死旧目录常量。
    return _storageStrategyPathPolicyService.defaultWorkspaceFileDirectory(
      storageStrategy,
    );
  }

  String createFolderParentDirectory({
    ProjectStorageStrategy storageStrategy =
        ProjectStorageStrategy.markdownProjectStore,
  }) {
    // 中文注释: 工作区“新建文件夹”默认挂到当前正式资产根，而不是继续使用旧兼容目录。
    return _storageStrategyPathPolicyService.defaultWorkspaceFolderDirectory(
      storageStrategy,
    );
  }

  String importTargetDirectory({
    ProjectStorageStrategy storageStrategy =
        ProjectStorageStrategy.markdownProjectStore,
  }) {
    // 中文注释: 工作区导入默认目标集中在这里，便于后续按项目策略再细分导入落点。
    return _storageStrategyPathPolicyService.defaultImportTargetDirectory(
      storageStrategy,
    );
  }
}
