import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('MarkdownProjectDirectorySkeletonService', () {
    test('creates new visible and hidden workspace skeleton', () async {
      // 中文注释: 这里验证 Markdown 项目创建时会生成新的双层目录结构，而不是继续依赖旧 specs/outline 骨架。
      final tempRoot = await Directory.systemTemp.createTemp(
        'novel-agent-markdown-skeleton-',
      );
      try {
        final projectRoot = Directory(
          '${tempRoot.path}${Platform.pathSeparator}project',
        )..createSync(recursive: true);
        final workspacePort = LocalProjectWorkspacePort();
        final repository = MarkdownProjectContentRepository(
          projectWorkspacePort: workspacePort,
        );
        final projectionService = MarkdownProjectReadableProjectionService(
          projectWorkspacePort: workspacePort,
        );
        final layout = const ProjectDirectoryLayoutService().layoutFor(
          ProjectStorageStrategy.markdownProjectStore,
        );
        const manifest = ProjectManifest(
          title: '目录重构测试',
          projectType: 'novel',
          storageStrategy: ProjectStorageStrategy.markdownProjectStore,
        );

        await repository.initializeProjectContent(
          rootPath: projectRoot.path,
          manifest: manifest,
          layout: layout,
        );
        await projectionService.ensureReadableProjection(
          rootPath: projectRoot.path,
          manifest: manifest,
          layout: layout,
        );

        expect(
          Directory(
            '${projectRoot.path}${Platform.pathSeparator}premise',
          ).existsSync(),
          isTrue,
        );
        expect(
          Directory(
            '${projectRoot.path}${Platform.pathSeparator}outlines${Platform.pathSeparator}story',
          ).existsSync(),
          isTrue,
        );
        expect(
          Directory(
            '${projectRoot.path}${Platform.pathSeparator}assets${Platform.pathSeparator}foreshadows',
          ).existsSync(),
          isTrue,
        );
        expect(
          Directory(
            '${projectRoot.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}runtime',
          ).existsSync(),
          isTrue,
        );
        expect(
          File(
            '${projectRoot.path}${Platform.pathSeparator}premise${Platform.pathSeparator}project_brief.md',
          ).existsSync(),
          isTrue,
        );
        expect(
          Directory(
            '${projectRoot.path}${Platform.pathSeparator}specs',
          ).existsSync(),
          isFalse,
        );
      } finally {
        if (tempRoot.existsSync()) {
          await tempRoot.delete(recursive: true);
        }
      }
    });
  });
}
