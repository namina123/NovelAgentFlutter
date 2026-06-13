import 'repair_contract_catalog.dart';
import 'repair_handoff_decision.dart';
import 'repair_request.dart';
import 'repair_task.dart';
import 'review_contract.dart';
import 'review_contract_catalog.dart';

class ReviewRepairHandoffService {
  const ReviewRepairHandoffService();

  RepairHandoffDecision handoffFromReview(ReviewContract review) {
    switch (review.recommendedDisposition) {
      case ReviewRecommendedDispositions.accept:
        return const RepairHandoffDecision(
          action: RepairHandoffActions.none,
          reason: 'review_accepts_without_repair',
        );
      case ReviewRecommendedDispositions.remind:
        return RepairHandoffDecision(
          action: RepairHandoffActions.noteOnly,
          reason: 'review_requests_note_only',
          note: review.summary,
          metadata: review.metadata,
        );
      case ReviewRecommendedDispositions.adjustNext:
        return RepairHandoffDecision(
          action: RepairHandoffActions.adjustNext,
          reason: 'review_requests_adjust_next',
          note: review.summary,
          metadata: review.metadata,
        );
      case ReviewRecommendedDispositions.checkpointUser:
        return RepairHandoffDecision(
          action: RepairHandoffActions.waitingUser,
          reason: 'review_requests_user_checkpoint',
          blocksMainFlow: true,
          note: review.summary,
          metadata: review.metadata,
        );
      case ReviewRecommendedDispositions.manualAttention:
        return RepairHandoffDecision(
          action: RepairHandoffActions.manualAttention,
          reason: 'review_requests_manual_attention',
          blocksMainFlow: true,
          note: review.summary,
          metadata: review.metadata,
        );
      case ReviewRecommendedDispositions.repair:
        final request = _requestFromReview(review);
        return RepairHandoffDecision(
          action: RepairHandoffActions.createBlockingRepair,
          reason: 'review_requests_blocking_repair',
          blocksMainFlow: true,
          requiresRepairTask: true,
          note: review.summary,
          repairRequest: request,
          metadata: review.metadata,
        );
    }
    return const RepairHandoffDecision(
      action: RepairHandoffActions.none,
      reason: 'review_disposition_unrecognized',
    );
  }

  RepairTask buildRepairTask(RepairRequest request) {
    final titleReviewType = request.sourceReviewType.trim().isEmpty
        ? 'review'
        : request.sourceReviewType;
    final firstTarget = request.targetPaths.isEmpty ? '' : request.targetPaths.first;
    final goalLines = <String>[
      '根据审稿结论执行正式修复，优先完成阻塞问题后再恢复主链。',
      '修复说明：${request.repairBrief}',
    ];
    if (request.findingIds.isNotEmpty) {
      goalLines.add('优先处理 findings：${request.findingIds.join('、')}');
    }
    return RepairTask(
      taskId: 'repair_task_${request.requestId}',
      requestId: request.requestId,
      title: '修复审稿问题：$titleReviewType/${request.sourceReviewId}',
      goal: goalLines.join('\n'),
      targetPaths: request.targetPaths,
      contextPaths: request.contextPaths,
      status: RepairTaskStatuses.queued,
      blocksMainFlow: request.blocksMainFlow,
      metadata: <String, Object?>{
        ...request.metadata,
        'origin': 'review_repair_handoff',
        'source_review_id': request.sourceReviewId,
        'source_review_type': request.sourceReviewType,
        if (firstTarget.isNotEmpty) 'primary_target_path': firstTarget,
      },
    );
  }

  RepairRequest _requestFromReview(ReviewContract review) {
    final targetPaths = <String>[];
    final contextPaths = <String>[];
    final evidencePaths = <String>[];
    _appendUnique(targetPaths, review.basis.targetPaths);
    _appendUnique(targetPaths, review.basis.sourcePaths);
    _appendUnique(contextPaths, review.basis.sourcePaths);
    _appendUnique(contextPaths, review.basis.targetPaths);
    _appendUnique(contextPaths, review.evidencePaths);
    _appendUnique(evidencePaths, review.evidencePaths);
    final findingIds = <String>[];
    for (final finding in review.findings) {
      if (finding.findingId.trim().isNotEmpty) {
        findingIds.add(finding.findingId);
      }
      _appendUnique(contextPaths, finding.evidencePaths);
      _appendUnique(evidencePaths, finding.evidencePaths);
    }
    return RepairRequest(
      requestId: 'repair_request_${review.reviewId}',
      sourceReviewId: review.reviewId,
      sourceReviewType: review.reviewType,
      sourceDisposition: review.recommendedDisposition,
      repairBrief: review.repairBrief,
      findingIds: findingIds,
      targetPaths: targetPaths,
      contextPaths: contextPaths,
      evidencePaths: evidencePaths,
      blocksMainFlow: true,
      metadata: review.metadata,
    );
  }

  void _appendUnique(List<String> target, List<String> values) {
    for (final value in values) {
      final clean = value.trim();
      if (clean.isNotEmpty && !target.contains(clean)) {
        target.add(clean);
      }
    }
  }
}
