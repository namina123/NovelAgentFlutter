import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ReferenceExtractionSupervisorSignalService', () {
    const service = ReferenceExtractionSupervisorSignalService();

    test(
      'keeps completed publishable runs completed for attach-only flows',
      () {
        final signal = service.build(
          _result(
            projectMountedEntriesRequested: false,
            attachToProjectRequested: true,
            projectMountStatus: ProjectReferenceMountStatuses.attachedOnly,
          ),
        );

        expect(signal.lifecycleState.runPhase, ContinuousTaskRunPhases.stopped);
        expect(
          signal.lifecycleState.stopCategory,
          ContinuousTaskStopCategories.completedNaturally,
        );
        expect(
          ValueReaders.stringValue(
            signal.metadata['supervisor_signal_category'],
          ),
          'completed',
        );
      },
    );

    test('maps projection confirmation gate to waiting_user', () {
      final signal = service.build(
        _result(
          projectMountStatus: ProjectReferenceMountStatuses.denied,
          projectMountWarningCodes: const <String>[
            'explicit_confirmation_required',
          ],
        ),
      );

      expect(
        signal.lifecycleState.runPhase,
        ContinuousTaskRunPhases.waitingUser,
      );
      expect(
        signal.lifecycleState.stopCategory,
        ContinuousTaskStopCategories.waitingUser,
      );
      expect(
        signal.lifecycleState.reason,
        'reference_mount_confirmation_required',
      );
      expect(
        ValueReaders.stringValue(signal.metadata['supervisor_signal_category']),
        'mount_waiting_user',
      );
    });

    test('maps unresolved continuity conflict to manual attention', () {
      final signal = service.build(
        _result(
          requiresManualContinuityReview: true,
          unresolvedConflictCount: 1,
          reviewAlertCount: 1,
        ),
      );

      expect(
        signal.lifecycleState.runPhase,
        ContinuousTaskRunPhases.manualAttention,
      );
      expect(
        signal.lifecycleState.stopCategory,
        ContinuousTaskStopCategories.manualAttention,
      );
      expect(
        signal.lifecycleState.reason,
        'reference_continuity_conflict_requires_review',
      );
      expect(
        ValueReaders.stringValue(signal.metadata['supervisor_signal_category']),
        'continuity_conflict',
      );
    });

    test(
      'maps missing mounted projection to paused mount-incomplete outcome',
      () {
        final signal = service.build(
          _result(
            projectMountStatus: ProjectReferenceMountStatuses.missingPackage,
            projectMountWarningCodes: const <String>[
              'package_snapshot_missing',
            ],
          ),
        );

        expect(signal.lifecycleState.runPhase, ContinuousTaskRunPhases.paused);
        expect(
          signal.lifecycleState.stopCategory,
          ContinuousTaskStopCategories.constraintGatePause,
        );
        expect(signal.lifecycleState.reason, 'reference_mount_incomplete');
        expect(
          ValueReaders.stringValue(
            signal.metadata['supervisor_signal_category'],
          ),
          'mount_incomplete',
        );
      },
    );

    test(
      'does not treat snapshot-unavailable staging runs as mount repair',
      () {
        final signal = service.build(
          _result(
            runStatus:
                ReferenceExtractionRunStatuses.awaitingSemanticContinuation,
            deliveryStatus: ReferenceExtractionDeliveryStatuses.stagingOnly,
            outputCompletionStatus:
                OutputCompletionStatuses.continuationRecommended,
            publishedSnapshotAvailable: false,
            needsContinuation: true,
            coverageRequiresFollowup: true,
            projectMountStatus:
                ProjectReferenceMountStatuses.snapshotUnavailable,
            projectMountWarningCodes: const <String>[
              'published_snapshot_unavailable',
            ],
            followupSegmentIds: const <String>['segment-2'],
            uncoveredCoverageDimensionIds: const <String>['world_rules'],
          ),
        );

        expect(signal.lifecycleState.runPhase, ContinuousTaskRunPhases.paused);
        expect(
          signal.lifecycleState.stopCategory,
          ContinuousTaskStopCategories.constraintGatePause,
        );
        expect(
          signal.lifecycleState.reason,
          'reference_coverage_followup_required',
        );
        expect(
          ValueReaders.stringValue(
            signal.metadata['supervisor_signal_category'],
          ),
          'coverage_followup',
        );
      },
    );

    test('maps continuation and coverage followup to paused coverage gate', () {
      final signal = service.build(
        _result(
          runStatus:
              ReferenceExtractionRunStatuses.awaitingSemanticContinuation,
          deliveryStatus: ReferenceExtractionDeliveryStatuses.stagingOnly,
          outputCompletionStatus:
              OutputCompletionStatuses.continuationRecommended,
          publishedSnapshotAvailable: false,
          needsContinuation: true,
          coverageRequiresFollowup: true,
          followupSegmentIds: const <String>['segment-2'],
          uncoveredCoverageDimensionIds: const <String>['world_rules'],
        ),
      );

      expect(signal.lifecycleState.runPhase, ContinuousTaskRunPhases.paused);
      expect(
        signal.lifecycleState.stopCategory,
        ContinuousTaskStopCategories.constraintGatePause,
      );
      expect(
        signal.lifecycleState.reason,
        'reference_coverage_followup_required',
      );
      expect(
        ValueReaders.stringValue(signal.metadata['supervisor_signal_category']),
        'coverage_followup',
      );
    });
  });
}

ProjectReferenceExtractionResult _result({
  String runStatus = ReferenceExtractionRunStatuses.completedPublishable,
  String deliveryStatus = ReferenceExtractionDeliveryStatuses.publishable,
  String outputCompletionStatus = OutputCompletionStatuses.completed,
  bool publishedSnapshotAvailable = true,
  bool needsContinuation = false,
  bool coverageRequiresFollowup = false,
  bool attachToProjectRequested = true,
  bool projectMountedEntriesRequested = true,
  String projectMountStatus = ProjectReferenceMountStatuses.applied,
  List<String> projectMountWarningCodes = const <String>[],
  bool requiresManualContinuityReview = false,
  int unresolvedConflictCount = 0,
  int reviewAlertCount = 0,
  List<String> followupSegmentIds = const <String>[],
  List<String> uncoveredCoverageDimensionIds = const <String>[],
}) {
  return ProjectReferenceExtractionResult(
    runId: 'reference_run',
    packageId: 'pkg_hp',
    packageVersionId: 'v1',
    sourceFilePath: 'references/harry.txt',
    sourceDecodeMode: 'utf8',
    groupResolutionKind: 'task_family_override',
    selectedGroupId: 'reference_extraction_group',
    strategyProfileId: 'reference_extraction.standard',
    executionConcurrencyMode: ReferenceExtractionConcurrencyModes.single,
    proposalCount: 4,
    acceptedProposalCount: 4,
    finalizedEntryCount: 4,
    batchCount: 2,
    completedBatchCount: 2,
    runStatus: runStatus,
    deliveryStatus: deliveryStatus,
    outputCompletionStatus: outputCompletionStatus,
    needsContinuation: needsContinuation,
    uncoveredCoverageDimensionIds: uncoveredCoverageDimensionIds,
    followupSegmentIds: followupSegmentIds,
    coverageRequiresFollowup: coverageRequiresFollowup,
    reviewAlertCount: reviewAlertCount,
    requiresManualContinuityReview: requiresManualContinuityReview,
    unresolvedConflictCount: unresolvedConflictCount,
    publishedSnapshotAvailable: publishedSnapshotAvailable,
    attachToProjectRequested: attachToProjectRequested,
    projectMountedEntriesRequested: projectMountedEntriesRequested,
    projectMountStatus: projectMountStatus,
    projectMountWarningCodes: projectMountWarningCodes,
  );
}
