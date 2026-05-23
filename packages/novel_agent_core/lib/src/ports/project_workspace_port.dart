import '../common/json_types.dart';

abstract class ProjectWorkspacePort {
  Future<List<JsonMap>> listEntries(String rootPath, {bool recursive = true});

  Future<String?> readTextFile(String rootPath, String relativePath);

  Future<void> writeTextFile(
    String rootPath,
    String relativePath,
    String content,
  );
}
