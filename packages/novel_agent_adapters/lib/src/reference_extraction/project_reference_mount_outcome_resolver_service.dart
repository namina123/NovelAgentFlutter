import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_reference_extraction_runtime_models.dart';
import 'project_reference_mount_outcome.dart';

class ProjectReferenceMountOutcomeResolverService {
  const ProjectReferenceMountOutcomeResolverService();

  ProjectReferenceMountOutcome resolve({
    required ProjectReferenceExtractionRequest request,
    required bool publishedSnapshotAvailable,
    ReferenceProjectionResult? projectionResult,
  }) {
    // 中文注释: 这里统一解释“请求挂载后当前这轮到底处于哪种正式结果语义”，避免 runtime / mount / projection 各自补一套状态映射。
    if (!request.attachToProject && !request.projectMountedEntries) {
      return const ProjectReferenceMountOutcome(
        status: ProjectReferenceMountStatuses.notRequested,
      );
    }
    if (!publishedSnapshotAvailable) {
      return const ProjectReferenceMountOutcome(
        status: ProjectReferenceMountStatuses.snapshotUnavailable,
        warningCodes: <String>['published_snapshot_unavailable'],
      );
    }
    if (!request.projectMountedEntries) {
      return const ProjectReferenceMountOutcome(
        status: ProjectReferenceMountStatuses.attachedOnly,
      );
    }
    if (projectionResult == null) {
      throw StateError(
        'projectMountedEntries=true 且已具备 published snapshot 时，projectionResult 不能为空。',
      );
    }
    return ProjectReferenceMountOutcome(
      status: projectionResult.status,
      warningCodes: List<String>.from(projectionResult.warnings),
      projectionResult: projectionResult,
    );
  }
}
