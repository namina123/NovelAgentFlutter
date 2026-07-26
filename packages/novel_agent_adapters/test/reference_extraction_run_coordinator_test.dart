import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ReferenceExtractionRunCoordinator', () {
    test('exposes identity and publication contracts as stable helpers', () {
      final coordinator = ReferenceExtractionRunCoordinator(
        workspacePort: LocalProjectWorkspacePort(),
      );

      expect(
        coordinator.identityService.resolveRunId(
          requestedRunId: '',
          now: DateTime.utc(2026, 6, 17, 1, 2, 3, 4, 5),
          fallbackPrefix: 'reference_extraction_gui',
        ),
        startsWith('reference_extraction_gui_'),
      );
      expect(
        coordinator.publicationService.shouldContinueSemantically(
          _result(
            runStatus:
                ReferenceExtractionRunStatuses.awaitingSemanticContinuation,
            needsContinuation: true,
            publishedSnapshotAvailable: false,
            projectMountStatus:
                ProjectReferenceMountStatuses.snapshotUnavailable,
          ),
        ),
        isTrue,
      );
      expect(
        coordinator.publicationService.isPublishedProjectionResult(
          _result(
            finalizedEntryCount: 2,
            publishedSnapshotAvailable: true,
            projectMountStatus: ProjectReferenceMountStatuses.applied,
          ),
        ),
        isTrue,
      );
    });
  });
}

ProjectReferenceExtractionResult _result({
  String runStatus = ReferenceExtractionRunStatuses.completedPublishable,
  bool needsContinuation = false,
  bool publishedSnapshotAvailable = true,
  int finalizedEntryCount = 1,
  String projectMountStatus = ProjectReferenceMountStatuses.applied,
}) {
  return ProjectReferenceExtractionResult(
    runId: 'reference_run',
    packageId: 'pkg_reference',
    packageVersionId: 'v1',
    sourceFilePath: 'references/sample.txt',
    sourceDecodeMode: 'utf8',
    groupResolutionKind: 'task_family_override',
    selectedGroupId: 'reference_group',
    strategyProfileId: 'reference_extraction.standard',
    executionConcurrencyMode: ReferenceExtractionConcurrencyModes.single,
    proposalCount: 1,
    acceptedProposalCount: 1,
    finalizedEntryCount: finalizedEntryCount,
    runStatus: runStatus,
    needsContinuation: needsContinuation,
    publishedSnapshotAvailable: publishedSnapshotAvailable,
    projectMountStatus: projectMountStatus,
  );
}
