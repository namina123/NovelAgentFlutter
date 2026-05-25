import 'package:novel_agent_core/novel_agent_core.dart';

class SqliteProjectReadableProjectionService
    implements ProjectReadableProjectionService {
  SqliteProjectReadableProjectionService({
    required ProjectWorkspacePort projectWorkspacePort,
  }) : _projectWorkspacePort = projectWorkspacePort;

  final ProjectWorkspacePort _projectWorkspacePort;

  @override
  Future<void> ensureReadableProjection({
    required String rootPath,
    required ProjectManifest manifest,
    required ProjectDirectoryLayout layout,
  }) async {
    // 中文注释: SQLite 项目先物化“用户可读投影目录”，这样后续即使主内容在数据库，也有稳定的可读入口位置。
    for (final descriptor in layout.readableProjectionDirectories) {
      await _projectWorkspacePort.createDirectory(rootPath, descriptor.path);
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
        '- 当前阶段：起步\n';
  }
}
