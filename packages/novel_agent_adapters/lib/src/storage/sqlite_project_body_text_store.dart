import 'package:sqlite3/sqlite3.dart';

class SqliteProjectBodyTextStore {
  void ensureSchema(Database database) {
    // 中文注释: 正文主表只保存“文档级元数据 + 纯文本总览”，不接受整篇 Markdown 文档串作为主存储格式。
    database.execute('''
      CREATE TABLE IF NOT EXISTS body_text_document (
        document_id TEXT PRIMARY KEY,
        document_kind TEXT NOT NULL,
        title TEXT NOT NULL,
        storage_format TEXT NOT NULL,
        plain_text TEXT NOT NULL DEFAULT '',
        markdown_path TEXT NOT NULL DEFAULT '',
        state_path TEXT NOT NULL DEFAULT '',
        status TEXT NOT NULL DEFAULT 'draft',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
      ''');
    // 中文注释: 分段表只承担段级正文内容，后续场景拆分、局部重写和精细检索都围绕这张表扩展。
    database.execute('''
      CREATE TABLE IF NOT EXISTS body_text_segment (
        document_id TEXT NOT NULL,
        segment_id TEXT NOT NULL,
        ordinal_index INTEGER NOT NULL,
        segment_kind TEXT NOT NULL,
        text_value TEXT NOT NULL,
        char_count INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        PRIMARY KEY (document_id, segment_id)
      )
      ''');
    database.execute('''
      CREATE INDEX IF NOT EXISTS idx_body_text_segment_document_ordinal
      ON body_text_segment(document_id, ordinal_index)
      ''');
  }
}
