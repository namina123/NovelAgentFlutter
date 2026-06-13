import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import 'reference_substrate_path_service.dart';

class ReferenceSubstrateDatabaseOpener {
  ReferenceSubstrateDatabaseOpener({ReferenceSubstratePathService? pathService})
    : _pathService = pathService ?? const ReferenceSubstratePathService();

  final ReferenceSubstratePathService _pathService;

  Database open(String substrateRootPath) {
    final dbPath = _pathService.databasePath(substrateRootPath);
    final dbFile = File(dbPath);
    dbFile.parent.createSync(recursive: true);
    _migrateLegacyDatabaseIfNeeded(
      targetFile: dbFile,
      legacyFile: File(_pathService.legacyDatabasePath(substrateRootPath)),
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
