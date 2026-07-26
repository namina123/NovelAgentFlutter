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

  Future<void> persistSourceOriginalArchive({
    required ProjectDescriptor project,
    required String archivePath,
    required String archiveTitle,
    required String sourceContent,
    String statePath = '',
  }) async {
    // 中文注释: 原文归档在 SQLite 项目里也要进入主事实源，文件层只保留可读投影与兼容入口。
    if (!_writePolicy.shouldWriteToSqlitePrimarySource(
      storageStrategy: project.storageStrategy,
      documentKind: 'source_original',
    )) {
      return;
    }
    final document = SqliteProjectBodyTextDocument(
      documentId: archivePath.trim(),
      documentKind: 'source_original',
      title: archiveTitle.trim().isEmpty
          ? archivePath.trim()
          : archiveTitle.trim(),
      storageFormat: SqliteProjectBodyTextStorageFormat.plainText,
      plainText: sourceContent,
      markdownPath: archivePath.trim(),
      statePath: statePath.trim(),
      status: 'archived',
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );
    await _bodyTextRepository.saveDocument(
      projectRootPath: project.rootPath,
      document: document,
    );
  }

  Future<void> persistStructuredDocument({
    required ProjectDescriptor project,
    required String documentPath,
    required String documentKind,
    required String title,
    required String content,
    String statePath = '',
    String status = 'applied',
  }) async {
    // 中文注释: 拆书确认物化的章纲和资产在 SQLite 项目也必须进入主事实源；
    // imports/ 下的 Markdown 只是供工作区和兼容读取使用的投影。
    final cleanPath = documentPath.trim();
    final cleanKind = documentKind.trim();
    if (cleanPath.isEmpty || cleanKind.isEmpty) {
      return;
    }
    if (!_writePolicy.shouldWriteToSqlitePrimarySource(
      storageStrategy: project.storageStrategy,
      documentKind: cleanKind,
    )) {
      return;
    }
    final document = SqliteProjectBodyTextDocument(
      documentId: cleanPath,
      documentKind: cleanKind,
      title: title.trim().isEmpty ? cleanPath : title.trim(),
      storageFormat: SqliteProjectBodyTextStorageFormat.plainText,
      plainText: content,
      markdownPath: cleanPath,
      statePath: statePath.trim(),
      status: status.trim().isEmpty ? 'applied' : status.trim(),
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );
    await _bodyTextRepository.saveDocument(
      projectRootPath: project.rootPath,
      document: document,
    );
  }

  Future<void> deleteStructuredDocument({
    required ProjectDescriptor project,
    required String documentPath,
    required String documentKind,
  }) async {
    // 中文注释: 删除 SQLite 投影时同步删除主事实源，避免文件树已消失而正文表仍残留孤儿文档。
    final cleanPath = documentPath.trim();
    if (cleanPath.isEmpty ||
        project.storageStrategy != ProjectStorageStrategy.sqliteProjectStore) {
      return;
    }
    final existing = await _bodyTextRepository.loadDocument(
      projectRootPath: project.rootPath,
      documentId: cleanPath,
    );
    if (existing == null &&
        !_writePolicy.shouldWriteToSqlitePrimarySource(
          storageStrategy: project.storageStrategy,
          documentKind: documentKind,
        )) {
      return;
    }
    await _bodyTextRepository.deleteDocument(
      projectRootPath: project.rootPath,
      documentId: cleanPath,
    );
  }

  Future<SqliteProjectBodyTextDocument?> loadStructuredDocument({
    required ProjectDescriptor project,
    required String documentPath,
  }) {
    if (project.storageStrategy != ProjectStorageStrategy.sqliteProjectStore ||
        documentPath.trim().isEmpty) {
      return Future<SqliteProjectBodyTextDocument?>.value();
    }
    return _bodyTextRepository.loadDocument(
      projectRootPath: project.rootPath,
      documentId: documentPath.trim(),
    );
  }

  Future<List<SqliteProjectBodyTextDocument>> listStructuredDocuments({
    required ProjectDescriptor project,
    String documentKind = '',
  }) {
    if (project.storageStrategy != ProjectStorageStrategy.sqliteProjectStore) {
      return Future<List<SqliteProjectBodyTextDocument>>.value(
        const <SqliteProjectBodyTextDocument>[],
      );
    }
    return _bodyTextRepository.listDocuments(
      projectRootPath: project.rootPath,
      documentKind: documentKind.trim(),
    );
  }

  Future<void> moveStructuredDocument({
    required ProjectDescriptor project,
    required String sourcePath,
    required String targetPath,
    required String targetDocumentKind,
  }) async {
    final cleanSourcePath = sourcePath.trim();
    final cleanTargetPath = targetPath.trim();
    if (cleanSourcePath.isEmpty ||
        cleanTargetPath.isEmpty ||
        cleanSourcePath == cleanTargetPath) {
      return;
    }
    final source = await loadStructuredDocument(
      project: project,
      documentPath: cleanSourcePath,
    );
    if (source == null) {
      return;
    }
    final cleanTargetKind = targetDocumentKind.trim();
    final target = await loadStructuredDocument(
      project: project,
      documentPath: cleanTargetPath,
    );
    final shouldPersistAtTarget = _writePolicy.shouldWriteToSqlitePrimarySource(
      storageStrategy: project.storageStrategy,
      documentKind: cleanTargetKind,
    );
    try {
      if (shouldPersistAtTarget) {
        final now = DateTime.now().toIso8601String();
        await _bodyTextRepository.saveDocument(
          projectRootPath: project.rootPath,
          document: SqliteProjectBodyTextDocument(
            documentId: cleanTargetPath,
            documentKind: cleanTargetKind,
            title: source.title,
            storageFormat: source.storageFormat,
            plainText: source.plainText,
            segments: source.segments,
            markdownPath: cleanTargetPath,
            statePath: source.statePath,
            status: source.status,
            createdAt: source.createdAt,
            updatedAt: now,
          ),
        );
      } else if (target != null) {
        // The file is leaving the SQLite-backed projection surface. Remove a
        // stale target row rather than retaining a document with no projection.
        await _bodyTextRepository.deleteDocument(
          projectRootPath: project.rootPath,
          documentId: cleanTargetPath,
        );
      }
      await _bodyTextRepository.deleteDocument(
        projectRootPath: project.rootPath,
        documentId: cleanSourcePath,
      );
    } catch (error, stackTrace) {
      // SQLite has no transaction with the filesystem. Keep this leg atomic so
      // callers can safely compensate the projection mutation independently.
      try {
        await _restoreDocumentSnapshot(
          project: project,
          documentPath: cleanSourcePath,
          snapshot: source,
        );
      } catch (_) {}
      try {
        await _restoreDocumentSnapshot(
          project: project,
          documentPath: cleanTargetPath,
          snapshot: target,
        );
      } catch (_) {}
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> restoreStructuredDocument({
    required ProjectDescriptor project,
    required String documentPath,
    required SqliteProjectBodyTextDocument? snapshot,
  }) {
    return _restoreDocumentSnapshot(
      project: project,
      documentPath: documentPath,
      snapshot: snapshot,
    );
  }

  Future<void> persistWorkspaceProjectionDocument({
    required ProjectDescriptor project,
    required String documentPath,
    required String inferredDocumentKind,
    required String title,
    required String content,
  }) async {
    // 中文注释: 通用文件出口写回 SQLite 投影时保留已有领域元数据；章节交付、拆书确认等
    // 上层已写入的 state_path/status 不能被一次兼容层编辑覆盖为默认值。
    final cleanPath = documentPath.trim();
    final cleanKind = inferredDocumentKind.trim();
    if (cleanPath.isEmpty ||
        cleanKind.isEmpty ||
        !_writePolicy.shouldWriteToSqlitePrimarySource(
          storageStrategy: project.storageStrategy,
          documentKind: cleanKind,
        )) {
      return;
    }
    final existing = await _bodyTextRepository.loadDocument(
      projectRootPath: project.rootPath,
      documentId: cleanPath,
    );
    await _bodyTextRepository.saveDocument(
      projectRootPath: project.rootPath,
      document: SqliteProjectBodyTextDocument(
        documentId: cleanPath,
        documentKind: existing?.documentKind.trim().isNotEmpty == true
            ? existing!.documentKind
            : cleanKind,
        title: existing?.title.trim().isNotEmpty == true
            ? existing!.title
            : title.trim().isEmpty
            ? cleanPath
            : title.trim(),
        storageFormat: SqliteProjectBodyTextStorageFormat.plainText,
        plainText: content,
        markdownPath: cleanPath,
        statePath: existing?.statePath ?? '',
        status: existing?.status.trim().isNotEmpty == true
            ? existing!.status
            : 'applied',
        createdAt: existing?.createdAt ?? '',
        updatedAt: DateTime.now().toIso8601String(),
      ),
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

  Future<void> _restoreDocumentSnapshot({
    required ProjectDescriptor project,
    required String documentPath,
    required SqliteProjectBodyTextDocument? snapshot,
  }) async {
    final cleanPath = documentPath.trim();
    if (cleanPath.isEmpty ||
        project.storageStrategy != ProjectStorageStrategy.sqliteProjectStore) {
      return;
    }
    if (snapshot == null) {
      await _bodyTextRepository.deleteDocument(
        projectRootPath: project.rootPath,
        documentId: cleanPath,
      );
      return;
    }
    await _bodyTextRepository.saveDocument(
      projectRootPath: project.rootPath,
      document: snapshot,
    );
  }
}
