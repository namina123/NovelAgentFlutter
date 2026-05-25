import 'package:flutter_test/flutter_test.dart';

import 'package:novel_agent_app/features/task_center/application/services/task_center_contract_action_view_data_service.dart';

void main() {
  group('TaskCenterContractActionViewDataService', () {
    test('checkpoint group only enables materialized host actions', () {
      // 中文注释: 检查点动作里只有已接宿主链的动作才允许点击，其余建议仍需展示但不可误触。
      final service = TaskCenterContractActionViewDataService();

      final groups = service.buildGroups(
        checkpointActionPackage: const <String, Object?>{
          'ok': true,
          'checkpoint_review_path': 'tracking/checkpoint_reviews/c1.json',
          'severity_label': '高风险',
          'recommended_action_id': 'create_followup_review_tasks',
          'action_summary': '建议动作：生成后续审稿、继续主链',
          'review': <String, Object?>{
            'task': <String, Object?>{'relative_path': 'tasks/ch01.task.json'},
          },
          'actions': <Object?>[
            <String, Object?>{
              'id': 'create_followup_review_tasks',
              'label': '生成后续审稿',
              'enabled': true,
              'tone': 'accent',
              'note': '物化 follow-up review。',
              'disabled_reason': '',
              'host_command': 'apply_checkpoint_review_action',
            },
            <String, Object?>{
              'id': 'continue_long_task',
              'label': '继续主链',
              'enabled': true,
              'tone': 'success',
              'note': '继续推进。',
              'disabled_reason': '',
              'host_command': 'user_decision',
            },
          ],
        },
      );

      expect(groups, hasLength(1));
      final group = groups.single;
      expect(group.title, contains('高风险'));
      expect(group.actions.first.enabled, isTrue);
      expect(group.actions.first.isRecommended, isTrue);
      expect(group.actions.last.enabled, isFalse);
      expect(group.actions.last.disabledReason, contains('图形界面还未接通'));
    });

    test('revision group keeps shared closure actions clickable', () {
      // 中文注释: 修订收口动作已经共享物化，GUI 侧应原样开放点击。
      final service = TaskCenterContractActionViewDataService();

      final groups = service.buildGroups(
        revisionResolution: const <String, Object?>{
          'ok': true,
          'stage_label': '等待收口',
          'action_summary': '可用收口动作：接受修复、回滚修复',
          'checkpoint_review_path': 'tracking/checkpoint_reviews/revision.json',
          'task': <String, Object?>{
            'relative_path': 'tasks/revision_01.task.json',
          },
          'actions': <Object?>[
            <String, Object?>{
              'id': 'accept_revision',
              'label': '接受修复',
              'enabled': true,
              'tone': 'success',
              'note': '确认修订结果。',
              'disabled_reason': '',
              'host_command': 'apply_revision_resolution_action',
            },
          ],
        },
      );

      expect(groups, hasLength(1));
      final action = groups.single.actions.single;
      expect(action.enabled, isTrue);
      expect(action.ownerTaskPath, 'tasks/revision_01.task.json');
      expect(
        action.checkpointReviewPath,
        'tracking/checkpoint_reviews/revision.json',
      );
    });
  });
}
