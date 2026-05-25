import 'package:novel_agent_core/novel_agent_core.dart';

class MarkdownProjectDirectorySkeletonService {
  MarkdownProjectDirectorySkeletonService({
    required ProjectWorkspacePort projectWorkspacePort,
  }) : _projectWorkspacePort = projectWorkspacePort;

  final ProjectWorkspacePort _projectWorkspacePort;

  Future<void> createSkeleton({
    required String rootPath,
    required ProjectDirectoryLayout layout,
  }) async {
    // 中文注释: Markdown 项目的目录骨架在这里统一生成，避免仓储同时承担“决定结构”和“执行落盘”两种职责。
    for (final descriptor in layout.primaryContentDirectories) {
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
