import '../common/value_readers.dart';
import '../output/output_contract_models.dart';
import 'reference_extraction_delivery_decision.dart';
import 'reference_extraction_reentry_models.dart';
import 'reference_extraction_run_models.dart';
import 'reference_source_batch_models.dart';

class ReferenceExtractionReentryDecisionService {
  const ReferenceExtractionReentryDecisionService();

  ReferenceExtractionReentryDecision decide({
    required ReferenceExtractionStagingRun? existingRun,
    required ReferenceSourceBatchPlan batchPlan,
  }) {
    if (existingRun == null) {
      return const ReferenceExtractionReentryDecision(
        action: ReferenceExtractionReentryActions.startNew,
        nextRunStatus: ReferenceExtractionRunStatuses.active,
        rationale: '没有已有 staging run，启动新一轮 reference extraction。',
      );
    }
    final reviewOutcome = existingRun.reviewOutcome;
    if (reviewOutcome != null) {
      if (existingRun.deliveryDecision.isPublishable) {
        return const ReferenceExtractionReentryDecision(
          action: ReferenceExtractionReentryActions.returnCompleted,
          nextRunStatus: ReferenceExtractionRunStatuses.completedPublishable,
          rationale: '已有 publishable completed 结果，可安全短路返回。',
        );
      }
      final continuationContext = _buildContinuationContext(
        existingRun,
        batchPlan: batchPlan,
      );
      return ReferenceExtractionReentryDecision(
        action: ReferenceExtractionReentryActions.resumeSemantic,
        nextRunStatus:
            ReferenceExtractionRunStatuses.semanticContinuationInProgress,
        rationale: '已有语义不完整结果，进入 semantic continuation 续提轮次。',
        targetBatchIds: continuationContext.targetBatchIds,
        continuationContext: continuationContext,
      );
    }
    final technicalResumeBatchIds = batchPlan.batches
        .where(
          (batch) =>
              !_isCompletedBatch(existingRun.batchProgress, batch.batchId),
        )
        .map((batch) => batch.batchId)
        .toList(growable: false);
    if (technicalResumeBatchIds.isNotEmpty) {
      return ReferenceExtractionReentryDecision(
        action: ReferenceExtractionReentryActions.resumeTechnical,
        nextRunStatus: ReferenceExtractionRunStatuses.active,
        rationale: '已有技术中断 staging run，继续未完成或失败的 batch。',
        targetBatchIds: technicalResumeBatchIds,
      );
    }
    return const ReferenceExtractionReentryDecision(
      action: ReferenceExtractionReentryActions.startNew,
      nextRunStatus: ReferenceExtractionRunStatuses.active,
      rationale: '已有 run 无 reviewOutcome 且无可恢复 batch，按新轮次处理。',
    );
  }

  ReferenceExtractionContinuationContext _buildContinuationContext(
    ReferenceExtractionStagingRun run, {
    required ReferenceSourceBatchPlan batchPlan,
  }) {
    final focusDimensionIds = <String>{
      for (final request in run.continuationRequests)
        if (request.isActionable)
        ...request.missingDimensionIds
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty),
      for (final report in run.omissionReports)
        if (report.isActionable)
        ...report.omittedDimensionIds
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty),
    }.toList(growable: false);
    final targetBatchIds = _resolveTargetBatchIds(
      run,
      batchPlan: batchPlan,
      focusDimensionIds: focusDimensionIds,
    );
    final recommendedNextFocus = <String>{
      for (final request in run.continuationRequests)
        if (request.isActionable)
        request.recommendedNextFocus.trim(),
      for (final report in run.omissionReports)
        if (report.isActionable)
        report.recommendedNextFocus.trim(),
    }.where((item) => item.isNotEmpty).join(' / ');
    return ReferenceExtractionContinuationContext(
      roundIndex: run.continuationContexts.length + 1,
      targetBatchIds: targetBatchIds,
      focusDimensionIds: focusDimensionIds,
      recommendedNextFocus: recommendedNextFocus,
      sourceContinuationRequestIds: run.continuationRequests
          .map((item) => item.requestId)
          .toList(growable: false),
      sourceOmissionReportIds: run.omissionReports
          .map((item) => item.reportId)
          .toList(growable: false),
      metadata: <String, Object?>{
        'previous_output_completion_status': run.outputCompletionStatus,
        'previous_delivery_status': run.deliveryDecision.deliveryStatus,
      },
    );
  }

  List<String> _resolveTargetBatchIds(
    ReferenceExtractionStagingRun run, {
    required ReferenceSourceBatchPlan batchPlan,
    required List<String> focusDimensionIds,
  }) {
    final resolved = <String>{};
    for (final request in run.continuationRequests) {
      if (!request.isActionable) {
        continue;
      }
      final batchId = ValueReaders.stringValue(
        request.metadata['batch_id'],
      ).trim();
      if (batchId.isNotEmpty) {
        resolved.add(batchId);
      }
    }
    for (final report in run.omissionReports) {
      if (!report.isActionable) {
        continue;
      }
      final batchId = ValueReaders.stringValue(
        report.metadata['batch_id'],
      ).trim();
      if (batchId.isNotEmpty) {
        resolved.add(batchId);
      }
    }
    if (resolved.isEmpty && focusDimensionIds.isNotEmpty) {
      for (final proposal in run.proposals) {
        final batchId = ValueReaders.stringValue(
          proposal.metadata['batch_id'],
        ).trim();
        if (batchId.isEmpty) {
          continue;
        }
        if (proposal.coverageDimensionIds.any(focusDimensionIds.contains)) {
          resolved.add(batchId);
        }
      }
    }
    if (resolved.isEmpty) {
      for (final proposal in run.proposals) {
        final batchId = ValueReaders.stringValue(
          proposal.metadata['batch_id'],
        ).trim();
        if (batchId.isNotEmpty) {
          resolved.add(batchId);
        }
      }
    }
    if (resolved.isEmpty) {
      resolved.addAll(batchPlan.batches.map((batch) => batch.batchId));
    }
    final validBatchIds = batchPlan.batches
        .map((batch) => batch.batchId)
        .where(resolved.contains)
        .toList(growable: false);
    return validBatchIds.isEmpty
        ? batchPlan.batches
              .map((batch) => batch.batchId)
              .toList(growable: false)
        : validBatchIds;
  }

  String resolvePostRunStatus({
    required ReferenceExtractionDeliveryDecision deliveryDecision,
  }) {
    if (deliveryDecision.deliveryStatus ==
        ReferenceExtractionDeliveryStatuses.publishable) {
      return ReferenceExtractionRunStatuses.completedPublishable;
    }
    if (deliveryDecision.outputCompletionStatus ==
            OutputCompletionStatuses.continuationRecommended ||
        deliveryDecision.outputCompletionStatus ==
            OutputCompletionStatuses.coverageInsufficient ||
        deliveryDecision.outputCompletionStatus ==
            OutputCompletionStatuses.compressed) {
      return ReferenceExtractionRunStatuses.awaitingSemanticContinuation;
    }
    return ReferenceExtractionRunStatuses.active;
  }

  bool _isCompletedBatch(
    ReferenceSourceBatchProgress? progress,
    String batchId,
  ) {
    if (progress == null) {
      return false;
    }
    return progress.items.any(
      (item) =>
          item.batchId == batchId &&
          item.status == ReferenceSourceBatchStatuses.completed,
    );
  }
}
