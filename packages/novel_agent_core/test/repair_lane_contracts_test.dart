import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Repair lane contracts', () {
    test('handoff keeps remind and adjust_next as non-blocking non-task actions', () {
      const service = ReviewRepairHandoffService();

      const remindReview = ReviewContract(
        reviewId: 'review-remind',
        reviewType: 'general',
        reviewer: ReviewReviewerRef(
          reviewerId: 'reviewer',
          reviewerRole: 'reviewer',
        ),
        basis: ReviewBasis(
          basisType: 'chapter_delivery',
          sourcePaths: <String>['chapters/ch01.md'],
        ),
        riskLevel: ReviewRiskLevels.low,
        recommendedDisposition: ReviewRecommendedDispositions.remind,
        summary: '记录提醒即可。',
        evidencePaths: <String>['chapters/ch01.md'],
      );
      const adjustReview = ReviewContract(
        reviewId: 'review-adjust',
        reviewType: 'style',
        reviewer: ReviewReviewerRef(
          reviewerId: 'reviewer',
          reviewerRole: 'reviewer',
        ),
        basis: ReviewBasis(
          basisType: 'chapter_delivery',
          sourcePaths: <String>['chapters/ch02.md'],
        ),
        riskLevel: ReviewRiskLevels.medium,
        recommendedDisposition: ReviewRecommendedDispositions.adjustNext,
        summary: '下一章前先收紧风格。',
        evidencePaths: <String>['chapters/ch02.md'],
      );

      final remind = service.handoffFromReview(remindReview);
      final adjust = service.handoffFromReview(adjustReview);

      expect(remind.validateBasics(), isEmpty);
      expect(remind.action, RepairHandoffActions.noteOnly);
      expect(remind.blocksMainFlow, isFalse);
      expect(remind.requiresRepairTask, isFalse);
      expect(remind.repairRequest, isNull);

      expect(adjust.validateBasics(), isEmpty);
      expect(adjust.action, RepairHandoffActions.adjustNext);
      expect(adjust.blocksMainFlow, isFalse);
      expect(adjust.requiresRepairTask, isFalse);
      expect(adjust.repairRequest, isNull);
    });

    test('handoff turns repair disposition into blocking repair request and task', () {
      const service = ReviewRepairHandoffService();
      const review = ReviewContract(
        reviewId: 'review-repair',
        reviewType: 'continuity',
        reviewer: ReviewReviewerRef(
          reviewerId: 'continuity_keeper',
          reviewerRole: 'reviewer',
        ),
        basis: ReviewBasis(
          basisType: 'checkpoint_review',
          sourcePaths: <String>['chapters/ch03.md'],
          targetPaths: <String>['chapters/ch03.md'],
        ),
        findings: <ReviewFindingContract>[
          ReviewFindingContract(
            findingId: 'finding-a',
            severity: ReviewFindingSeverities.blocking,
            summary: '角色状态与前文冲突。',
            evidencePaths: <String>['chapters/ch03.md'],
          ),
          ReviewFindingContract(
            findingId: 'finding-b',
            severity: ReviewFindingSeverities.high,
            summary: '场景衔接缺少前置状态。',
            evidencePaths: <String>['analysis/checkpoint-03.md'],
          ),
        ],
        riskLevel: ReviewRiskLevels.high,
        recommendedDisposition: ReviewRecommendedDispositions.repair,
        repairBrief: '先修复角色状态与场景承接，再恢复主链。',
        summary: '必须先执行修订。',
        evidencePaths: <String>[
          'chapters/ch03.md',
          'reviews/continuity/review-repair.json',
        ],
      );

      final handoff = service.handoffFromReview(review);
      final request = handoff.repairRequest!;
      final task = service.buildRepairTask(request);

      expect(handoff.validateBasics(), isEmpty);
      expect(handoff.action, RepairHandoffActions.createBlockingRepair);
      expect(handoff.blocksMainFlow, isTrue);
      expect(handoff.requiresRepairTask, isTrue);

      expect(request.validateBasics(), isEmpty);
      expect(request.sourceReviewId, 'review-repair');
      expect(request.sourceDisposition, ReviewRecommendedDispositions.repair);
      expect(request.blocksMainFlow, isTrue);
      expect(request.findingIds, <String>['finding-a', 'finding-b']);
      expect(
        request.contextPaths,
        containsAll(<String>[
          'chapters/ch03.md',
          'analysis/checkpoint-03.md',
          'reviews/continuity/review-repair.json',
        ]),
      );

      expect(task.validateBasics(), isEmpty);
      expect(task.requestId, request.requestId);
      expect(task.status, RepairTaskStatuses.queued);
      expect(task.blocksMainFlow, isTrue);
      expect(task.title, contains('continuity'));
      expect(task.goal, contains('先修复角色状态与场景承接'));
    });

    test('handoff maps checkpoint_user and manual_attention to blocking non-task actions', () {
      const service = ReviewRepairHandoffService();

      const waitingReview = ReviewContract(
        reviewId: 'review-waiting',
        reviewType: 'general',
        reviewer: ReviewReviewerRef(
          reviewerId: 'reviewer',
          reviewerRole: 'reviewer',
        ),
        basis: ReviewBasis(
          basisType: 'chapter_delivery',
          sourcePaths: <String>['chapters/ch04.md'],
        ),
        riskLevel: ReviewRiskLevels.high,
        recommendedDisposition: ReviewRecommendedDispositions.checkpointUser,
        summary: '需要用户确认是否接受当前方向。',
        evidencePaths: <String>['chapters/ch04.md'],
      );
      const manualReview = ReviewContract(
        reviewId: 'review-manual',
        reviewType: 'general',
        reviewer: ReviewReviewerRef(
          reviewerId: 'reviewer',
          reviewerRole: 'reviewer',
        ),
        basis: ReviewBasis(
          basisType: 'chapter_delivery',
          sourcePaths: <String>['chapters/ch05.md'],
        ),
        riskLevel: ReviewRiskLevels.critical,
        recommendedDisposition: ReviewRecommendedDispositions.manualAttention,
        summary: '需要人工决定是否回滚前文。',
        evidencePaths: <String>['chapters/ch05.md'],
      );

      final waiting = service.handoffFromReview(waitingReview);
      final manual = service.handoffFromReview(manualReview);

      expect(waiting.validateBasics(), isEmpty);
      expect(waiting.action, RepairHandoffActions.waitingUser);
      expect(waiting.blocksMainFlow, isTrue);
      expect(waiting.requiresRepairTask, isFalse);

      expect(manual.validateBasics(), isEmpty);
      expect(manual.action, RepairHandoffActions.manualAttention);
      expect(manual.blocksMainFlow, isTrue);
      expect(manual.requiresRepairTask, isFalse);
    });

    test('blocking service requires blocking repair to finish before main flow resumes', () {
      const service = RepairLaneBlockingService();
      const request = RepairRequest(
        requestId: 'repair-request-001',
        sourceReviewId: 'review-repair',
        sourceReviewType: 'continuity',
        sourceDisposition: ReviewRecommendedDispositions.repair,
        repairBrief: '先修再继续。',
        findingIds: <String>['finding-a'],
        targetPaths: <String>['chapters/ch03.md'],
        blocksMainFlow: true,
      );

      final pending = service.blockingState(request: request);
      final queued = service.blockingState(
        request: request,
        task: const RepairTask(
          taskId: 'repair-task-001',
          requestId: 'repair-request-001',
          title: '修复任务',
          goal: '修复后再继续',
          status: RepairTaskStatuses.queued,
          blocksMainFlow: true,
        ),
      );
      final waiting = service.blockingState(
        request: request,
        task: const RepairTask(
          taskId: 'repair-task-001',
          requestId: 'repair-request-001',
          title: '修复任务',
          goal: '修复后再继续',
          status: RepairTaskStatuses.waitingUser,
          blocksMainFlow: true,
        ),
      );
      final completed = service.blockingState(
        request: request,
        outcome: const RepairOutcome(
          requestId: 'repair-request-001',
          taskId: 'repair-task-001',
          status: RepairOutcomeStatuses.completed,
          summary: '修复完成。',
        ),
      );

      expect(pending.validateBasics(), isEmpty);
      expect(pending.blocksMainFlow, isTrue);
      expect(pending.reason, 'repair_request_pending_task');
      expect(pending.resolved, isFalse);

      expect(queued.validateBasics(), isEmpty);
      expect(queued.blocksMainFlow, isTrue);
      expect(queued.reason, 'repair_task_queued');
      expect(queued.resolved, isFalse);

      expect(waiting.validateBasics(), isEmpty);
      expect(waiting.blocksMainFlow, isTrue);
      expect(waiting.waitingUser, isTrue);
      expect(waiting.reason, 'repair_task_waiting_user');

      expect(completed.validateBasics(), isEmpty);
      expect(completed.blocksMainFlow, isFalse);
      expect(completed.reason, 'repair_completed');
      expect(completed.resolved, isTrue);
    });

    test('blocking repair cannot be resolved as note_only outcome', () {
      const service = RepairLaneBlockingService();
      const request = RepairRequest(
        requestId: 'repair-request-002',
        sourceReviewId: 'review-repair',
        sourceReviewType: 'style',
        sourceDisposition: ReviewRecommendedDispositions.repair,
        repairBrief: '正文必须重写关键段落。',
        findingIds: <String>['finding-z'],
        targetPaths: <String>['chapters/ch06.md'],
        blocksMainFlow: true,
      );

      final state = service.blockingState(
        request: request,
        outcome: const RepairOutcome(
          requestId: 'repair-request-002',
          status: RepairOutcomeStatuses.noteOnly,
          summary: '只记录提醒，没有真正修复。',
        ),
      );

      expect(state.validateBasics(), isEmpty);
      expect(state.blocksMainFlow, isTrue);
      expect(state.reason, 'blocking_repair_cannot_resolve_as_note_only');
      expect(state.resolved, isFalse);
    });
  });
}
