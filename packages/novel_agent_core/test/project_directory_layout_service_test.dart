import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectDirectoryLayoutService', () {
    test('markdown layout exposes user directories as primary content', () {
      // 中文注释: Markdown 项目应把用户工作目录直接视为主内容来源，而不是额外投影层。
      const service = ProjectDirectoryLayoutService();

      final layout = service.layoutFor(
        ProjectStorageStrategy.markdownProjectStore,
      );

      expect(
        layout.storageStrategy,
        ProjectStorageStrategy.markdownProjectStore,
      );
      expect(
        layout.primaryContentDirectories.length,
        ProjectWorkspaceCatalog.visibleWorkspaceSkeletonDirs.length,
      );
      expect(layout.readableProjectionDirectories, isEmpty);
      expect(layout.internalDirectories, isNotEmpty);
      expect(
        layout.primaryContentDirectories.any(
          (descriptor) => descriptor.path == 'outlines/story/',
        ),
        isTrue,
      );
    });

    test('sqlite layout exposes user directories as readable projection', () {
      // 中文注释: SQLite 项目当前阶段不把用户目录当事实来源，而是保留成可读投影视图入口。
      const service = ProjectDirectoryLayoutService();

      final layout = service.layoutFor(
        ProjectStorageStrategy.sqliteProjectStore,
      );

      expect(layout.storageStrategy, ProjectStorageStrategy.sqliteProjectStore);
      expect(layout.primaryContentDirectories, isEmpty);
      expect(
        layout.readableProjectionDirectories.length,
        ProjectWorkspaceCatalog.visibleWorkspaceSkeletonDirs.length,
      );
      expect(layout.internalDirectories, isNotEmpty);
      expect(
        layout.readableProjectionDirectories.any(
          (descriptor) => descriptor.path == 'assets/foreshadows/',
        ),
        isTrue,
      );
    });
  });
}
