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
    // 中文注释: SQLite 项目只创建最小物理骨架；其余工作区语义面主要通过只读投影暴露。
    for (final descriptor in layout.readableProjectionDirectories) {
      await _projectWorkspacePort.createDirectory(rootPath, descriptor.path);
    }
    for (final descriptor in layout.advancedDirectories) {
      await _projectWorkspacePort.createDirectory(rootPath, descriptor.path);
    }
    for (final descriptor in layout.internalDirectories) {
      await _projectWorkspacePort.createDirectory(rootPath, descriptor.path);
    }
  }
}
