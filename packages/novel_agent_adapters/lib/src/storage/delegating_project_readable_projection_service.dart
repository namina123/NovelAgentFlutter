import 'package:novel_agent_core/novel_agent_core.dart';

class DelegatingProjectReadableProjectionService
    implements ProjectReadableProjectionService {
  DelegatingProjectReadableProjectionService({
    required ProjectReadableProjectionService markdownService,
    required ProjectReadableProjectionService sqliteService,
  }) : _markdownService = markdownService,
       _sqliteService = sqliteService;

  final ProjectReadableProjectionService _markdownService;
  final ProjectReadableProjectionService _sqliteService;

  @override
  Future<void> ensureReadableProjection({
    required String rootPath,
    required ProjectManifest manifest,
    required ProjectDirectoryLayout layout,
  }) {
    // 中文注释: 可读投影分发也跟随主存储策略走，避免创建用例里再次硬编码 if/else。
    switch (manifest.storageStrategy) {
      case ProjectStorageStrategy.markdownProjectStore:
        return _markdownService.ensureReadableProjection(
          rootPath: rootPath,
          manifest: manifest,
          layout: layout,
        );
      case ProjectStorageStrategy.sqliteProjectStore:
        return _sqliteService.ensureReadableProjection(
          rootPath: rootPath,
          manifest: manifest,
          layout: layout,
        );
    }
  }
}
