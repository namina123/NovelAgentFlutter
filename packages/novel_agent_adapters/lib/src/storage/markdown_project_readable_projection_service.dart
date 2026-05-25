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
      'premise/project_brief.md',
      _projectBrief(manifest),
    );
  }

  String _projectBrief(ProjectManifest manifest) {
    return '# ${manifest.title}\n\n'
        '- 项目类型：${manifest.projectType}\n'
        '- 主存储策略：${manifest.storageStrategy.id}\n'
        '- 题材：\n'
        '- 核心卖点：\n'
        '- 创作边界：\n'
        '- 当前阶段：起步\n';
  }
}
