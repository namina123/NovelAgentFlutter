import 'package:sqlite3/sqlite3.dart';

class ProjectReferenceAttachmentDatabaseMigrator {
  static const String schemaVersion = '1';

  const ProjectReferenceAttachmentDatabaseMigrator();

  void migrate(Database database) {
    database.execute('PRAGMA foreign_keys = ON;');
    database.execute('''
      CREATE TABLE IF NOT EXISTS project_reference_attachment_meta (
        meta_key TEXT PRIMARY KEY,
        value_text TEXT NOT NULL
      );
      ''');
    database.execute('''
      CREATE TABLE IF NOT EXISTS project_reference_attachment (
        attachment_id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        package_id TEXT NOT NULL,
        package_version_id TEXT NOT NULL,
        visibility_mode TEXT NOT NULL,
        access_level TEXT NOT NULL,
        display_label TEXT NOT NULL,
        allows_discovery_expansion INTEGER NOT NULL,
        allows_projection INTEGER NOT NULL,
        allows_promotion INTEGER NOT NULL,
        requires_confirmation INTEGER NOT NULL,
        attached_at TEXT NOT NULL,
        metadata_json TEXT NOT NULL
      );
      ''');
    database.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_project_reference_attachment_package
      ON project_reference_attachment(package_id);
      ''');
    database.execute(
      '''
      INSERT OR REPLACE INTO project_reference_attachment_meta(meta_key, value_text)
      VALUES ('schema_version', ?);
      ''',
      <Object?>[schemaVersion],
    );
  }
}
