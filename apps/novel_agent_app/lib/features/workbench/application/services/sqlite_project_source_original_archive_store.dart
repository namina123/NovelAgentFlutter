import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_source_original_archive_store.dart';

class SqliteProjectSourceOriginalArchiveStore
    implements ProjectSourceOriginalArchiveStore {
  SqliteProjectSourceOriginalArchiveStore({
    required ProjectToolHostPort projectToolHostPort,
    ProjectStructuredContentBridgeService? structuredContentBridgeService,
  }) : _structuredContentBridgeService =
           structuredContentBridgeService ??
           ProjectStructuredContentBridgeService();

  final ProjectStructuredContentBridgeService _structuredContentBridgeService;

  @override
  Future<void> persist({
    required ProjectDescriptor project,
    required String relativePath,
    required String title,
    required String content,
    String statePath = '',
  }) async {
    // 中文注释: SQLite 项目不再把原文归档额外双写到用户可见 Markdown 面；文件树只保留导入原件与必要结构入口。
    await _structuredContentBridgeService.persistSourceOriginalArchive(
      project: project,
      archivePath: relativePath,
      archiveTitle: title,
      sourceContent: content,
      statePath: statePath,
    );
  }
}
