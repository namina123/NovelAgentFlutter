import '../common/json_types.dart';

abstract class ProjectToolHostPort {
  Future<List<JsonMap>> listEntries(String rootPath, {bool recursive = true});

  Future<String?> readTextFile(String rootPath, String relativePath);

  Future<void> writeTextFile(
    String rootPath,
    String relativePath,
    String content,
  );

  Future<bool> entryExists(String rootPath, String relativePath);

  Future<void> createDirectory(String rootPath, String relativePath);

  Future<void> deleteEntry(String rootPath, String relativePath);

  Future<void> moveEntry(
    String rootPath,
    String sourceRelativePath,
    String targetRelativePath,
  );
}
