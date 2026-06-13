import 'package:novel_agent_core/novel_agent_core.dart';

abstract class ProjectReferenceProjectionPort {
  Future<ReferenceProjectionResult> projectMountedEntries(
    ProjectDescriptor project,
    ReferenceProjectionRequest request,
  );
}

abstract class ProjectReferenceProjectionPortFactory {
  ProjectReferenceProjectionPort create({
    required ReferenceEvidenceSubstrate substrate,
    required ProjectReferenceAttachmentLayer attachmentLayer,
  });
}
