import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import 'project_reference_attachment_sqlite_path_service.dart';

class ProjectReferenceAttachmentDatabaseOpener {
  static const int _windowsExtendedPathThreshold = 240;

  ProjectReferenceAttachmentDatabaseOpener({
    ProjectReferenceAttachmentSqlitePathService? pathService,
  }) : _pathService =
           pathService ?? const ProjectReferenceAttachmentSqlitePathService();

  final ProjectReferenceAttachmentSqlitePathService _pathService;

  Database open(String rootPath) {
    final dbPath = _sqliteOpenPath(_pathService.databasePath(rootPath));
    final dbFile = File(dbPath);
    dbFile.parent.createSync(recursive: true);
    _migrateLegacyDatabaseIfNeeded(
      targetFile: dbFile,
      legacyFile: File(
        _sqliteOpenPath(_pathService.legacyDatabasePath(rootPath)),
      ),
    );
    return sqlite3.open(dbPath);
  }

  String _sqliteOpenPath(String databasePath) {
    if (!Platform.isWindows) {
      return databasePath;
    }
    final absolutePath = File(databasePath).absolute.path;
    if (absolutePath.startsWith('\\\\?\\') ||
        absolutePath.length < _windowsExtendedPathThreshold) {
      return absolutePath;
    }
    // SQLite creates journal sidecars during the first schema write. The
    // shortened project-relative path can still exceed Win32's legacy limit
    // once those suffixes are added, so use the extended path for the handle.
    if (absolutePath.startsWith('\\\\')) {
      return '\\\\?\\UNC\\${absolutePath.substring(2)}';
    }
    return '\\\\?\\$absolutePath';
  }

  void _migrateLegacyDatabaseIfNeeded({
    required File targetFile,
    required File legacyFile,
  }) {
    if (targetFile.existsSync() || !legacyFile.existsSync()) {
      return;
    }
    try {
      legacyFile.renameSync(targetFile.path);
      return;
    } on FileSystemException {
      legacyFile.copySync(targetFile.path);
    }
  }
}
