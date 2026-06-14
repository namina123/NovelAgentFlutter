import 'sqlite_project_body_text_document.dart';

abstract class ProjectBodyTextRepository {
  Future<SqliteProjectBodyTextDocument?> loadDocument({
    required String projectRootPath,
    required String documentId,
  });

  Future<List<SqliteProjectBodyTextDocument>> listDocuments({
    required String projectRootPath,
    String documentKind = '',
  });

  Future<void> saveDocument({
    required String projectRootPath,
    required SqliteProjectBodyTextDocument document,
  });

  Future<void> deleteDocument({
    required String projectRootPath,
    required String documentId,
  });
}
