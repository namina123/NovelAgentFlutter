import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectReviewRepairTaskContractService', () {
    final service = ProjectReviewRepairTaskContractService();

    test('builds workflow revision task from shared review handoff', () {
      final reviewContract = ReviewContract(
        reviewId: 'review-001',
        reviewType: ReviewTypeConstants.general,
        reviewer: const ReviewReviewerRef(
          reviewerId: 'reviewer-agent',
          reviewerRole: 'critic',
        ),
        basis: const ReviewBasis(
          basisType: 'semantic_review',
          summary: '第01章',
          sourcePaths: <String>['chapters/ch01.md', 'outline/总纲.md'],
          targetPaths: <String>['chapters/ch01.md'],
        ),
        findings: const <ReviewFindingContract>[
          ReviewFindingContract(
            findingId: 'finding-1',
            severity: ReviewFindingSeverities.blocking,
            summary: '结尾冲突没有兑现。',
            suggestedAction: '重写结尾段落并补足冲突兑现。',
            evidencePaths: <String>['chapters/ch01.md'],
          ),
        ],
        riskLevel: ReviewRiskLevels.critical,
        recommendedDisposition: ReviewRecommendedDispositions.repair,
        repairBrief: '重写结尾并统一冲突兑现。',
        summary: '当前章节需要先返修。',
        evidencePaths: const <String>['chapters/ch01.md'],
        createdAt: '2026-06-09T10:00:00Z',
      );
      final handoff = const ReviewRepairHandoffService().handoffFromReview(
        reviewContract,
      );

      final task = service.buildWorkflowRevisionTask(
        reviewContract: reviewContract,
        repairHandoff: handoff,
        reviewReportPath: 'reviews/general/ch01.json',
        workflowMode: TaskRuntimeConstants.modeSeedToFullNovel,
        sourceTaskMetadata: const <String, Object?>{
          'runtime_baseline_id': 'chapter_collaboration_autorun',
          'persistent_context_paths': <Object?>['styles/default.md'],
          'checkpoint_review_path':
              'tracking/checkpoint_reviews/review-001.json',
        },
        sourceTaskId: 'review_task_001',
        sourceTaskPath: 'tasks/review_task_001.json',
      );

      expect(ValueReaders.stringValue(task['task_type']), 'revision');
      expect(
        ValueReaders.stringValue(
          ValueReaders.mapValue(task['metadata'])['origin'],
        ),
        'review_repair_handoff',
      );
      expect(
        ValueReaders.stringValue(
          ValueReaders.mapValue(task['metadata'])['review_id'],
        ),
        'review-001',
      );
      expect(
        ValueReaders.stringValue(
          ValueReaders.mapValue(
            ValueReaders.mapValue(task['metadata'])['review_repair_handoff'],
          )['action'],
        ),
        RepairHandoffActions.createBlockingRepair,
      );
      expect(
        ValueReaders.stringList(task['source_paths']),
        containsAll(<String>[
          'chapters/ch01.md',
          'reviews/general/ch01.md',
          'reviews/general/ch01.json',
        ]),
      );
    });
  });
}
