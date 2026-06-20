import 'project_content_path_policy_service.dart';
import 'project_storage_strategy.dart';

class ProjectStorageStrategyPathPolicyService {
  const ProjectStorageStrategyPathPolicyService({
    ProjectContentPathPolicyService? contentPathPolicyService,
  }) : _contentPathPolicyService =
           contentPathPolicyService ?? const ProjectContentPathPolicyService();

  final ProjectContentPathPolicyService _contentPathPolicyService;

  String defaultWorkspaceFileDirectory(ProjectStorageStrategy storageStrategy) {
    switch (storageStrategy) {
      case ProjectStorageStrategy.markdownProjectStore:
        return _contentPathPolicyService.defaultWorkspaceFileDirectory();
      case ProjectStorageStrategy.sqliteProjectStore:
        return 'imports';
      }
  }

  String defaultWorkspaceFolderDirectory(
    ProjectStorageStrategy storageStrategy,
  ) {
    switch (storageStrategy) {
      case ProjectStorageStrategy.markdownProjectStore:
        return _contentPathPolicyService.defaultWorkspaceFolderDirectory();
      case ProjectStorageStrategy.sqliteProjectStore:
        return 'imports';
    }
  }

  String defaultImportTargetDirectory(ProjectStorageStrategy storageStrategy) {
    switch (storageStrategy) {
      case ProjectStorageStrategy.markdownProjectStore:
        return _contentPathPolicyService.defaultImportTargetDirectory();
      case ProjectStorageStrategy.sqliteProjectStore:
        return 'imports';
    }
  }

  String directoryForContentType({
    required ProjectStorageStrategy storageStrategy,
    required String contentType,
  }) {
    final normalized = _contentPathPolicyService.normalizeContentType(
      contentType,
    );
    switch (storageStrategy) {
      case ProjectStorageStrategy.markdownProjectStore:
        return _contentPathPolicyService.directoryForContentType(normalized);
      case ProjectStorageStrategy.sqliteProjectStore:
        switch (normalized) {
          case 'source_original':
            return 'imports/source_original';
          case 'analysis':
            return 'imports/analysis';
          case 'derived_continuation_narrative':
            return 'imports/derived/continuation';
          case 'derived_fanfic_narrative':
            return 'imports/derived/fanfic';
          case 'outline':
            return 'imports/analysis/outlines';
          case 'chapter_outline':
            return 'imports/analysis/chapter_outlines';
          case 'volume_outline':
            return 'imports/analysis/volume_outlines';
          case 'setting':
            return 'imports/analysis/assets/world';
          case 'character':
            return 'imports/analysis/assets/characters';
          case 'style':
            return 'imports/analysis/assets/styles';
          case 'summary':
            return 'imports/analysis/summaries';
          case 'knowledge':
            return 'imports/analysis/knowledge';
          default:
            return 'imports';
        }
    }
  }
}
