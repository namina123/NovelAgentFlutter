import 'package:novel_agent_core/novel_agent_core.dart';

class MarkdownProjectReadableProjectionService
    implements ProjectReadableProjectionService {
  MarkdownProjectReadableProjectionService({
    required ProjectWorkspacePort projectWorkspacePort,
  }) : _projectWorkspacePort = projectWorkspacePort;

  final ProjectWorkspacePort _projectWorkspacePort;

  @override
  Future<void> ensureReadableProjection({
    required String rootPath,
    required ProjectManifest manifest,
    required ProjectDirectoryLayout layout,
  }) async {
    // 中文注释: Markdown 项目主内容已经直接是可读目录，这里只补最小入口文档，避免创建期就写入过多默认内容。
    await _projectWorkspacePort.writeTextFile(
      rootPath,
      ProjectSupportDocumentCatalog.projectOverviewRelativePath,
      _projectBrief(manifest),
    );
  }

  String _projectBrief(ProjectManifest manifest) {
    return '# 项目概览\n\n'
        '> 这是系统维护的快速概览，不是正式故事前提、长期设定承诺或项目宪章。\n'
        '> 正式前提、总纲、角色和世界规则应分别沉淀到 premise/、outlines/、assets/ 下的正式文档中。\n\n'
        '- 项目标题：${manifest.title}\n'
        '- 项目类型：${manifest.projectType}\n'
        '- 主存储策略：${manifest.storageStrategy.id}\n'
        '- 当前状态：项目已创建，等待正式前提与结构资产沉淀。\n';
  }
}
