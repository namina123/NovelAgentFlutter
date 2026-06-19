import 'package:novel_agent_core/novel_agent_core.dart';

import 'sqlite_project_body_text_store.dart';
import 'sqlite_project_database_opener.dart';
import 'sqlite_project_metadata_store.dart';
import 'sqlite_rag_metadata_store.dart';

class SqliteProjectDatabaseInitializer {
  SqliteProjectDatabaseInitializer({
    SqliteProjectDatabaseOpener? databaseOpener,
    SqliteProjectMetadataStore? metadataStore,
    SqliteRagMetadataStore? ragMetadataStore,
    SqliteProjectBodyTextStore? bodyTextStore,
  }) : _databaseOpener = databaseOpener ?? SqliteProjectDatabaseOpener(),
       _metadataStore = metadataStore ?? SqliteProjectMetadataStore(),
       _ragMetadataStore = ragMetadataStore ?? SqliteRagMetadataStore(),
       _bodyTextStore = bodyTextStore ?? SqliteProjectBodyTextStore();

  final SqliteProjectDatabaseOpener _databaseOpener;
  final SqliteProjectMetadataStore _metadataStore;
  final SqliteRagMetadataStore _ragMetadataStore;
  final SqliteProjectBodyTextStore _bodyTextStore;

  Future<void> initialize({
    required String rootPath,
    required ProjectManifest manifest,
  }) async {
    // 中文注释: SQLite 项目初始化只做最小建库和规则登记，不在这里偷渡具体正文写入或跨策略迁移。
    final database = _databaseOpener.open(rootPath);
    try {
      database.execute('BEGIN');
      _metadataStore.ensureSchema(database);
      _ragMetadataStore.ensureSchema(database);
      _bodyTextStore.ensureSchema(database);
      _metadataStore.saveBootstrapMetadata(database, manifest: manifest);
      _ragMetadataStore.saveBootstrapMetadata(database);
      database.execute('COMMIT');
    } catch (_) {
      database.execute('ROLLBACK');
      rethrow;
    } finally {
      database.dispose();
    }
  }
}
