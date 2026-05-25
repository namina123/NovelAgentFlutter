import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Project storage strategy adapters', () {
    test('resolver reads storage strategy from manifest', () async {
      // 中文注释: 这里验证本地项目打开前的策略识别会尊重 manifest，而不是总按 Markdown 猜测。
      final tempRoot = await Directory.systemTemp.createTemp(
        'novel-agent-storage-resolver-',
      );
      try {
        final projectRoot = Directory(
          '${tempRoot.path}${Platform.pathSeparator}project',
        )..createSync(recursive: true);
        final codec = ProjectManifestCodecService();
        final manifest = codec.create(
          title: 'SQLite 项目',
          projectType: 'novel',
          storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
        );
        final manifestFile = File(
          '${projectRoot.path}${Platform.pathSeparator}${ProjectManifestCodecService.manifestRelativePath.replaceAll('/', Platform.pathSeparator)}',
        )..createSync(recursive: true);
        await manifestFile.writeAsString(codec.encode(manifest));

        final resolver = ProjectStorageStrategyResolver();
        final strategy = await resolver.resolveFromRootPath(projectRoot.path);

        expect(strategy, ProjectStorageStrategy.sqliteProjectStore);
      } finally {
        if (tempRoot.existsSync()) {
          await tempRoot.delete(recursive: true);
        }
      }
    });

    test('delegating content repository routes by manifest strategy', () async {
      // 中文注释: 这里验证分发壳只做策略路由，不会把 Markdown/SQLite 初始化逻辑重新耦回一个大仓储。
      final markdownRepository = _RecordingProjectContentRepository();
      final sqliteRepository = _RecordingProjectContentRepository();
      final repository = DelegatingProjectContentRepository(
        markdownRepository: markdownRepository,
        sqliteRepository: sqliteRepository,
      );

      await repository.initializeProjectContent(
        rootPath: 'D:/demo',
        manifest: const ProjectManifest(
          title: 'SQLite',
          projectType: 'novel',
          storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
        ),
        layout: const ProjectDirectoryLayout(
          storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
          primaryContentDirectories: <WorkspaceDirectoryDescriptor>[],
          readableProjectionDirectories: <WorkspaceDirectoryDescriptor>[],
          advancedDirectories: <WorkspaceDirectoryDescriptor>[],
          internalDirectories: <WorkspaceDirectoryDescriptor>[],
        ),
      );

      expect(markdownRepository.callCount, 0);
      expect(sqliteRepository.callCount, 1);
    });
  });
}

class _RecordingProjectContentRepository implements ProjectContentRepository {
  int callCount = 0;

  @override
  Future<void> initializeProjectContent({
    required String rootPath,
    required ProjectManifest manifest,
    required ProjectDirectoryLayout layout,
  }) async {
    // 中文注释: 该测试替身只记录是否被命中，避免把真实文件系统副作用带进策略分发测试。
    callCount += 1;
  }
}
