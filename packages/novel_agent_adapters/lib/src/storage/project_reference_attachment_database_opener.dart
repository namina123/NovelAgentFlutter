import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import 'project_reference_attachment_sqlite_path_service.dart';

class ProjectReferenceAttachmentDatabaseOpener {
  ProjectReferenceAttachmentDatabaseOpener({
    ProjectReferenceAttachmentSqlitePathService? pathService,
  }) : _pathService =
           pathService ?? const ProjectReferenceAttachmentSqlitePathService();

  final ProjectReferenceAttachmentSqlitePathService _pathService;

  Database open(String rootPath) {
    final dbPath = _pathService.databasePath(rootPath);
    final dbFile = File(dbPath);
    dbFile.parent.createSync(recursive: true);
    _migrateLegacyDatabaseIfNeeded(
      targetFile: dbFile,
      legacyFile: File(_pathService.legacyDatabasePath(rootPath)),
    );
    return sqlite3.open(dbPath);
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
