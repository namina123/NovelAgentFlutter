import 'dart:convert';

import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:sqlite3/sqlite3.dart';

import 'project_reference_attachment_database_migrator.dart';
import 'project_reference_attachment_database_opener.dart';

class SqliteProjectReferenceAttachmentLayer
    implements ProjectReferenceAttachmentLayer {
  SqliteProjectReferenceAttachmentLayer({
    ProjectReferenceAttachmentDatabaseOpener? databaseOpener,
    ProjectReferenceAttachmentDatabaseMigrator? migrator,
  }) : _databaseOpener =
           databaseOpener ?? ProjectReferenceAttachmentDatabaseOpener(),
       _migrator =
           migrator ?? const ProjectReferenceAttachmentDatabaseMigrator();

  final ProjectReferenceAttachmentDatabaseOpener _databaseOpener;
  final ProjectReferenceAttachmentDatabaseMigrator _migrator;

  @override
  Future<List<ProjectReferenceAttachment>> listAttachments(
    ProjectDescriptor project, {
    String? visibilityMode,
  }) async {
    final database = _open(project.rootPath);
    try {
      final rows = visibilityMode == null
          ? database.select('''
              SELECT *
              FROM project_reference_attachment
              ORDER BY package_id
              ''')
          : database.select(
              '''
              SELECT *
              FROM project_reference_attachment
              WHERE visibility_mode = ?
              ORDER BY package_id
              ''',
              <Object?>[visibilityMode],
            );
      return rows.map(_mapAttachment).toList(growable: false);
    } finally {
      database.dispose();
    }
  }

  @override
  Future<ProjectReferenceAttachment?> readAttachment(
    ProjectDescriptor project, {
    required String packageId,
  }) async {
    final database = _open(project.rootPath);
    try {
      final rows = database.select(
        '''
        SELECT *
        FROM project_reference_attachment
        WHERE package_id = ?
        LIMIT 1
        ''',
        <Object?>[packageId],
      );
      if (rows.isEmpty) {
        return null;
      }
      return _mapAttachment(rows.first);
    } finally {
      database.dispose();
    }
  }

  @override
  Future<void> upsertAttachment(
    ProjectDescriptor project,
    ProjectReferenceAttachment attachment,
  ) async {
    final database = _open(project.rootPath);
    try {
      database.execute(
        '''
        INSERT OR REPLACE INTO project_reference_attachment (
          attachment_id,
          project_id,
          package_id,
          package_version_id,
          visibility_mode,
          access_level,
          display_label,
          allows_discovery_expansion,
          allows_projection,
          allows_promotion,
          requires_confirmation,
          attached_at,
          metadata_json
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        <Object?>[
          attachment.attachmentId,
          attachment.projectId,
          attachment.packageId,
          attachment.packageVersionId,
          attachment.visibilityMode,
          attachment.accessLevel,
          attachment.displayLabel,
          attachment.allowsDiscoveryExpansion ? 1 : 0,
          attachment.allowsProjection ? 1 : 0,
          attachment.allowsPromotion ? 1 : 0,
          attachment.requiresConfirmation ? 1 : 0,
          attachment.attachedAt,
          jsonEncode(attachment.metadata),
        ],
      );
    } finally {
      database.dispose();
    }
  }

  Database _open(String rootPath) {
    final database = _databaseOpener.open(rootPath);
    _migrator.migrate(database);
    return database;
  }

  ProjectReferenceAttachment _mapAttachment(Row row) {
    return ProjectReferenceAttachment.fromJson(<String, Object?>{
      'attachment_id': row['attachment_id'],
      'project_id': row['project_id'],
      'package_id': row['package_id'],
      'package_version_id': row['package_version_id'],
      'visibility_mode': row['visibility_mode'],
      'access_level': row['access_level'],
      'display_label': row['display_label'],
      'allows_discovery_expansion':
          (row['allows_discovery_expansion'] as int? ?? 0) == 1,
      'allows_projection': (row['allows_projection'] as int? ?? 0) == 1,
      'allows_promotion': (row['allows_promotion'] as int? ?? 0) == 1,
      'requires_confirmation': (row['requires_confirmation'] as int? ?? 0) == 1,
      'attached_at': row['attached_at'],
      'metadata': ValueReaders.mapValue(
        jsonDecode(row['metadata_json']?.toString() ?? '{}'),
      ),
    });
  }
}
