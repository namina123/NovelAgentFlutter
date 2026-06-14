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
  final SqliteProjectSemanticProjectionBuilderService
  _projectionBuilderService;

  @override
  Future<void> ensureReadableProjection({
    required String rootPath,
    required ProjectManifest manifest,
    required ProjectDirectoryLayout layout,
  }) async {
    // 中文注释: SQLite 项目先把可读目录、语义树索引和快速说明一并物化，避免只剩一个 project_brief.md 作为伪入口。
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
      'premise/project_brief.md',
      _projectBrief(manifest),
    );
  }

  String _projectBrief(ProjectManifest manifest) {
    return '# ${manifest.title}\n\n'
        '- 项目类型：${manifest.projectType}\n'
        '- 主存储策略：${manifest.storageStrategy.id}\n'
        '- 当前内容来源：SQLite 主库存储，Markdown 仅作为投影/导出层。\n'
        '- 语义树入口：premise/sqlite_projection/index.md\n'
        '- 当前阶段：起步\n';
  }
}
