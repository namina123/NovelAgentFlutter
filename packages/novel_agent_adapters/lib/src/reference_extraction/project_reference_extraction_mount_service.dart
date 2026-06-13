import 'package:novel_agent_core/novel_agent_core.dart';

import '../storage/project_reference_projection_port.dart';
import '../storage/sqlite_project_reference_attachment_layer.dart';
import '../storage/sqlite_first_project_reference_projection_port_factory.dart';
import '../tools/project_tool_path_policy.dart';
import 'project_reference_extraction_runtime_models.dart';
import 'project_reference_mount_outcome.dart';
import 'project_reference_mount_outcome_resolver_service.dart';

class ProjectReferenceExtractionMountService {
  ProjectReferenceExtractionMountService({
    required ProjectWorkspacePort workspacePort,
    ProjectToolPathPolicy? toolPathPolicy,
    ProjectReferenceAttachmentLayer? attachmentLayer,
    ProjectReferenceProjectionPortFactory? projectionPortFactory,
    ProjectReferenceMountOutcomeResolverService? mountOutcomeResolverService,
  }) : _toolPathPolicy = toolPathPolicy ?? ProjectToolPathPolicy(),
       _attachmentLayer =
           attachmentLayer ?? SqliteProjectReferenceAttachmentLayer(),
       _projectionPortFactory =
           projectionPortFactory ??
           SqliteFirstProjectReferenceProjectionPortFactory(
             workspacePort: workspacePort,
           ),
       _mountOutcomeResolverService =
           mountOutcomeResolverService ??
           const ProjectReferenceMountOutcomeResolverService();

  final ProjectToolPathPolicy _toolPathPolicy;
  final ProjectReferenceAttachmentLayer _attachmentLayer;
  final ProjectReferenceProjectionPortFactory _projectionPortFactory;
  final ProjectReferenceMountOutcomeResolverService
  _mountOutcomeResolverService;

  Future<ProjectReferenceMountOutcome> attachAndProjectIfRequested({
    required ProjectDescriptor project,
    required ReferenceEvidenceSubstrate substrate,
    required ProjectReferenceExtractionRequest request,
    required String packageId,
    required String packageVersionId,
    required String displayName,
    required String attachedAt,
  }) async {
    if (!request.attachToProject && !request.projectMountedEntries) {
      return _mountOutcomeResolverService.resolve(
        request: request,
        publishedSnapshotAvailable: true,
      );
    }
    await _attachmentLayer.upsertAttachment(
      project,
      ProjectReferenceAttachment(
        attachmentId:
            'ref_attach_${_toolPathPolicy.safeFileName('${packageId}_$packageVersionId', fallback: 'reference_attachment')}',
        projectId: project.id,
        packageId: packageId,
        packageVersionId: packageVersionId,
        visibilityMode: ReferenceVisibilityModes.discoverable,
        accessLevel: ReferenceAccessLevels.manager,
        displayLabel: displayName,
        allowsDiscoveryExpansion: true,
        allowsProjection: true,
        allowsPromotion: true,
        requiresConfirmation: !request.explicitProjectionConfirmationGranted,
        attachedAt: attachedAt,
        metadata: const <String, Object?>{
          'source': 'reference_extraction_runtime',
        },
      ),
    );
    if (!request.projectMountedEntries) {
      return _mountOutcomeResolverService.resolve(
        request: request,
        publishedSnapshotAvailable: true,
      );
    }
    final projectionResult = await _buildProjectionPort(substrate)
        .projectMountedEntries(
          project,
          ReferenceProjectionRequest(
            packageId: packageId,
            packageVersionId: packageVersionId,
            requestedBy: 'reference_extraction_runtime',
            explicitConfirmationGranted:
                request.explicitProjectionConfirmationGranted,
          ),
        );
    return _mountOutcomeResolverService.resolve(
      request: request,
      publishedSnapshotAvailable: true,
      projectionResult: projectionResult,
    );
  }

  ProjectReferenceProjectionPort _buildProjectionPort(
    ReferenceEvidenceSubstrate substrate,
  ) {
    return _projectionPortFactory.create(
      substrate: substrate,
      attachmentLayer: _attachmentLayer,
    );
  }
}
