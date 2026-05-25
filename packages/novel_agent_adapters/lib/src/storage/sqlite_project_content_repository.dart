import 'package:novel_agent_core/novel_agent_core.dart';

import 'sqlite_project_database_initializer.dart';
import 'sqlite_project_directory_skeleton_service.dart';

class SqliteProjectContentRepository implements ProjectContentRepository {
  SqliteProjectContentRepository({
    required ProjectWorkspacePort projectWorkspacePort,
    SqliteProjectDirectorySkeletonService? directorySkeletonService,
    SqliteProjectDatabaseInitializer? databaseInitializer,
  }) : _directorySkeletonService =
           directorySkeletonService ??
           SqliteProjectDirectorySkeletonService(
             projectWorkspacePort: projectWorkspacePort,
           ),
       _databaseInitializer =
           databaseInitializer ?? SqliteProjectDatabaseInitializer();

  final SqliteProjectDirectorySkeletonService _directorySkeletonService;
  final SqliteProjectDatabaseInitializer _databaseInitializer;

  @override
  Future<void> initializeProjectContent({
    required String rootPath,
    required ProjectManifest manifest,
    required ProjectDirectoryLayout layout,
  }) async {
    // 中文注释: SQLite 主内容仓储这里只编排“目录骨架 + 最小建库”，具体 schema 与表写入能力继续交给独立 store 扩展。
    await _directorySkeletonService.createSkeleton(
      rootPath: rootPath,
      layout: layout,
    );
    await _databaseInitializer.initialize(
      rootPath: rootPath,
      manifest: manifest,
    );
  }
}
