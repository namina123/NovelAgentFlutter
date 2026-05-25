import 'package:novel_agent_core/novel_agent_core.dart';

class DelegatingProjectContentRepository implements ProjectContentRepository {
  DelegatingProjectContentRepository({
    required ProjectContentRepository markdownRepository,
    required ProjectContentRepository sqliteRepository,
  }) : _markdownRepository = markdownRepository,
       _sqliteRepository = sqliteRepository;

  final ProjectContentRepository _markdownRepository;
  final ProjectContentRepository _sqliteRepository;

  @override
  Future<void> initializeProjectContent({
    required String rootPath,
    required ProjectManifest manifest,
    required ProjectDirectoryLayout layout,
  }) {
    // 中文注释: 调度器只负责按 manifest 里的主存储策略分发，不承载任何具体目录或数据库规则。
    switch (manifest.storageStrategy) {
      case ProjectStorageStrategy.markdownProjectStore:
        return _markdownRepository.initializeProjectContent(
          rootPath: rootPath,
          manifest: manifest,
          layout: layout,
        );
      case ProjectStorageStrategy.sqliteProjectStore:
        return _sqliteRepository.initializeProjectContent(
          rootPath: rootPath,
          manifest: manifest,
          layout: layout,
        );
    }
  }
}
