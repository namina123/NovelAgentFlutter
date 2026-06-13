import 'dart:convert';

import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:sqlite3/sqlite3.dart';

import 'sqlite_project_database_opener.dart';

class SqliteProjectInformationRecordStore {
  SqliteProjectInformationRecordStore({
    SqliteProjectDatabaseOpener? databaseOpener,
  }) : _databaseOpener = databaseOpener ?? SqliteProjectDatabaseOpener();

  static const String _tableName = 'project_information_record';

  final SqliteProjectDatabaseOpener _databaseOpener;

  Future<void> upsertRecord({
    required ProjectDescriptor project,
    required String recordType,
    required String recordId,
    required String filterKey,
    required JsonMap payload,
  }) async {
    final database = _databaseOpener.open(project.rootPath);
    try {
      _ensureSchema(database);
      database.execute('BEGIN');
      database.execute(
        '''
        INSERT INTO $_tableName (
          project_id,
          record_type,
          record_id,
          filter_key,
          payload_json
        ) VALUES (?, ?, ?, ?, ?)
        ON CONFLICT(project_id, record_type, record_id) DO UPDATE SET
          filter_key = excluded.filter_key,
          payload_json = excluded.payload_json
        ''',
        <Object?>[
          project.id,
          recordType,
          recordId,
          filterKey,
          jsonEncode(payload),
        ],
      );
      database.execute('COMMIT');
    } catch (_) {
      database.execute('ROLLBACK');
      rethrow;
    } finally {
      database.dispose();
    }
  }

  Future<JsonMap?> readRecord({
    required ProjectDescriptor project,
    required String recordType,
    required String recordId,
  }) async {
    final database = _databaseOpener.open(project.rootPath);
    try {
      _ensureSchema(database);
      final rows = database.select(
        '''
        SELECT payload_json
        FROM $_tableName
        WHERE project_id = ? AND record_type = ? AND record_id = ?
        ''',
        <Object?>[project.id, recordType, recordId],
      );
      if (rows.isEmpty) {
        return null;
      }
      return _decodeJsonMap(rows.first['payload_json']);
    } finally {
      database.dispose();
    }
  }

  Future<List<JsonMap>> listRecords({
    required ProjectDescriptor project,
    required String recordType,
    String? filterKey,
  }) async {
    final database = _databaseOpener.open(project.rootPath);
    try {
      _ensureSchema(database);
      final statement = StringBuffer()
        ..writeln('SELECT payload_json')
        ..writeln('FROM $_tableName')
        ..write('WHERE project_id = ? AND record_type = ?');
      final parameters = <Object?>[project.id, recordType];
      if (filterKey != null) {
        statement.write(' AND filter_key = ?');
        parameters.add(filterKey);
      }
      statement.write(' ORDER BY filter_key, record_id');
      final rows = database.select(statement.toString(), parameters);
      return rows
          .map((row) => _decodeJsonMap(row['payload_json']))
          .toList(growable: false);
    } finally {
      database.dispose();
    }
  }

  void _ensureSchema(Database database) {
    database.execute('''
      CREATE TABLE IF NOT EXISTS $_tableName (
        project_id TEXT NOT NULL,
        record_type TEXT NOT NULL,
        record_id TEXT NOT NULL,
        filter_key TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        PRIMARY KEY (project_id, record_type, record_id)
      )
      ''');
    database.execute('''
      CREATE INDEX IF NOT EXISTS idx_project_information_record_filter
      ON $_tableName (project_id, record_type, filter_key, record_id)
      ''');
  }

  JsonMap _decodeJsonMap(Object? rawValue) {
    if (rawValue is! String || rawValue.isEmpty) {
      return <String, Object?>{};
    }
    final decoded = jsonDecode(rawValue);
    if (decoded is! Map) {
      return <String, Object?>{};
    }
    return decoded.map<String, Object?>(
      (key, value) => MapEntry(key.toString(), value),
    );
  }
}
