import 'package:novel_agent_core/novel_agent_core.dart';

class WorkbenchResourceIdentityService {
  const WorkbenchResourceIdentityService({
    ProjectArtifactIdentityService? artifactIdentityService,
  }) : _artifactIdentityService =
           artifactIdentityService ?? const ProjectArtifactIdentityService();

  final ProjectArtifactIdentityService _artifactIdentityService;

  ProjectArtifactIdentity classify({
    required String relativePath,
    required bool isDirectory,
    String projectTypeId = '',
  }) {
    final normalized = _normalize(relativePath);
    if (normalized.isEmpty) {
      return ProjectArtifactIdentity.unknown;
    }
    return _artifactIdentityService.classify(
      relativePath: normalized,
      isDirectory: isDirectory,
      projectTypeId: projectTypeId,
    );
  }

  String secondaryLabel({
    required String relativePath,
    required bool isDirectory,
    String projectTypeId = '',
  }) {
    return classify(
      relativePath: relativePath,
      isDirectory: isDirectory,
      projectTypeId: projectTypeId,
    ).detailLabel;
  }

  String _normalize(String relativePath) {
    return relativePath.trim().replaceAll('\\', '/').toLowerCase();
  }
}
