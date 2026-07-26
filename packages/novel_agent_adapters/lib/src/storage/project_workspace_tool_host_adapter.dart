import 'dart:async';

import 'package:novel_agent_core/novel_agent_core.dart';

import 'local_project_file_mutation_adapter.dart';
import 'project_structured_content_bridge_service.dart';
import 'project_structured_content_synchronization_host_port.dart';

class ProjectWorkspaceToolHostAdapter
    implements
        ProjectToolHostPort,
        ProjectStructuredContentSynchronizationHostPort {
  ProjectWorkspaceToolHostAdapter({
    required ProjectWorkspacePort workspacePort,
    required LocalProjectFileMutationAdapter fileMutationAdapter,
    ProjectStructuredContentBridgeService? structuredContentBridgeService,
    ProjectManifestCodecService? projectManifestCodecService,
    ProjectContentPathPolicyService? projectContentPathPolicyService,
  }) : _workspacePort = workspacePort,
       _fileMutationAdapter = fileMutationAdapter,
       _structuredContentBridgeService =
           structuredContentBridgeService ??
           ProjectStructuredContentBridgeService(),
       _projectManifestCodecService =
           projectManifestCodecService ?? ProjectManifestCodecService(),
       _projectContentPathPolicyService =
           projectContentPathPolicyService ??
           const ProjectContentPathPolicyService();

  final ProjectWorkspacePort _workspacePort;
  final LocalProjectFileMutationAdapter _fileMutationAdapter;
  final ProjectStructuredContentBridgeService _structuredContentBridgeService;
  final ProjectManifestCodecService _projectManifestCodecService;
  final ProjectContentPathPolicyService _projectContentPathPolicyService;
  static final Object _structuredContentSynchronizationZoneKey = Object();

  bool get _isStructuredContentSynchronizationSuppressed {
    return Zone.current[_structuredContentSynchronizationZoneKey] == true;
  }

  @override
  Future<T> runWithoutStructuredContentSynchronization<T>(
    Future<T> Function() operation,
  ) {
    // This is zone-scoped rather than an adapter field so concurrent project
    // operations cannot accidentally suppress each other's synchronization.
    return runZoned<Future<T>>(
      operation,
      zoneValues: <Object?, Object?>{
        _structuredContentSynchronizationZoneKey: true,
      },
    );
  }

  @override
  Future<List<JsonMap>> listEntries(String rootPath, {bool recursive = true}) {
    // 中文注释: 工具宿主适配器复用工作区读取接口，确保 list/read/write 与主工作区口径一致。
    return _workspacePort.listEntries(rootPath, recursive: recursive);
  }

  @override
  Future<String?> readTextFile(String rootPath, String relativePath) {
    // 中文注释: 工具读取直接委托给工作区端口，避免工具链和项目浏览链各用一套读文件规则。
    return _workspacePort.readTextFile(rootPath, relativePath);
  }

  @override
  Future<void> writeTextFile(
    String rootPath,
    String relativePath,
    String content,
  ) async {
    if (_isStructuredContentSynchronizationSuppressed) {
      await _workspacePort.writeTextFile(rootPath, relativePath, content);
      return;
    }
    // 中文注释: Host 适配器是角色、资料包和低层工具共用的文本出口；SQLite 项目先同步结构化主库，
    // 再更新 Markdown 投影，避免各类仓储各自遗漏同一条事实源约束。
    final cleanPath = _cleanRelativePath(relativePath);
    final project = await _loadSqliteProjectForStructuredPaths(
      rootPath: rootPath,
      relativePaths: <String>[cleanPath],
    );
    if (project == null) {
      await _workspacePort.writeTextFile(rootPath, relativePath, content);
      return;
    }
    final structuredSnapshot = await _structuredContentBridgeService
        .loadStructuredDocument(project: project, documentPath: cleanPath);
    final projectionSnapshot = await _captureProjectionSnapshot(
      rootPath: rootPath,
      relativePath: cleanPath,
    );
    var projectionWriteAttempted = false;
    try {
      await _persistStructuredProjection(
        project: project,
        relativePath: cleanPath,
        content: content,
      );
      projectionWriteAttempted = true;
      await _workspacePort.writeTextFile(rootPath, relativePath, content);
    } catch (error, stackTrace) {
      // A workspace write can fail after the SQLite row was saved. Restore the
      // prior snapshots best-effort, but never replace the original failure.
      await _restoreStructuredDocumentSnapshot(
        project: project,
        documentPath: cleanPath,
        snapshot: structuredSnapshot,
      );
      if (projectionWriteAttempted) {
        await _restoreProjectionSnapshot(
          rootPath: rootPath,
          relativePath: cleanPath,
          snapshot: projectionSnapshot,
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> _persistStructuredProjection({
    required ProjectDescriptor project,
    required String relativePath,
    required String content,
  }) async {
    await _structuredContentBridgeService.persistWorkspaceProjectionDocument(
      project: project,
      documentPath: relativePath,
      inferredDocumentKind: _projectContentPathPolicyService
          .inferContentTypeFromPath(relativePath),
      title: relativePath.split('/').last,
      content: content,
    );
  }

  Future<ProjectDescriptor?> _loadSqliteProjectForStructuredPaths({
    required String rootPath,
    required Iterable<String> relativePaths,
  }) async {
    if (!relativePaths.any(_isStructuredContentPath)) {
      return null;
    }
    final manifestContent = await _workspacePort.readTextFile(
      rootPath,
      ProjectManifestCodecService.manifestRelativePath,
    );
    if (manifestContent == null || manifestContent.trim().isEmpty) {
      return null;
    }
    final manifest = _projectManifestCodecService.tryParseStrict(
      manifestContent,
    );
    if (manifest == null) {
      throw ProjectManifestCorruptionException(rootPath: rootPath);
    }
    if (manifest.storageStrategy != ProjectStorageStrategy.sqliteProjectStore) {
      return null;
    }
    return ProjectDescriptor(
      id: rootPath,
      name: manifest.title,
      rootPath: rootPath,
      projectType: manifest.projectType,
      storageStrategy: manifest.storageStrategy,
      projectBranchId: manifest.projectBranchId,
      runtimeBaselineId: manifest.runtimeBaselineId,
      additionalTraitIds: manifest.additionalTraitIds,
    );
  }

  String _cleanRelativePath(String relativePath) {
    return relativePath.trim().replaceAll('\\', '/');
  }

  bool _isStructuredContentPath(String relativePath) {
    if (relativePath.isEmpty) {
      return false;
    }
    switch (relativePath.split('/').first.toLowerCase()) {
      case 'premise':
      case 'chapters':
      case 'scenes':
      case 'outlines':
      case 'assets':
      case 'knowledge':
      case 'research':
      case 'sources':
      case 'summaries':
      case 'world':
      case 'characters':
      case 'styles':
      case 'imports':
        return true;
      default:
        return false;
    }
  }

  @override
  Future<bool> entryExists(String rootPath, String relativePath) {
    // 中文注释: 会改变文件系统状态的辅助判断交给更细的变更适配器，防止工作区端口继续变重。
    return _fileMutationAdapter.entryExists(rootPath, relativePath);
  }

  @override
  Future<void> createDirectory(String rootPath, String relativePath) {
    // 中文注释: 创建目录属于变更职责，因此由文件变更适配器承接。
    return _fileMutationAdapter.createDirectory(rootPath, relativePath);
  }

  @override
  Future<void> deleteEntry(String rootPath, String relativePath) async {
    if (_isStructuredContentSynchronizationSuppressed) {
      await _fileMutationAdapter.deleteEntry(rootPath, relativePath);
      return;
    }
    final cleanPath = _cleanRelativePath(relativePath);
    final project = await _loadSqliteProjectForStructuredPaths(
      rootPath: rootPath,
      relativePaths: <String>[cleanPath],
    );
    if (project == null) {
      await _fileMutationAdapter.deleteEntry(rootPath, relativePath);
      return;
    }
    final snapshots = await _loadStructuredDocumentsInScope(
      project: project,
      relativePath: cleanPath,
    );
    if (snapshots.isEmpty) {
      await _fileMutationAdapter.deleteEntry(rootPath, relativePath);
      return;
    }
    final projectionSnapshots = await _captureProjectionSnapshots(
      rootPath: rootPath,
      documentPaths: snapshots.keys,
    );
    var projectionDeleteAttempted = false;
    try {
      for (final entry in snapshots.entries) {
        await _structuredContentBridgeService.deleteStructuredDocument(
          project: project,
          documentPath: entry.key,
          documentKind: entry.value.documentKind,
        );
      }
      projectionDeleteAttempted = true;
      await _fileMutationAdapter.deleteEntry(rootPath, relativePath);
    } catch (error, stackTrace) {
      // SQLite and Markdown use separate transaction managers. Restore both
      // sides best-effort and retain the operation error for callers.
      await _restoreStructuredDocumentSnapshots(
        project: project,
        snapshots: snapshots,
      );
      if (projectionDeleteAttempted) {
        await _restoreProjectionSnapshots(
          rootPath: rootPath,
          snapshots: projectionSnapshots,
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  Future<void> moveEntry(
    String rootPath,
    String sourceRelativePath,
    String targetRelativePath,
  ) async {
    if (_isStructuredContentSynchronizationSuppressed) {
      await _fileMutationAdapter.moveEntry(
        rootPath,
        sourceRelativePath,
        targetRelativePath,
      );
      return;
    }
    final cleanSourcePath = _cleanRelativePath(sourceRelativePath);
    final cleanTargetPath = _cleanRelativePath(targetRelativePath);
    if (cleanSourcePath.isEmpty || cleanTargetPath.isEmpty) {
      await _fileMutationAdapter.moveEntry(
        rootPath,
        sourceRelativePath,
        targetRelativePath,
      );
      return;
    }
    final project = await _loadSqliteProjectForStructuredPaths(
      rootPath: rootPath,
      relativePaths: <String>[cleanSourcePath, cleanTargetPath],
    );
    if (project == null ||
        !await _fileMutationAdapter.entryExists(rootPath, sourceRelativePath)) {
      await _fileMutationAdapter.moveEntry(
        rootPath,
        sourceRelativePath,
        targetRelativePath,
      );
      return;
    }
    final sourceSnapshots = await _loadStructuredDocumentsInScope(
      project: project,
      relativePath: cleanSourcePath,
    );
    if (sourceSnapshots.isEmpty) {
      await _fileMutationAdapter.moveEntry(
        rootPath,
        sourceRelativePath,
        targetRelativePath,
      );
      return;
    }
    final sourceToTargetPaths = <String, String>{
      for (final sourcePath in sourceSnapshots.keys)
        sourcePath: _targetPathForSourceDocument(
          sourcePath: sourcePath,
          sourceScopePath: cleanSourcePath,
          targetScopePath: cleanTargetPath,
        ),
    };
    final targetSnapshots = <String, SqliteProjectBodyTextDocument?>{
      for (final targetPath in sourceToTargetPaths.values)
        targetPath: await _structuredContentBridgeService
            .loadStructuredDocument(project: project, documentPath: targetPath),
    };
    final sourceProjectionSnapshots = await _captureProjectionSnapshots(
      rootPath: rootPath,
      documentPaths: sourceSnapshots.keys,
    );
    final targetProjectionSnapshots = await _captureProjectionSnapshots(
      rootPath: rootPath,
      documentPaths: targetSnapshots.keys,
    );
    var projectionMoveAttempted = false;
    try {
      for (final entry in sourceSnapshots.entries) {
        final targetPath = sourceToTargetPaths[entry.key]!;
        await _structuredContentBridgeService.moveStructuredDocument(
          project: project,
          sourcePath: entry.key,
          targetPath: targetPath,
          targetDocumentKind: _projectContentPathPolicyService
              .inferContentTypeFromPath(targetPath),
        );
      }
      projectionMoveAttempted = true;
      await _fileMutationAdapter.moveEntry(
        rootPath,
        sourceRelativePath,
        targetRelativePath,
      );
    } catch (error, stackTrace) {
      await _restoreStructuredDocumentSnapshots(
        project: project,
        snapshots: sourceSnapshots,
      );
      await _restoreStructuredDocumentSnapshots(
        project: project,
        snapshots: targetSnapshots,
      );
      if (projectionMoveAttempted) {
        await _restoreProjectionSnapshots(
          rootPath: rootPath,
          snapshots: sourceProjectionSnapshots,
        );
        await _restoreProjectionSnapshots(
          rootPath: rootPath,
          snapshots: targetProjectionSnapshots,
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<Map<String, SqliteProjectBodyTextDocument>>
  _loadStructuredDocumentsInScope({
    required ProjectDescriptor project,
    required String relativePath,
  }) async {
    final cleanPath = _cleanRelativePath(relativePath);
    if (cleanPath.isEmpty) {
      return const <String, SqliteProjectBodyTextDocument>{};
    }
    final documents = await _structuredContentBridgeService
        .listStructuredDocuments(project: project);
    return <String, SqliteProjectBodyTextDocument>{
      for (final document in documents)
        if (document.documentId == cleanPath ||
            document.documentId.startsWith('$cleanPath/'))
          document.documentId: document,
    };
  }

  String _targetPathForSourceDocument({
    required String sourcePath,
    required String sourceScopePath,
    required String targetScopePath,
  }) {
    if (sourcePath == sourceScopePath) {
      return targetScopePath;
    }
    return '$targetScopePath${sourcePath.substring(sourceScopePath.length)}';
  }

  Future<Map<String, _ProjectionSnapshot>> _captureProjectionSnapshots({
    required String rootPath,
    required Iterable<String> documentPaths,
  }) async {
    final snapshots = <String, _ProjectionSnapshot>{};
    for (final path in documentPaths) {
      snapshots[path] = await _captureProjectionSnapshot(
        rootPath: rootPath,
        relativePath: path,
      );
    }
    return snapshots;
  }

  Future<_ProjectionSnapshot> _captureProjectionSnapshot({
    required String rootPath,
    required String relativePath,
  }) async {
    final exists = await _fileMutationAdapter.entryExists(
      rootPath,
      relativePath,
    );
    return _ProjectionSnapshot(
      existed: exists,
      content: exists
          ? await _workspacePort.readTextFile(rootPath, relativePath)
          : null,
    );
  }

  Future<void> _restoreStructuredDocumentSnapshot({
    required ProjectDescriptor project,
    required String documentPath,
    required SqliteProjectBodyTextDocument? snapshot,
  }) async {
    try {
      await _structuredContentBridgeService.restoreStructuredDocument(
        project: project,
        documentPath: documentPath,
        snapshot: snapshot,
      );
    } catch (_) {}
  }

  Future<void> _restoreStructuredDocumentSnapshots({
    required ProjectDescriptor project,
    required Map<String, SqliteProjectBodyTextDocument?> snapshots,
  }) async {
    for (final entry in snapshots.entries) {
      await _restoreStructuredDocumentSnapshot(
        project: project,
        documentPath: entry.key,
        snapshot: entry.value,
      );
    }
  }

  Future<void> _restoreProjectionSnapshots({
    required String rootPath,
    required Map<String, _ProjectionSnapshot> snapshots,
  }) async {
    for (final entry in snapshots.entries) {
      await _restoreProjectionSnapshot(
        rootPath: rootPath,
        relativePath: entry.key,
        snapshot: entry.value,
      );
    }
  }

  Future<void> _restoreProjectionSnapshot({
    required String rootPath,
    required String relativePath,
    required _ProjectionSnapshot snapshot,
  }) async {
    try {
      if (!snapshot.existed) {
        if (await _fileMutationAdapter.entryExists(rootPath, relativePath)) {
          await _fileMutationAdapter.deleteEntry(rootPath, relativePath);
        }
        return;
      }
      if (snapshot.content != null) {
        await _workspacePort.writeTextFile(
          rootPath,
          relativePath,
          snapshot.content!,
        );
      }
    } catch (_) {}
  }

  @override
  Future<String?> readExternalTextFile(String absolutePath) {
    // 中文注释: 外部文本读取仍由更细的宿主变更适配器承接，避免工作区端口引入宿主绝对路径概念。
    return _fileMutationAdapter.readExternalTextFile(absolutePath);
  }

  @override
  Future<void> writeExternalTextFile(String absolutePath, String content) {
    // 中文注释: 外部文本写出同样收口到宿主适配器，让目录包导出和后续 zip 导出共用一层文件出口。
    return _fileMutationAdapter.writeExternalTextFile(absolutePath, content);
  }

  @override
  Future<void> copyExternalFile(
    String absolutePath,
    String rootPath,
    String targetRelativePath,
  ) {
    // 中文注释: 外部文件复制属于宿主导入行为，因此保持在变更适配器边界内。
    return _fileMutationAdapter.copyExternalFile(
      absolutePath,
      rootPath,
      targetRelativePath,
    );
  }
}

class _ProjectionSnapshot {
  const _ProjectionSnapshot({required this.existed, required this.content});

  final bool existed;
  final String? content;
}
