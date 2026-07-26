import 'package:novel_agent_core/src/project/project_body_text_repository.dart';
import 'package:novel_agent_core/src/project/sqlite_project_body_text_document.dart';
import 'package:novel_agent_core/src/project/sqlite_project_body_text_segment.dart';
import 'package:novel_agent_core/src/project/sqlite_project_body_text_storage_format.dart';
import 'package:sqlite3/sqlite3.dart';

import 'sqlite_project_body_text_store.dart';
import 'sqlite_project_database_opener.dart';

class SqliteProjectBodyTextRepository implements ProjectBodyTextRepository {
  SqliteProjectBodyTextRepository({
    SqliteProjectDatabaseOpener? databaseOpener,
    SqliteProjectBodyTextStore? bodyTextStore,
  }) : _databaseOpener = databaseOpener ?? SqliteProjectDatabaseOpener(),
       _bodyTextStore = bodyTextStore ?? SqliteProjectBodyTextStore();

  final SqliteProjectDatabaseOpener _databaseOpener;
  final SqliteProjectBodyTextStore _bodyTextStore;

  @override
  Future<void> deleteDocument({
    required String projectRootPath,
    required String documentId,
  }) async {
    // 中文注释: 删除正文文档时同步清掉分段表，避免正文主表和段表留下孤儿记录。
    final database = _openDatabase(projectRootPath);
    try {
      database.execute('BEGIN');
      _deleteDocumentRows(database, documentId);
      database.execute('COMMIT');
    } catch (_) {
      database.execute('ROLLBACK');
      rethrow;
    } finally {
      database.dispose();
    }
  }

  @override
  Future<SqliteProjectBodyTextDocument?> loadDocument({
    required String projectRootPath,
    required String documentId,
  }) async {
    // 中文注释: 读取正文文档时优先恢复文档主表，再按 ordinal 拼回分段文本，保证 SQLite 真相源可直接回读。
    final database = _openDatabase(projectRootPath);
    try {
      final rows = database.select(
        '''
        SELECT document_id, document_kind, title, storage_format, plain_text,
               markdown_path, state_path, status, created_at, updated_at
        FROM body_text_document
        WHERE document_id = ?
        ''',
        <Object?>[documentId],
      );
      if (rows.isEmpty) {
        return null;
      }
      final row = rows.first;
      return SqliteProjectBodyTextDocument(
        documentId: _text(row['document_id']),
        documentKind: _text(row['document_kind']),
        title: _text(row['title']),
        storageFormat: SqliteProjectBodyTextStorageFormat.fromId(
          _text(row['storage_format']),
        ),
        plainText: _text(row['plain_text']),
        segments: _loadSegments(database, documentId),
        markdownPath: _text(row['markdown_path']),
        statePath: _text(row['state_path']),
        status: _text(row['status']),
        createdAt: _text(row['created_at']),
        updatedAt: _text(row['updated_at']),
      );
    } finally {
      database.dispose();
    }
  }

  @override
  Future<List<SqliteProjectBodyTextDocument>> listDocuments({
    required String projectRootPath,
    String documentKind = '',
  }) async {
    // 中文注释: 列表查询只做文档级摘要，不把 segment 全量塞进结果，避免普通列表接口过重。
    final database = _openDatabase(projectRootPath);
    try {
      final sql = documentKind.trim().isEmpty
          ? '''
        SELECT document_id, document_kind, title, storage_format, plain_text,
               markdown_path, state_path, status, created_at, updated_at
        FROM body_text_document
        ORDER BY created_at, document_id
        '''
          : '''
        SELECT document_id, document_kind, title, storage_format, plain_text,
               markdown_path, state_path, status, created_at, updated_at
        FROM body_text_document
        WHERE document_kind = ?
        ORDER BY created_at, document_id
        ''';
      final rows = documentKind.trim().isEmpty
          ? database.select(sql)
          : database.select(sql, <Object?>[documentKind.trim()]);
      return rows
          .map(
            (row) => SqliteProjectBodyTextDocument(
              documentId: _text(row['document_id']),
              documentKind: _text(row['document_kind']),
              title: _text(row['title']),
              storageFormat: SqliteProjectBodyTextStorageFormat.fromId(
                _text(row['storage_format']),
              ),
              plainText: _text(row['plain_text']),
              segments: _loadSegments(database, _text(row['document_id'])),
              markdownPath: _text(row['markdown_path']),
              statePath: _text(row['state_path']),
              status: _text(row['status']),
              createdAt: _text(row['created_at']),
              updatedAt: _text(row['updated_at']),
            ),
          )
          .toList(growable: false);
    } finally {
      database.dispose();
    }
  }

  @override
  Future<void> saveDocument({
    required String projectRootPath,
    required SqliteProjectBodyTextDocument document,
  }) async {
    // 中文注释: 保存正文文档时先覆盖主表，再重建分段表，避免旧分段残留影响回读结果。
    final database = _openDatabase(projectRootPath);
    try {
      final now = DateTime.now().toIso8601String();
      final existingRows = database.select(
        'SELECT created_at FROM body_text_document WHERE document_id = ?',
        <Object?>[document.documentId],
      );
      final existingCreatedAt = existingRows.isEmpty
          ? ''
          : _text(existingRows.first['created_at']);
      final createdAt = document.createdAt.trim().isNotEmpty
          ? document.createdAt.trim()
          : existingCreatedAt.isNotEmpty
          ? existingCreatedAt
          : now;
      final updatedAt = document.updatedAt.trim().isNotEmpty
          ? document.updatedAt.trim()
          : now;
      database.execute('BEGIN');
      _deleteDocumentRows(database, document.documentId);
      database.execute(
        '''
        INSERT INTO body_text_document (
          document_id, document_kind, title, storage_format, plain_text,
          markdown_path, state_path, status, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        <Object?>[
          document.documentId.trim(),
          document.documentKind.trim(),
          document.title.trim(),
          document.storageFormat.id,
          document.plainText,
          document.markdownPath.trim(),
          document.statePath.trim(),
          document.status.trim(),
          createdAt,
          updatedAt,
        ],
      );
      for (final segment in document.segments) {
        database.execute(
          '''
          INSERT INTO body_text_segment (
            document_id, segment_id, ordinal_index, segment_kind, text_value,
            char_count, created_at, updated_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          <Object?>[
            document.documentId.trim(),
            segment.segmentId.trim(),
            segment.ordinal,
            segment.segmentKind.trim(),
            segment.text,
            segment.text.runes.length,
            createdAt,
            updatedAt,
          ],
        );
      }
      database.execute('COMMIT');
    } catch (_) {
      database.execute('ROLLBACK');
      rethrow;
    } finally {
      database.dispose();
    }
  }

  Database _openDatabase(String projectRootPath) {
    // 中文注释: 数据库打开统一经过同一个 opener，避免各个仓储自己拼 SQLite 路径。
    final database = _databaseOpener.open(projectRootPath);
    _bodyTextStore.ensureSchema(database);
    return database;
  }

  List<SqliteProjectBodyTextSegment> _loadSegments(
    Database database,
    String documentId,
  ) {
    // 中文注释: 分段内容按 ordinal 重新排序后返回，保证 segmented 正文的回读顺序稳定。
    final rows = database.select(
      '''
      SELECT segment_id, ordinal_index, segment_kind, text_value
      FROM body_text_segment
      WHERE document_id = ?
      ORDER BY ordinal_index, segment_id
      ''',
      <Object?>[documentId],
    );
    return rows
        .map(
          (row) => SqliteProjectBodyTextSegment(
            segmentId: _text(row['segment_id']),
            ordinal: _int(row['ordinal_index']),
            segmentKind: _text(row['segment_kind']),
            text: _text(row['text_value']),
          ),
        )
        .toList(growable: false);
  }

  void _deleteDocumentRows(Database database, String documentId) {
    // 中文注释: 主表和分段表必须一起清理，避免正文更新后出现旧段残留。
    database.execute(
      'DELETE FROM body_text_segment WHERE document_id = ?',
      <Object?>[documentId],
    );
    database.execute(
      'DELETE FROM body_text_document WHERE document_id = ?',
      <Object?>[documentId],
    );
  }

  String _text(Object? value) {
    // 中文注释: SQLite 查询值统一转成字符串，避免返回层再处理类型细节。
    return value?.toString() ?? '';
  }

  int _int(Object? value) {
    // 中文注释: ordinal_index 只需要稳定整数，不必把数据库数值类型透传给上层。
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
