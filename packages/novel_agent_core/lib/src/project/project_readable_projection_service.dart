import 'project_directory_layout.dart';
import 'project_manifest.dart';

abstract class ProjectReadableProjectionService {
  Future<void> ensureReadableProjection({
    required String rootPath,
    required ProjectManifest manifest,
    required ProjectDirectoryLayout layout,
  });
}
