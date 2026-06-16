import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('SqliteProjectReadableProjectionService', () {
    late Directory tempDirectory;
    late LocalProjectWorkspacePort workspacePort;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'sqlite_project_readable_projection_service_test_',
      );
      workspacePort = LocalProjectWorkspacePort();
      await workspacePort.writeTextFile(
        tempDirectory.path,
        'chapters/chapter_01.md',
        '# 第一章\n\n正文内容。',
      );
      await workspacePort.writeTextFile(
        tempDirectory.path,
        'knowledge/card_01.md',
        '# 知识卡\n\n卡片内容。',
      );
      await workspacePort.writeTextFile(
        tempDirectory.path,
        '.novel_agent/sqlite/novel_agent.db',
        'sqlite-binary-placeholder',
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'writes semantic projection documents instead of a single brief file',
      () async {
        // 中文注释: 这里确认 SQLite 项目会物化语义树目录，而不是只留一个 overview 说明页充当伪入口。
        final service = SqliteProjectReadableProjectionService(
          projectWorkspacePort: workspacePort,
        );
        final manifest = ProjectManifest(
          title: 'SQLite 项目',
          projectType: 'novel',
          storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
        );
        final layout = const ProjectDirectoryLayoutService().layoutFor(
          ProjectStorageStrategy.sqliteProjectStore,
        );

        await service.ensureReadableProjection(
          rootPath: tempDirectory.path,
          manifest: manifest,
          layout: layout,
        );

        final projectOverview = File(
          '${tempDirectory.path}${Platform.pathSeparator}premise${Platform.pathSeparator}project_overview.md',
        );
        final indexDocument = File(
          '${tempDirectory.path}${Platform.pathSeparator}premise${Platform.pathSeparator}sqlite_projection${Platform.pathSeparator}index.md',
        );
        final chaptersDocument = File(
          '${tempDirectory.path}${Platform.pathSeparator}premise${Platform.pathSeparator}sqlite_projection${Platform.pathSeparator}body_and_chapters.md',
        );
        final materialsDocument = File(
          '${tempDirectory.path}${Platform.pathSeparator}premise${Platform.pathSeparator}sqlite_projection${Platform.pathSeparator}project_materials.md',
        );

        expect(await projectOverview.exists(), isTrue);
        expect(await indexDocument.exists(), isTrue);
        expect(await chaptersDocument.exists(), isTrue);
        expect(await materialsDocument.exists(), isTrue);

        final indexMarkdown = await indexDocument.readAsString();
        expect(indexMarkdown, contains('SQLite 项目语义树'));
        expect(indexMarkdown, contains('正文与章节'));
        expect(indexMarkdown, contains('.novel_agent/sqlite/novel_agent.db'));

        final overviewMarkdown = await projectOverview.readAsString();
        expect(overviewMarkdown, contains('SQLite 项目快速概览'));
        expect(overviewMarkdown, contains('正式主事实源是 SQLite'));
        expect(
          overviewMarkdown,
          contains('premise/sqlite_projection/index.md'),
        );
      },
    );
  });
}
