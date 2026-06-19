import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  group('SqliteRagMetadataStore', () {
    test('initializer creates rag metadata tables and bootstrap values', () async {
      final tempRoot = await Directory.systemTemp.createTemp(
        'novel-agent-rag-metadata-store-',
      );
      try {
        final projectRoot = Directory(
          '${tempRoot.path}${Platform.pathSeparator}project',
        )..createSync(recursive: true);
        final initializer = SqliteProjectDatabaseInitializer();
        const manifest = ProjectManifest(
          title: 'RAG SQLite 测试',
          projectType: 'novel',
          storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
        );

        await initializer.initialize(
          rootPath: projectRoot.path,
          manifest: manifest,
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
          expect(tableNames, contains('rag_meta'));
          expect(tableNames, contains('rag_corpus'));
          expect(tableNames, contains('rag_source_document'));
          expect(tableNames, contains('rag_chunk'));
          expect(tableNames, contains('rag_mount_binding'));
          expect(tableNames, contains('rag_index_handle'));
          expect(tableNames, contains('rag_ingestion_run'));

          final metadataRows = database.select('''
            SELECT meta_key, value_text
            FROM rag_meta
            ORDER BY meta_key
            ''');
          final metadata = <String, String>{
            for (final row in metadataRows)
              row['meta_key']?.toString() ?? '':
                  row['value_text']?.toString() ?? '',
          };
          expect(metadata['schema_version'], SqliteRagMetadataStore.schemaVersion);
          expect(metadata['metadata_policy'], 'metadata_and_mapping_only');
          expect(metadata['vector_backend_policy'], 'external_or_placeholder_only');
          expect(metadata['mount_policy'], 'project_scoped_bindings');
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
