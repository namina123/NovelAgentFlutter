import 'package:novel_agent_core/novel_agent_core.dart';

import 'sqlite_project_semantic_projection_builder_service.dart';

class SqliteProjectReadableProjectionService
    implements ProjectReadableProjectionService {
  SqliteProjectReadableProjectionService({
    required ProjectWorkspacePort projectWorkspacePort,
    SqliteProjectSemanticProjectionBuilderService? projectionBuilderService,
  }) : _projectWorkspacePort = projectWorkspacePort,
       _projectionBuilderService =
           projectionBuilderService ??
           const SqliteProjectSemanticProjectionBuilderService();

  final ProjectWorkspacePort _projectWorkspacePort;
  final SqliteProjectSemanticProjectionBuilderService _projectionBuilderService;

  @override
  Future<void> ensureReadableProjection({
    required String rootPath,
    required ProjectManifest manifest,
    required ProjectDirectoryLayout layout,
  }) async {
    // 中文注释: SQLite 项目先把可读目录、语义树索引和快速说明一并物化，避免只剩一个 overview 说明页作为伪入口。
    for (final descriptor in layout.readableProjectionDirectories) {
      await _projectWorkspacePort.createDirectory(rootPath, descriptor.path);
    }
    final workspaceEntries = await _projectWorkspacePort.listEntries(rootPath);
    final projection = _projectionBuilderService.build(
      rootPath: rootPath,
      manifest: manifest,
      layout: layout,
      workspaceEntries: workspaceEntries,
    );
    for (final document in projection.documents) {
      await _projectWorkspacePort.writeTextFile(
        rootPath,
        document.relativePath,
        document.markdown,
      );
    }
    await _projectWorkspacePort.writeTextFile(
      rootPath,
      ProjectSupportDocumentCatalog.projectOverviewRelativePath,
      _projectBrief(manifest),
    );
  }

  String _projectBrief(ProjectManifest manifest) {
    return '# 项目概览\n\n'
        '> 这是系统维护的 SQLite 项目快速概览，不是正式故事前提或项目宪章。\n'
        '> 当前项目的正式主事实源是 SQLite；Markdown 仅承担只读摘要、导出和入口说明作用。\n\n'
        '- 项目标题：${manifest.title}\n'
        '- 项目类型：${manifest.projectType}\n'
        '- 主存储策略：${manifest.storageStrategy.id}\n'
        '- 语义树入口：premise/sqlite_projection/index.md\n'
        '- 当前状态：项目已创建，等待正式前提与结构资产沉淀。\n';
  }
}
