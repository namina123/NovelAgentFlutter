import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import 'project_sqlite_path_service.dart';

class SqliteProjectDatabaseOpener {
  SqliteProjectDatabaseOpener({ProjectSqlitePathService? sqlitePathService})
    : _sqlitePathService = sqlitePathService ?? ProjectSqlitePathService();

  final ProjectSqlitePathService _sqlitePathService;

  Database open(String rootPath) {
    // 中文注释: SQLite 数据库打开与父目录准备集中在这里，避免每个 store 都自己拼路径和补目录。
    final dbPath = _sqlitePathService.databasePath(rootPath);
    final dbFile = File(dbPath);
    dbFile.parent.createSync(recursive: true);
    return sqlite3.open(dbPath);
  }
}
