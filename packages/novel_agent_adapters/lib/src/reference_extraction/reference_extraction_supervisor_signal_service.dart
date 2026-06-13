import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_reference_extraction_runtime_models.dart';

class ReferenceExtractionSupervisorSignal {
  const ReferenceExtractionSupervisorSignal({
    required this.lifecycleState,
    this.metadata = const <String, Object?>{},
  });

  final ContinuousTaskLifecycleState lifecycleState;
  final JsonMap metadata;
}

class ReferenceExtractionSupervisorSignalService {
  const ReferenceExtractionSupervisorSignalService();

  ReferenceExtractionSupervisorSignal build(
    ProjectReferenceExtractionResult result,
  ) {
    final lifecycleState = _lifecycleStateFromResult(result);
    return ReferenceExtractionSupervisorSignal(
      lifecycleState: lifecycleState,
      metadata: <String, Object?>{
        'package_id': result.packageId,
        'package_version_id': result.packageVersionId,
        'source_file_path': result.sourceFilePath,
        'source_decode_mode': result.sourceDecodeMode,
        'group_resolution_kind': result.groupResolutionKind,
        'selected_group_id': result.selectedGroupId,
        'strategy_profile_id': result.strategyProfileId,
        'execution_concurrency_mode': result.executionConcurrencyMode,
        'execution_max_concurrent_batches':
            result.executionMaxConcurrentBatches,
        'allow_parallel_heavy_text_consumption':
            result.allowParallelHeavyTextConsumption,
        'delivery_status': result.deliveryStatus,
        'run_status': result.runStatus,
        'output_completion_status': result.outputCompletionStatus,
        'published_snapshot_available': result.publishedSnapshotAvailable,
        'batch_count': result.batchCount,
        'completed_batch_count': result.completedBatchCount,
        'failed_batch_count': result.failedBatchCount,
        'pending_batch_count': result.pendingBatchCount,
        'covered_coverage_dimension_ids': List<String>.from(
          result.coveredCoverageDimensionIds,
        ),
        'uncovered_coverage_dimension_ids': List<String>.from(
          result.uncoveredCoverageDimensionIds,
        ),
        'followup_segment_ids': List<String>.from(result.followupSegmentIds),
        'coverage_requires_followup': result.coverageRequiresFollowup,
        'project_mount_status': result.projectMountStatus,
        'project_mount_warning_codes': List<String>.from(
          result.projectMountWarningCodes,
        ),
        'attach_to_project_requested': result.attachToProjectRequested,
        'project_mounted_entries_requested':
            result.projectMountedEntriesRequested,
        'conflict_cluster_count': result.conflictClusterCount,
        'canon_decision_count': result.canonDecisionCount,
        'review_alert_count': result.reviewAlertCount,
        'requires_manual_continuity_review':
            result.requiresManualContinuityReview,
        'unresolved_conflict_count': result.unresolvedConflictCount,
        'supervisor_signal_category': _signalCategory(result),
      },
    );
  }

  ContinuousTaskLifecycleState _lifecycleStateFromResult(
    ProjectReferenceExtractionResult result,
  ) {
    if (_requiresMountConfirmation(result)) {
      return ContinuousTaskLifecycleState(
        runPhase: ContinuousTaskRunPhases.waitingUser,
        stopCategory: ContinuousTaskStopCategories.waitingUser,
        reason: 'reference_mount_confirmation_required',
        metadata: <String, Object?>{
          'project_mount_status': result.projectMountStatus,
          'project_mount_warning_codes': List<String>.from(
            result.projectMountWarningCodes,
          ),
        },
      );
    }
    if (_requiresContinuityDecision(result)) {
      return ContinuousTaskLifecycleState(
        runPhase: ContinuousTaskRunPhases.manualAttention,
        stopCategory: ContinuousTaskStopCategories.manualAttention,
        reason: 'reference_continuity_conflict_requires_review',
        metadata: <String, Object?>{
          'conflict_cluster_count': result.conflictClusterCount,
          'canon_decision_count': result.canonDecisionCount,
          'review_alert_count': result.reviewAlertCount,
          'requires_manual_continuity_review':
              result.requiresManualContinuityReview,
          'unresolved_conflict_count': result.unresolvedConflictCount,
        },
      );
    }
    if (_requiresMountRepair(result)) {
      return ContinuousTaskLifecycleState(
        runPhase: ContinuousTaskRunPhases.paused,
        stopCategory: ContinuousTaskStopCategories.constraintGatePause,
        reason: 'reference_mount_incomplete',
        metadata: <String, Object?>{
          'project_mount_status': result.projectMountStatus,
          'project_mount_warning_codes': List<String>.from(
            result.projectMountWarningCodes,
          ),
        },
      );
    }
    if (result.runStatus ==
            ReferenceExtractionRunStatuses.completedPublishable &&
        result.publishedSnapshotAvailable) {
      return const ContinuousTaskLifecycleState(
        runPhase: ContinuousTaskRunPhases.stopped,
        terminalDisposition: ContinuousTaskTerminalDispositions.completed,
        stopCategory: ContinuousTaskStopCategories.completedNaturally,
        reason: 'completed_publishable',
      );
    }
    if (result.needsContinuation || result.coverageRequiresFollowup) {
      return ContinuousTaskLifecycleState(
        runPhase: ContinuousTaskRunPhases.paused,
        stopCategory: ContinuousTaskStopCategories.constraintGatePause,
        reason: 'reference_coverage_followup_required',
        metadata: <String, Object?>{
          'coverage_requires_followup': result.coverageRequiresFollowup,
          'followup_segment_ids': List<String>.from(result.followupSegmentIds),
          'uncovered_coverage_dimension_ids': List<String>.from(
            result.uncoveredCoverageDimensionIds,
          ),
        },
      );
    }
    return ContinuousTaskLifecycleState(
      runPhase: ContinuousTaskRunPhases.manualAttention,
      stopCategory: ContinuousTaskStopCategories.manualAttention,
      reason: result.runStatus,
    );
  }

  bool _requiresMountConfirmation(ProjectReferenceExtractionResult result) {
    return result.projectMountedEntriesRequested &&
        result.projectMountStatus == ProjectReferenceMountStatuses.denied &&
        result.projectMountWarningCodes.contains(
          'explicit_confirmation_required',
        );
  }

  bool _requiresContinuityDecision(ProjectReferenceExtractionResult result) {
    return result.requiresManualContinuityReview ||
        result.unresolvedConflictCount > 0;
  }

  bool _requiresMountRepair(ProjectReferenceExtractionResult result) {
    if (!result.projectMountedEntriesRequested) {
      return false;
    }
    if (result.projectMountStatus ==
        ProjectReferenceMountStatuses.snapshotUnavailable) {
      return false;
    }
    return result.projectMountStatus != ProjectReferenceMountStatuses.applied &&
        !_requiresMountConfirmation(result);
  }

  String _signalCategory(ProjectReferenceExtractionResult result) {
    if (_requiresMountConfirmation(result)) {
      return 'mount_waiting_user';
    }
    if (_requiresContinuityDecision(result)) {
      return 'continuity_conflict';
    }
    if (_requiresMountRepair(result)) {
      return 'mount_incomplete';
    }
    if (result.runStatus ==
            ReferenceExtractionRunStatuses.completedPublishable &&
        result.publishedSnapshotAvailable) {
      return 'completed';
    }
    if (result.needsContinuation || result.coverageRequiresFollowup) {
      return 'coverage_followup';
    }
    return 'manual_attention_fallback';
  }
}
