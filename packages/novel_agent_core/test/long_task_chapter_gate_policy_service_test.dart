import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('LongTaskChapterGatePolicyService', () {
    const service = LongTaskChapterGatePolicyService();

    test('enables gate for chapter collaboration autorun chapter task', () {
      final policy = service.chapterGatePolicy(
        const <String, Object?>{'task_type': 'chapter'},
        options: const <String, Object?>{
          'runtime_baseline_id': 'chapter_collaboration_autorun',
        },
      );

      expect(policy['requires_gate'], isTrue);
      expect(policy['auto_create_review_tasks'], isTrue);
      expect(policy['auto_create_repair_task'], isTrue);
    });

    test('requests repair when review report has issues', () {
      final decision = service.reviewOutcomeDecision(const <String, Object?>{
        'issues': <Object?>[
          <String, Object?>{'title': '连续性问题', 'severity': 'high'},
        ],
        'suggestions': <Object?>[],
      }, runtimeBaselineId: 'chapter_collaboration_autorun');

      expect(decision['action'], 'create_repair_task');
      expect(decision['blocks_auto_advance'], isTrue);
    });

    test('uses waiting user status when gate decision blocks advance', () {
      final nextStatus = service.statusAfterReviewOutcome(
        const <String, Object?>{'disposition': 'blocked_wait_user'},
        TaskRuntimeConstants.statusSucceeded,
      );

      expect(nextStatus, TaskRuntimeConstants.statusWaitingUser);
    });

    test('uses failed status when gate decision requires manual attention', () {
      final nextStatus = service.statusAfterReviewOutcome(
        const <String, Object?>{'disposition': 'manual_attention'},
        TaskRuntimeConstants.statusSucceeded,
      );

      expect(nextStatus, TaskRuntimeConstants.statusFailed);
    });
  });
}
