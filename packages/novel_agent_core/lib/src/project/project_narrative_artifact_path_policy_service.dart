import 'project_content_path_policy_service.dart';

class ProjectNarrativeArtifactPathPolicyService {
  const ProjectNarrativeArtifactPathPolicyService({
    ProjectContentPathPolicyService? contentPathPolicyService,
  }) : _contentPathPolicyService =
           contentPathPolicyService ?? const ProjectContentPathPolicyService();

  final ProjectContentPathPolicyService _contentPathPolicyService;

  bool isFormalChapterPath(String path) {
    return _isMarkdownPathUnder(
      path,
      _contentPathPolicyService.directoryForContentType('chapter'),
    );
  }

  bool isSamplePath(String path) {
    return _isMarkdownPathUnder(
      path,
      _contentPathPolicyService.directoryForContentType('sample'),
    );
  }

  bool isScenePath(String path) {
    return _isMarkdownPathUnder(
      path,
      _contentPathPolicyService.directoryForContentType('scene'),
    );
  }

  bool isNarrativeDeliveryPath(String path) {
    return isFormalChapterPath(path) || isSamplePath(path);
  }

  bool isChapterLikePath(
    String path, {
    bool includeSamples = true,
    bool includeScenes = true,
  }) {
    if (isFormalChapterPath(path)) {
      return true;
    }
    if (includeSamples && isSamplePath(path)) {
      return true;
    }
    if (includeScenes && isScenePath(path)) {
      return true;
    }
    return false;
  }

  bool _isMarkdownPathUnder(String path, String directory) {
    final normalizedPath = _normalize(path).toLowerCase();
    final normalizedDirectory = _normalize(directory).toLowerCase();
    if (normalizedPath.isEmpty || normalizedDirectory.isEmpty) {
      return false;
    }
    return normalizedPath.startsWith('$normalizedDirectory/') &&
        normalizedPath.endsWith('.md');
  }

  String _normalize(String value) {
    return value
        .trim()
        .replaceAll('\\', '/')
        .replaceAll(RegExp(r'/+$'), '');
  }
}
