import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  group('SqliteProjectContentRepository', () {
    test('initializes sqlite store with minimal schema and metadata', () async {
      // 中文注释: 这里验证 SQLite 项目初始化会真正建库建表，而不是继续写一个占位文本文件冒充数据库。
      final tempRoot = await Directory.systemTemp.createTemp(
        'novel-agent-sqlite-store-',
      );
      try {
        final projectRoot = Directory(
          '${tempRoot.path}${Platform.pathSeparator}project',
        )..createSync(recursive: true);
        final workspacePort = LocalProjectWorkspacePort();
        final repository = SqliteProjectContentRepository(
          projectWorkspacePort: workspacePort,
        );
        final layout = const ProjectDirectoryLayoutService().layoutFor(
          ProjectStorageStrategy.sqliteProjectStore,
        );
        const manifest = ProjectManifest(
          title: 'SQLite 仓储测试',
          projectType: 'novel',
          storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
        );

        await repository.initializeProjectContent(
          rootPath: projectRoot.path,
          manifest: manifest,
          layout: layout,
        );

        final databaseFile = File(
          '${projectRoot.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}sqlite${Platform.pathSeparator}novel_agent.db',
        );
        expect(await databaseFile.exists(), isTrue);
        final database = sqlite3.open(databaseFile.path);
        try {
          final tableRows = database.select('''
            SELECT name
            FROM sqlite_master
            WHERE type = 'table'
            ORDER BY name
            ''');
          final tableNames = tableRows
              .map((row) => row['name']?.toString() ?? '')
              .toList(growable: false);
          expect(tableNames, contains('project_store_meta'));
          expect(tableNames, contains('body_text_document'));
          expect(tableNames, contains('body_text_segment'));

          final metadataRows = database.select('''
            SELECT meta_key, value_text
            FROM project_store_meta
            ORDER BY meta_key
            ''');
          final metadata = <String, String>{
            for (final row in metadataRows)
              row['meta_key']?.toString() ?? '':
                  row['value_text']?.toString() ?? '',
          };
          expect(metadata['storage_strategy'], 'sqlite_project_store');
          expect(
            metadata['schema_version'],
            SqliteProjectMetadataStore.schemaVersion,
          );
          expect(metadata['body_markdown_blob_allowed'], 'false');
        } finally {
          database.dispose();
        }
      } finally {
        if (tempRoot.existsSync()) {
          await tempRoot.delete(recursive: true);
        }
      }
    });
  });
}
