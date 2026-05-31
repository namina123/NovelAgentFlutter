import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('LongTaskCheckpointSeverityService and action contract', () {
    final severityService = LongTaskCheckpointSeverityService();
    final actionService = LongTaskCheckpointActionContractService();

    test(
      'marks sample chapter checkpoint as high and suggests followup review',
      () {
        final review = <String, Object?>{
          'task': <String, Object?>{
            'id': 'chapter_001',
            'relative_path': 'tasks/chapter_001.json',
          },
          'task_type': 'chapter',
          'stage': 'sample',
          'result_ok': true,
          'output_paths': <Object?>['chapters/ch01.md'],
          'confirmation_focus': <Object?>['样章入口是否成立。', '主角体验是否成立。'],
          'drift_watch_items': <Object?>[
            '检查文风是否漂移。',
            '检查世界规则是否漂移。',
            '检查角色动机是否漂移。',
          ],
          'persistent_context_paths': <Object?>[
            'tracking/modes/seed_autopilot_novel/guidance.md',
          ],
        };

        final severity = severityService.assess(review);
        expect(ValueReaders.stringValue(severity['severity']), 'high');

        final package = actionService.buildPackage(
          <String, Object?>{...review, 'severity': severity['severity']},
          checkpointReviewPath: 'tracking/checkpoint_reviews/chapter_001.json',
        );
        final actions = ValueReaders.mapList(package['actions']);
        final disposition = ValueReaders.mapValue(package['disposition']);
        expect(
          actions.any(
            (item) =>
                ValueReaders.stringValue(item['id']) ==
                    'create_followup_review_tasks' &&
                !ValueReaders.boolValue(item['enabled']),
          ),
          isTrue,
        );
        expect(
          ValueReaders.stringValue(disposition['disposition']),
          'blocked_wait_user',
        );
        expect(
          ValueReaders.stringValue(package['recommended_action_id']),
          'request_revision_followup',
        );
        expect(
          actions.any(
            (item) =>
                ValueReaders.stringValue(item['id']) == 'continue_long_task' &&
                ValueReaders.boolValue(item['enabled']) &&
                ValueReaders.stringValue(item['host_command']) ==
                    'apply_checkpoint_review_action',
          ),
          isTrue,
        );
        expect(
          actions.any(
            (item) =>
                ValueReaders.stringValue(item['id']) ==
                    'request_revision_followup' &&
                ValueReaders.stringValue(item['host_command']) ==
                    'apply_checkpoint_review_action',
          ),
          isTrue,
        );
        expect(
          actions.any(
            (item) =>
                ValueReaders.stringValue(item['id']) ==
                    'revisit_mode_guidance' &&
                ValueReaders.stringValue(item['host_command']) ==
                    'apply_checkpoint_review_action',
          ),
          isTrue,
        );
      },
    );

    test(
      'enables continue and confirm checkpoint actions on low risk review',
      () {
        final review = <String, Object?>{
          'task': <String, Object?>{
            'id': 'checkpoint_001',
            'relative_path': 'tasks/checkpoint_001.json',
          },
          'task_type': 'checkpoint',
          'stage': 'checkpoint',
          'result_ok': true,
          'severity': 'low',
          'severity_label': '低风险',
          'output_paths': <Object?>['tracking/checkpoints/ch01.md'],
          'confirmation_focus': <Object?>['确认当前检查点可以继续。'],
          'drift_watch_items': const <Object?>[],
          'persistent_context_paths': const <Object?>[],
        };

        final package = actionService.buildPackage(
          review,
          checkpointReviewPath:
              'tracking/checkpoint_reviews/checkpoint_001.json',
        );
        final actions = ValueReaders.mapList(package['actions']);
        final disposition = ValueReaders.mapValue(package['disposition']);

        expect(
          actions.any(
            (item) =>
                ValueReaders.stringValue(item['id']) == 'continue_long_task' &&
                ValueReaders.boolValue(item['enabled']),
          ),
          isTrue,
        );
        expect(
          actions.any(
            (item) =>
                ValueReaders.stringValue(item['id']) ==
                    'confirm_checkpoint_continue' &&
                ValueReaders.boolValue(item['enabled']) &&
                ValueReaders.stringValue(item['host_command']) ==
                    'apply_checkpoint_review_action',
          ),
          isTrue,
        );
        expect(
          ValueReaders.stringValue(disposition['disposition']),
          'auto_continue',
        );
      },
    );

    test('marks failed checkpoint as critical', () {
      final severity = severityService.assess(<String, Object?>{
        'task_type': 'planning',
        'result_ok': false,
        'error': '模型失败',
        'output_paths': const <Object?>[],
        'drift_watch_items': const <Object?>[],
        'confirmation_focus': const <Object?>[],
        'tool_names': const <Object?>[],
      });

      expect(ValueReaders.stringValue(severity['severity']), 'critical');
      expect(ValueReaders.stringList(severity['reasons']), isNotEmpty);
    });
  });
}
