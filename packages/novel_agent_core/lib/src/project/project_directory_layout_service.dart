import 'project_directory_layout.dart';
import 'project_storage_strategy.dart';
import 'project_workspace_catalog.dart';
import 'workspace_directory_descriptor.dart';

class ProjectDirectoryLayoutService {
  const ProjectDirectoryLayoutService();

  ProjectDirectoryLayout layoutFor(ProjectStorageStrategy storageStrategy) {
    // 中文注释: 目录布局先由存储策略决定；后续即使真正换新目录结构，也只需要在这里集中切换。
    switch (storageStrategy) {
      case ProjectStorageStrategy.markdownProjectStore:
        return ProjectDirectoryLayout(
          storageStrategy: storageStrategy,
          primaryContentDirectories:
              ProjectWorkspaceCatalog.visibleWorkspaceSkeletonDirs,
          readableProjectionDirectories: const <WorkspaceDirectoryDescriptor>[],
          advancedDirectories: ProjectWorkspaceCatalog.advancedWorkspaceDirs,
          internalDirectories: ProjectWorkspaceCatalog.internalWorkspaceDirs,
        );
      case ProjectStorageStrategy.sqliteProjectStore:
        return ProjectDirectoryLayout(
          storageStrategy: storageStrategy,
          primaryContentDirectories: const <WorkspaceDirectoryDescriptor>[],
          readableProjectionDirectories:
              ProjectWorkspaceCatalog.visibleWorkspaceSkeletonDirs,
          advancedDirectories: ProjectWorkspaceCatalog.advancedWorkspaceDirs,
          internalDirectories: ProjectWorkspaceCatalog.internalWorkspaceDirs,
        );
    }
  }
}
