import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:sqlite3/sqlite3.dart';

class SqliteProjectMetadataStore {
  static const String schemaVersion = '1';

  void ensureSchema(Database database) {
    // 中文注释: 项目级元数据单独成表，后续升级时可以只动这层，而不是把版本号塞进任意业务表。
    database.execute('''
      CREATE TABLE IF NOT EXISTS project_store_meta (
        meta_key TEXT PRIMARY KEY,
        value_text TEXT NOT NULL
      )
      ''');
  }

  void saveBootstrapMetadata(
    Database database, {
    required ProjectManifest manifest,
  }) {
    // 中文注释: 初始化元数据时只登记存储策略、schema 版本和正文存储规则，避免第一版就写入过多推导信息。
    final values = <String, String>{
      'storage_strategy': manifest.storageStrategy.id,
      'project_type': manifest.projectType,
      'schema_version': schemaVersion,
      'body_storage_policy': 'plain_text_or_segmented_text_only',
      'body_markdown_blob_allowed': 'false',
    };
    for (final entry in values.entries) {
      database.execute(
        '''
        INSERT INTO project_store_meta (meta_key, value_text)
        VALUES (?, ?)
        ON CONFLICT(meta_key) DO UPDATE SET value_text = excluded.value_text
        ''',
        <Object?>[entry.key, entry.value],
      );
    }
  }
}
