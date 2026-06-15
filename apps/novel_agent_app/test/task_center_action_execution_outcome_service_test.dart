import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/task_center/application/services/task_center_action_execution_outcome_service.dart';
import 'package:novel_agent_app/features/task_center/presentation/models/task_center_contract_action_view_data.dart';

void main() {
  group('TaskCenterActionExecutionOutcomeService', () {
    const service = TaskCenterActionExecutionOutcomeService();

    test('selects first created follow-up review task', () {
      // 中文注释: 生成后续审稿后应直接跳到第一条新任务，减少用户再手动查找。
      final outcome = service.resolve(
        action: _action(
          id: 'create_followup_review_tasks',
          ownerTaskPath: 'tasks/chapter_01.task.json',
        ),
        result: const <String, Object?>{
          'ok': true,
          'tasks': <Object?>[
            <String, Object?>{'relative_path': 'tasks/review_01.task.json'},
            <String, Object?>{'relative_path': 'tasks/review_02.task.json'},
          ],
        },
        defaultSuccessMessage: '已完成。',
        currentSelectedTaskId: 'tasks/chapter_01.task.json',
      );

      expect(outcome.nextSelectedTaskId, 'tasks/review_01.task.json');
      expect(outcome.statusMessage, '已生成后续审稿任务 2 项。');
    });

    test(
      'revision follow-up prefers created task and reports related count',
      () {
        // 中文注释: 建议返工后既要跳到新任务，也要把“新建”和“关联”数量讲清楚。
        final outcome = service.resolve(
          action: _action(
            id: 'request_revision_followup',
            ownerTaskPath: 'tasks/planning.task.json',
          ),
          result: const <String, Object?>{
            'ok': true,
            'review_tasks': <Object?>[
              <String, Object?>{'relative_path': 'tasks/review_01.task.json'},
              <String, Object?>{'relative_path': 'tasks/review_02.task.json'},
              <String, Object?>{'relative_path': 'tasks/review_03.task.json'},
            ],
            'created_tasks': <Object?>[
              <String, Object?>{'relative_path': 'tasks/review_03.task.json'},
            ],
            'task': <String, Object?>{
              'relative_path': 'tasks/planning.task.json',
            },
          },
          defaultSuccessMessage: '已完成。',
          currentSelectedTaskId: 'tasks/planning.task.json',
        );

        expect(outcome.nextSelectedTaskId, 'tasks/review_03.task.json');
        expect(outcome.statusMessage, '已请求返工，并关联 3 个审稿任务（新建 1 项）。');
      },
    );

    test('rollback keeps warning and reports restored file count', () {
      // 中文注释: 回滚类动作既要回显恢复数量，也要把部分失败的 warning 保留下来。
      final outcome = service.resolve(
        action: _action(
          id: 'rollback_revision',
          ownerTaskPath: 'tasks/revision_01.task.json',
        ),
        result: const <String, Object?>{
          'ok': true,
          'relative_path': 'tasks/revision_01.task.json',
          'warning': '部分或全部目标回滚失败。',
          'rollback': <String, Object?>{
            'restored_paths': <Object?>['chapters/ch01.md', 'chapters/ch02.md'],
          },
        },
        defaultSuccessMessage: '已完成。',
        currentSelectedTaskId: 'tasks/revision_01.task.json',
      );

      expect(outcome.nextSelectedTaskId, 'tasks/revision_01.task.json');
      expect(outcome.statusMessage, '已回滚修复，并恢复 2 个文件。 部分或全部目标回滚失败。');
    });

    test('failure falls back to readable error message', () {
      // 中文注释: 失败态不应吞掉底层错误信息，否则用户无法判断下一步。
      final outcome = service.resolve(
        action: _action(
          id: 'accept_revision',
          ownerTaskPath: 'tasks/r.task.json',
        ),
        result: const <String, Object?>{
          'ok': false,
          'error': 'Task not found.',
        },
        defaultSuccessMessage: '已完成。',
        currentSelectedTaskId: 'tasks/r.task.json',
      );

      expect(outcome.nextSelectedTaskId, 'tasks/r.task.json');
      expect(outcome.statusMessage, '操作失败：Task not found.');
    });
  });
}

TaskCenterContractActionViewData _action({
  required String id,
  required String ownerTaskPath,
}) {
  return TaskCenterContractActionViewData(
    id: id,
    label: id,
    note: '',
    tone: 'neutral',
    invocationKind: 'checkpoint_review',
    enabled: true,
    disabledReason: '',
    ownerTaskPath: ownerTaskPath,
    checkpointReviewPath: '',
  );
}
