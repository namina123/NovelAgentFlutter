import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_source_original_archive_store.dart';

class MarkdownProjectSourceOriginalArchiveStore
    implements ProjectSourceOriginalArchiveStore {
  MarkdownProjectSourceOriginalArchiveStore({
    required ProjectToolHostPort projectToolHostPort,
  }) : _projectToolHostPort = projectToolHostPort;

  final ProjectToolHostPort _projectToolHostPort;

  @override
  Future<void> persist({
    required ProjectDescriptor project,
    required String relativePath,
    required String title,
    required String content,
    String statePath = '',
  }) {
    // 中文注释: Markdown 项目的原文归档只需要保留文件主事实源，不承担额外结构化写入。
    return _projectToolHostPort.writeTextFile(
      project.rootPath,
      relativePath,
      content,
    );
  }
}
