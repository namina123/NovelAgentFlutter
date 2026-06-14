import 'package:novel_agent_core/src/project/project_body_text_repository.dart';
import 'package:novel_agent_core/src/project/project_content_storage_disposition.dart';
import 'package:novel_agent_core/src/project/project_descriptor.dart';
import 'package:novel_agent_core/src/project/project_storage_aware_workspace_policy.dart';
import 'package:novel_agent_core/src/project/project_storage_strategy.dart';
import 'package:novel_agent_core/src/project/project_structured_content_write_policy.dart';
import 'package:novel_agent_core/src/project/sqlite_project_body_text_document.dart';
import 'package:novel_agent_core/src/project/sqlite_project_body_text_storage_format.dart';

import 'sqlite_project_body_text_repository.dart';

class ProjectStructuredContentBridgeService {
  ProjectStructuredContentBridgeService({
    ProjectBodyTextRepository? bodyTextRepository,
    ProjectStorageAwareWorkspacePolicy? workspacePolicy,
    ProjectStructuredContentWritePolicy? writePolicy,
  }) : _bodyTextRepository =
           bodyTextRepository ?? SqliteProjectBodyTextRepository(),
       _workspacePolicy =
           workspacePolicy ?? const ProjectStorageAwareWorkspacePolicy(),
       _writePolicy =
           writePolicy ?? const ProjectStructuredContentWritePolicy();

  final ProjectBodyTextRepository _bodyTextRepository;
  final ProjectStorageAwareWorkspacePolicy _workspacePolicy;
  final ProjectStructuredContentWritePolicy _writePolicy;

  Future<void> persistChapterDelivery({
    required ProjectDescriptor project,
    required String chapterPath,
    required String chapterTitle,
    required String chapterContent,
    required String recordPath,
    required String status,
  }) async {
    // 中文注释: 章节正式交付时，SQLite 项目要把正文同时写入数据库主事实源，文件层只保留投影。
    if (!_writePolicy.shouldWriteToSqlitePrimarySource(
      storageStrategy: project.storageStrategy,
      documentKind: 'chapter',
    )) {
      return;
    }
    final document = SqliteProjectBodyTextDocument(
      documentId: chapterPath,
      documentKind: 'chapter',
      title: chapterTitle.trim().isEmpty ? chapterPath : chapterTitle.trim(),
      storageFormat: SqliteProjectBodyTextStorageFormat.plainText,
      plainText: chapterContent,
      markdownPath: chapterPath,
      statePath: recordPath,
      status: status,
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );
    await _bodyTextRepository.saveDocument(
      projectRootPath: project.rootPath,
      document: document,
    );
  }

  Future<String?> readProjectedBodyText(
    ProjectDescriptor project,
    String relativePath,
  ) async {
    // 中文注释: 读取时优先尝试 SQLite 主事实源，文件层只是兼容投影和旧项目回退。
    if (project.storageStrategy != ProjectStorageStrategy.sqliteProjectStore) {
      return null;
    }
    final disposition = _workspacePolicy.dispositionOfWorkspacePath(
      storageStrategy: project.storageStrategy,
      relativePath: relativePath,
    );
    if (disposition != ProjectContentStorageDisposition.filesystemProjection &&
        disposition !=
            ProjectContentStorageDisposition.filesystemCompatibilityMirror) {
      return null;
    }
    final document = await _bodyTextRepository.loadDocument(
      projectRootPath: project.rootPath,
      documentId: relativePath.trim(),
    );
    if (document == null) {
      return null;
    }
    return document.combinedText();
  }
}
