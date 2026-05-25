import 'package:novel_agent_core/novel_agent_core.dart';

class SqliteProjectDirectorySkeletonService {
  SqliteProjectDirectorySkeletonService({
    required ProjectWorkspacePort projectWorkspacePort,
  }) : _projectWorkspacePort = projectWorkspacePort;

  final ProjectWorkspacePort _projectWorkspacePort;

  Future<void> createSkeleton({
    required String rootPath,
    required ProjectDirectoryLayout layout,
  }) async {
    // 中文注释: SQLite 项目虽然主内容在数据库，但高级目录和隐藏目录仍要先稳定创建，保证投影、导出和运行记录有固定落点。
    for (final descriptor in layout.advancedDirectories) {
      await _projectWorkspacePort.createDirectory(rootPath, descriptor.path);
    }
    for (final descriptor in layout.internalDirectories) {
      await _projectWorkspacePort.createDirectory(rootPath, descriptor.path);
    }
  }
}
