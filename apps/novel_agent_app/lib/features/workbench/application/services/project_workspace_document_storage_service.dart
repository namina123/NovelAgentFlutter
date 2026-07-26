import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

/// Keeps manual workbench editing on the same fact-source contract as project
/// generation and import workflows.
class ProjectWorkspaceDocumentStorageService {
  ProjectWorkspaceDocumentStorageService({
    required ReadProjectFileUseCase readProjectFileUseCase,
    required SaveDraftUseCase saveDraftUseCase,
    ProjectStructuredContentBridgeService? structuredContentBridgeService,
    DraftFilePathService? draftFilePathService,
    ProjectContentPathPolicyService? contentPathPolicyService,
  }) : _readProjectFileUseCase = readProjectFileUseCase,
       _saveDraftUseCase = saveDraftUseCase,
       _structuredContentBridgeService =
           structuredContentBridgeService ??
           ProjectStructuredContentBridgeService(),
       _draftFilePathService = draftFilePathService ?? DraftFilePathService(),
       _contentPathPolicyService =
           contentPathPolicyService ?? const ProjectContentPathPolicyService();

  final ReadProjectFileUseCase _readProjectFileUseCase;
  final SaveDraftUseCase _saveDraftUseCase;
  final ProjectStructuredContentBridgeService _structuredContentBridgeService;
  final DraftFilePathService _draftFilePathService;
  final ProjectContentPathPolicyService _contentPathPolicyService;

  Future<String?> read({
    required ProjectDescriptor project,
    required String relativePath,
  }) async {
    // 中文注释: SQLite 项目的结构化文档优先回读主事实源；旧项目或非结构化路径仍兼容文件树。
    final structuredContent = await _structuredContentBridgeService
        .readProjectedBodyText(project, relativePath);
    return structuredContent ??
        _readProjectFileUseCase.execute(project, relativePath);
  }

  Future<String> save({
    required ProjectDescriptor project,
    required String content,
    String title = '',
    String relativePath = '',
  }) async {
    final resolvedPath = relativePath.trim().isEmpty
        ? _draftFilePathService.buildPath(title: title, content: content)
        : relativePath.trim();
    // 中文注释: SQLite 是结构化内容的主事实源，先提交主库，再更新工作区 Markdown 投影。
    final documentKind = _documentKindFor(project, resolvedPath);
    final writesStructuredPrimarySource =
        const ProjectStructuredContentWritePolicy()
            .shouldWriteToSqlitePrimarySource(
              storageStrategy: project.storageStrategy,
              documentKind: documentKind,
            );
    final previousStructuredDocument = writesStructuredPrimarySource
        ? await _structuredContentBridgeService.loadStructuredDocument(
            project: project,
            documentPath: resolvedPath,
          )
        : null;
    await persistPrimarySource(
      project: project,
      relativePath: resolvedPath,
      title: title,
      content: content,
    );
    try {
      return await _saveDraftUseCase.execute(
        project: project,
        content: content,
        title: title,
        relativePath: resolvedPath,
      );
    } catch (error, stackTrace) {
      // 中文注释: SQLite 与文件投影没有跨介质事务。投影失败时恢复保存前的主库
      // 快照，避免 UI 报错但重新打开项目后却看到一份未成功保存的新内容。
      if (writesStructuredPrimarySource) {
        try {
          await _structuredContentBridgeService.restoreStructuredDocument(
            project: project,
            documentPath: resolvedPath,
            snapshot: previousStructuredDocument,
          );
        } catch (_) {
          // Preserve the projection failure so callers retain the actionable error.
        }
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> persistPrimarySource({
    required ProjectDescriptor project,
    required String relativePath,
    required String content,
    String title = '',
  }) {
    final documentKind = _documentKindFor(project, relativePath);
    return _structuredContentBridgeService.persistStructuredDocument(
      project: project,
      documentPath: relativePath,
      documentKind: documentKind,
      title: title,
      content: content,
    );
  }

  Future<SqliteProjectBodyTextDocument?> snapshotPrimarySource({
    required ProjectDescriptor project,
    required String relativePath,
  }) {
    final documentKind = _documentKindFor(project, relativePath);
    final writesStructuredPrimarySource =
        const ProjectStructuredContentWritePolicy()
            .shouldWriteToSqlitePrimarySource(
              storageStrategy: project.storageStrategy,
              documentKind: documentKind,
            );
    if (!writesStructuredPrimarySource) {
      return Future<SqliteProjectBodyTextDocument?>.value();
    }
    return _structuredContentBridgeService.loadStructuredDocument(
      project: project,
      documentPath: relativePath,
    );
  }

  Future<void> restorePrimarySource({
    required ProjectDescriptor project,
    required String relativePath,
    required SqliteProjectBodyTextDocument? snapshot,
  }) async {
    final documentKind = _documentKindFor(project, relativePath);
    final writesStructuredPrimarySource =
        const ProjectStructuredContentWritePolicy()
            .shouldWriteToSqlitePrimarySource(
              storageStrategy: project.storageStrategy,
              documentKind: documentKind,
            );
    if (!writesStructuredPrimarySource) {
      return;
    }
    await _structuredContentBridgeService.restoreStructuredDocument(
      project: project,
      documentPath: relativePath,
      snapshot: snapshot,
    );
  }

  String _documentKindFor(ProjectDescriptor project, String relativePath) {
    // 中文注释: SQLite 知识库默认把手工新建文件放在 imports/；这类资料不能因为
    // 路径是通用导入根就退化成 chapter，与 GUI/CLI 导入路径保持同一分类合同。
    final normalizedPath = relativePath.trim().replaceAll('\\', '/');
    if (project.projectType.trim() == 'knowledge_base' &&
        normalizedPath.startsWith('imports/') &&
        !normalizedPath.startsWith('imports/analysis/') &&
        !normalizedPath.startsWith('imports/source_original/') &&
        !normalizedPath.startsWith('imports/derived/')) {
      return 'knowledge';
    }
    return _contentPathPolicyService.inferContentTypeFromPath(normalizedPath);
  }
}
