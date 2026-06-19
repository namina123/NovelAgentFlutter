import 'package:sqlite3/sqlite3.dart';

class SqliteRagMetadataStore {
  static const String schemaVersion = '1';

  void ensureSchema(Database database) {
    // 中文注释: RAG 元数据基座只负责建表和稳定索引，不承担向量索引或检索计算。
    database.execute('PRAGMA foreign_keys = ON;');
    database.execute('''
      CREATE TABLE IF NOT EXISTS rag_meta (
        meta_key TEXT PRIMARY KEY,
        value_text TEXT NOT NULL
      )
      ''');
    database.execute('''
      CREATE TABLE IF NOT EXISTS rag_corpus (
        corpus_id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        source_kind TEXT NOT NULL,
        build_mode TEXT NOT NULL,
        language TEXT NOT NULL,
        version TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        source_count INTEGER NOT NULL DEFAULT 0,
        chapter_count INTEGER NOT NULL DEFAULT 0,
        chunk_count INTEGER NOT NULL DEFAULT 0,
        is_model_assisted INTEGER NOT NULL DEFAULT 0,
        capability_flags_json TEXT NOT NULL,
        payload_json TEXT NOT NULL
      )
      ''');
    database.execute('''
      CREATE TABLE IF NOT EXISTS rag_source_document (
        source_document_id TEXT PRIMARY KEY,
        corpus_id TEXT NOT NULL,
        source_kind TEXT NOT NULL,
        display_name TEXT NOT NULL,
        origin_path TEXT NOT NULL,
        origin_format TEXT NOT NULL,
        language TEXT NOT NULL,
        content_hash TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        FOREIGN KEY(corpus_id) REFERENCES rag_corpus(corpus_id)
          ON DELETE CASCADE
      )
      ''');
    database.execute('''
      CREATE TABLE IF NOT EXISTS rag_chunk (
        chunk_id TEXT PRIMARY KEY,
        corpus_id TEXT NOT NULL,
        source_document_id TEXT NOT NULL,
        chapter_index INTEGER NOT NULL DEFAULT 0,
        chapter_title TEXT NOT NULL,
        segment_index INTEGER NOT NULL DEFAULT 0,
        range_start INTEGER NOT NULL DEFAULT 0,
        range_end INTEGER NOT NULL DEFAULT 0,
        text_value TEXT NOT NULL,
        normalized_text TEXT NOT NULL,
        token_estimate INTEGER NOT NULL DEFAULT 0,
        payload_json TEXT NOT NULL,
        FOREIGN KEY(corpus_id) REFERENCES rag_corpus(corpus_id)
          ON DELETE CASCADE,
        FOREIGN KEY(source_document_id) REFERENCES rag_source_document(
          source_document_id
        ) ON DELETE CASCADE
      )
      ''');
    database.execute('''
      CREATE TABLE IF NOT EXISTS rag_mount_binding (
        binding_id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        corpus_id TEXT NOT NULL,
        mount_scope TEXT NOT NULL,
        priority INTEGER NOT NULL DEFAULT 0,
        usage_policy TEXT NOT NULL,
        activation_policy TEXT NOT NULL,
        created_at TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        FOREIGN KEY(corpus_id) REFERENCES rag_corpus(corpus_id)
          ON DELETE CASCADE
      )
      ''');
    database.execute('''
      CREATE TABLE IF NOT EXISTS rag_index_handle (
        index_handle_id TEXT PRIMARY KEY,
        corpus_id TEXT NOT NULL,
        backend_kind TEXT NOT NULL,
        backend_location TEXT NOT NULL,
        embedding_dimension INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL,
        version TEXT NOT NULL,
        last_built_at TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        FOREIGN KEY(corpus_id) REFERENCES rag_corpus(corpus_id)
          ON DELETE CASCADE
      )
      ''');
    database.execute('''
      CREATE TABLE IF NOT EXISTS rag_ingestion_run (
        ingestion_run_id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        corpus_id TEXT NOT NULL,
        source_document_id TEXT NOT NULL,
        status TEXT NOT NULL,
        started_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        FOREIGN KEY(corpus_id) REFERENCES rag_corpus(corpus_id)
          ON DELETE CASCADE,
        FOREIGN KEY(source_document_id) REFERENCES rag_source_document(
          source_document_id
        ) ON DELETE CASCADE
      )
      ''');
    database.execute('''
      CREATE INDEX IF NOT EXISTS idx_rag_source_document_corpus
      ON rag_source_document(corpus_id, source_kind, source_document_id)
      ''');
    database.execute('''
      CREATE INDEX IF NOT EXISTS idx_rag_chunk_corpus_source
      ON rag_chunk(corpus_id, source_document_id, chapter_index, segment_index)
      ''');
    database.execute('''
      CREATE INDEX IF NOT EXISTS idx_rag_mount_binding_project
      ON rag_mount_binding(project_id, corpus_id, priority, binding_id)
      ''');
    database.execute('''
      CREATE INDEX IF NOT EXISTS idx_rag_index_handle_corpus
      ON rag_index_handle(corpus_id, status, index_handle_id)
      ''');
    database.execute('''
      CREATE INDEX IF NOT EXISTS idx_rag_ingestion_run_project
      ON rag_ingestion_run(project_id, corpus_id, source_document_id, updated_at)
      ''');
  }

  void saveBootstrapMetadata(Database database) {
    // 中文注释: 这里登记 RAG 元数据基座的最小自描述信息，方便后续检测 schema 是否已就绪。
    final values = <String, String>{
      'schema_version': schemaVersion,
      'metadata_policy': 'metadata_and_mapping_only',
      'vector_backend_policy': 'external_or_placeholder_only',
      'mount_policy': 'project_scoped_bindings',
    };
    for (final entry in values.entries) {
      database.execute(
        '''
        INSERT INTO rag_meta (meta_key, value_text)
        VALUES (?, ?)
        ON CONFLICT(meta_key) DO UPDATE SET value_text = excluded.value_text
        ''',
        <Object?>[entry.key, entry.value],
      );
    }
  }
}
