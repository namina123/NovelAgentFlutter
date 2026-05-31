import 'package:novel_agent_core/novel_agent_core.dart';

class WorkspaceCommandDefaultTargetService {
  WorkspaceCommandDefaultTargetService({
    ProjectContentPathPolicyService? contentPathPolicyService,
  }) : _contentPathPolicyService =
           contentPathPolicyService ?? const ProjectContentPathPolicyService();

  final ProjectContentPathPolicyService _contentPathPolicyService;

  String createFileDirectory() {
    // 中文注释: 工作区“新建文件”默认目标目录统一由这个轻量服务提供，避免控制器写死旧目录常量。
    return _contentPathPolicyService.defaultWorkspaceFileDirectory();
  }

  String createFolderParentDirectory() {
    // 中文注释: 工作区“新建文件夹”默认挂到当前正式资产根，而不是继续使用旧兼容目录。
    return _contentPathPolicyService.defaultWorkspaceFolderDirectory();
  }

  String importTargetDirectory() {
    // 中文注释: 工作区导入默认目标集中在这里，便于后续按项目策略再细分导入落点。
    return _contentPathPolicyService.defaultImportTargetDirectory();
  }
}
