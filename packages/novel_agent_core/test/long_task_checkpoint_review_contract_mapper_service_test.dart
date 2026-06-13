import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('LongTaskCheckpointReviewContractMapperService', () {
    const service = LongTaskCheckpointReviewContractMapperService();

    test('maps medium checkpoint followup review into shared review contract', () {
      final review = service.mapReview(
        checkpointReview: const <String, Object?>{
          'id': 'checkpoint_review_medium_1',
          'kind': 'long_task_checkpoint_review',
          'created_at': '2026-06-07T10:00:00Z',
          'summary': '当前节点建议先过一轮补充审视，再决定是否继续推进。',
          'severity': 'medium',
          'severity_reasons': <Object?>['文风与连续性都有轻度漂移信号。'],
          'task': <String, Object?>{
            'id': 'chapter_001',
            'title': '样章：第01章',
            'task_type': 'chapter',
          },
          'task_type': 'chapter',
          'stage': 'sample',
          'output_paths': <Object?>['chapters/ch01.md'],
          'persistent_context_paths': <Object?>['styles/default.md'],
          'changed_paths': <Object?>['chapters/ch01.md'],
          'json_path': 'tracking/checkpoint_reviews/chapter_001.json',
          'markdown_path': 'tracking/checkpoint_reviews/chapter_001.md',
          'disposition': <String, Object?>{
            'disposition': 'blocked_wait_user',
            'reason': 'medium_risk_needs_review',
            'create_followup_review_tasks': true,
            'request_revision_followup': false,
          },
          'continuation_disposition': 'blocked_wait_user',
          'information_signal': <String, Object?>{
            'present': false,
            'category': 'accept',
          },
          'collaboration_signal': <String, Object?>{
            'present': false,
            'category': 'accept',
          },
          'expression_constraint_signal': <String, Object?>{
            'present': false,
            'category': 'suggest_strengthen',
          },
        },
      );

      expect(review.reviewId, 'checkpoint_review_medium_1');
      expect(review.riskLevel, ReviewRiskLevels.medium);
      expect(
        review.recommendedDisposition,
        ReviewRecommendedDispositions.adjustNext,
      );
      expect(
        review.metadata['followup_review_required'],
        isTrue,
      );
      expect(
        review.metadata['revision_followup_required'],
        isFalse,
      );
      expect(
        ValueReaders.stringValue(
          ValueReaders.mapValue(review.metadata['review_authority_policy'])['trigger_authority'],
        ),
        ReviewTriggerAuthorities.runtimeSupervisorPolicy,
      );
      expect(review.evidencePaths, contains('tracking/checkpoint_reviews/chapter_001.json'));
    });

    test('maps repair-oriented checkpoint review into blocking repair contract', () {
      final review = service.mapReview(
        checkpointReview: const <String, Object?>{
          'id': 'checkpoint_review_repair_1',
          'kind': 'long_task_checkpoint_review',
          'summary': 'required 信息省略 1 项，建议先补上下文。',
          'severity': 'high',
          'task': <String, Object?>{
            'id': 'chapter_002',
            'title': '正文：第02章',
            'task_type': 'chapter',
          },
          'task_type': 'chapter',
          'output_paths': <Object?>['chapters/ch02.md'],
          'information_changed_paths': <Object?>[
            '.novel_agent/information/research_requests/request_001.json',
          ],
          'disposition': <String, Object?>{
            'disposition': 'blocked_wait_user',
            'reason': 'narrative_repair_required',
            'create_followup_review_tasks': false,
            'request_revision_followup': true,
          },
          'continuation_disposition': 'blocked_wait_user',
          'information_signal': <String, Object?>{
            'present': true,
            'category': 'repair',
            'summary': 'required 信息省略 1 项，建议先补上下文。',
          },
          'collaboration_signal': <String, Object?>{
            'present': false,
            'category': 'accept',
          },
          'expression_constraint_signal': <String, Object?>{
            'present': false,
            'category': 'accept',
            'repair_required': false,
          },
        },
      );
      final handoff = const ReviewRepairHandoffService().handoffFromReview(review);

      expect(review.riskLevel, ReviewRiskLevels.high);
      expect(review.recommendedDisposition, ReviewRecommendedDispositions.repair);
      expect(review.repairBrief, contains('建议先补上下文'));
      expect(handoff.action, RepairHandoffActions.createBlockingRepair);
      expect(handoff.blocksMainFlow, isTrue);
      expect(
        handoff.repairRequest?.evidencePaths,
        contains('.novel_agent/information/research_requests/request_001.json'),
      );
    });
  });
}
