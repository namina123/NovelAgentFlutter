import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_reference_extraction_runtime_models.dart';
import 'project_reference_extraction_mount_service.dart';
import 'project_reference_mount_outcome.dart';
import 'project_reference_mount_outcome_resolver_service.dart';

class ReferenceExtractionMountCoordinator {
  ReferenceExtractionMountCoordinator({
    required ProjectWorkspacePort workspacePort,
    ProjectReferenceExtractionMountService? mountService,
    ProjectReferenceMountOutcomeResolverService? mountOutcomeResolverService,
  }) : _mountService =
           mountService ??
           ProjectReferenceExtractionMountService(workspacePort: workspacePort),
       _mountOutcomeResolverService =
           mountOutcomeResolverService ??
           const ProjectReferenceMountOutcomeResolverService();

  final ProjectReferenceExtractionMountService _mountService;
  final ProjectReferenceMountOutcomeResolverService
  _mountOutcomeResolverService;

  Future<ProjectReferenceMountOutcome> resolveMountOutcome({
    required ProjectDescriptor project,
    required ReferenceEvidenceSubstrate substrate,
    required ProjectReferenceExtractionRequest request,
    required String packageId,
    required String packageVersionId,
    required String displayName,
    required String attachedAt,
    required bool publishedSnapshotAvailable,
  }) async {
    if (!publishedSnapshotAvailable) {
      return _mountOutcomeResolverService.resolve(
        request: request,
        publishedSnapshotAvailable: false,
      );
    }
    return _mountService.attachAndProjectIfRequested(
      project: project,
      substrate: substrate,
      request: request,
      packageId: packageId,
      packageVersionId: packageVersionId,
      displayName: displayName,
      attachedAt: attachedAt,
    );
  }
}
