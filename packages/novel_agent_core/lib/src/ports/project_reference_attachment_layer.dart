import '../project/project_descriptor.dart';
import '../reference_substrate/reference_access_models.dart';

abstract class ProjectReferenceAttachmentLayer {
  Future<void> upsertAttachment(
    ProjectDescriptor project,
    ProjectReferenceAttachment attachment,
  );

  Future<ProjectReferenceAttachment?> readAttachment(
    ProjectDescriptor project, {
    required String packageId,
  });

  Future<List<ProjectReferenceAttachment>> listAttachments(
    ProjectDescriptor project, {
    String? visibilityMode,
  });
}
