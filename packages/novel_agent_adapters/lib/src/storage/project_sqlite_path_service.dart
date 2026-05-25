import 'project_relative_path_resolver.dart';

class ProjectSqlitePathService {
  ProjectSqlitePathService({ProjectRelativePathResolver? pathResolver})
    : _pathResolver = pathResolver ?? ProjectRelativePathResolver();

  final ProjectRelativePathResolver _pathResolver;

  String databasePath(String rootPath) {
    return _pathResolver.resolve(
      rootPath: rootPath,
      relativePath: '.novel_agent/sqlite/novel_agent.db',
    );
  }
}
