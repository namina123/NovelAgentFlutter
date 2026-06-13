class ProjectReferenceAttachmentSqlitePathService {
  const ProjectReferenceAttachmentSqlitePathService();

  static const String databaseRelativePath = '.na/ra.db';
  static const String legacyDatabaseRelativePath =
      '.novel_agent/reference_attachments/reference_attachments.db';

  String databasePath(String rootPath) {
    return '$rootPath/$databaseRelativePath';
  }

  String legacyDatabasePath(String rootPath) {
    return '$rootPath/$legacyDatabaseRelativePath';
  }
}
