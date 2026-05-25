import '../project/project_directory_layout.dart';
import '../project/project_manifest.dart';

abstract class ProjectContentRepository {
  Future<void> initializeProjectContent({
    required String rootPath,
    required ProjectManifest manifest,
    required ProjectDirectoryLayout layout,
  });
}
