import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_source_original_archive_store.dart';

class SqliteProjectSourceOriginalArchiveStore
    implements ProjectSourceOriginalArchiveStore {
  SqliteProjectSourceOriginalArchiveStore({
    required ProjectToolHostPort projectToolHostPort,
    ProjectStructuredContentBridgeService? structuredContentBridgeService,
  }) : _projectToolHostPort = projectToolHostPort,
       _structuredContentBridgeService =
           structuredContentBridgeService ??
           ProjectStructuredContentBridgeService();

  final ProjectToolHostPort _projectToolHostPort;
  final ProjectStructuredContentBridgeService _structuredContentBridgeService;

  @override
  Future<void> persist({
    required ProjectDescriptor project,
    required String relativePath,
    required String title,
    required String content,
    String statePath = '',
  }) async {
    // 中文注释: SQLite 项目同时保留文件投影与数据库主事实源，避免导入链自己理解双写细节。
    await _projectToolHostPort.writeTextFile(
      project.rootPath,
      relativePath,
      content,
    );
    await _structuredContentBridgeService.persistSourceOriginalArchive(
      project: project,
      archivePath: relativePath,
      archiveTitle: title,
      sourceContent: content,
      statePath: statePath,
    );
  }
}
