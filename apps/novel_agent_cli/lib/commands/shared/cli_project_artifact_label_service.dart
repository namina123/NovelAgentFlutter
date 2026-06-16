import 'package:novel_agent_core/novel_agent_core.dart';

class CliProjectArtifactLabelService {
  const CliProjectArtifactLabelService({
    ProjectArtifactIdentityService? artifactIdentityService,
  }) : _artifactIdentityService =
           artifactIdentityService ?? const ProjectArtifactIdentityService();

  final ProjectArtifactIdentityService _artifactIdentityService;

  String formatPath(String relativePath) {
    return _artifactIdentityService.formatPathWithLabel(relativePath);
  }
}
