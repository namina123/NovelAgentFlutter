import 'package:novel_agent_core/novel_agent_core.dart';

import 'markdown_project_directory_skeleton_service.dart';

class MarkdownProjectContentRepository implements ProjectContentRepository {
  MarkdownProjectContentRepository({
    required ProjectWorkspacePort projectWorkspacePort,
    MarkdownProjectDirectorySkeletonService? directorySkeletonService,
  }) : _directorySkeletonService =
           directorySkeletonService ??
           MarkdownProjectDirectorySkeletonService(
             projectWorkspacePort: projectWorkspacePort,
           );

  final MarkdownProjectDirectorySkeletonService _directorySkeletonService;

  @override
  Future<void> initializeProjectContent({
    required String rootPath,
    required ProjectManifest manifest,
    required ProjectDirectoryLayout layout,
  }) async {
    // 中文注释: 主内容仓储这里只负责触发 Markdown 骨架初始化，不再自己内嵌目录结构细节。
    await _directorySkeletonService.createSkeleton(
      rootPath: rootPath,
      layout: layout,
    );
  }
}
