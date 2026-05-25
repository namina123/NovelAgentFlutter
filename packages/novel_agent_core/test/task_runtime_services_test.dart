import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Task runtime services', () {
    final definitionService = TaskDefinitionService();
    final selectionService = TaskSelectionService(
      taskDefinitionService: definitionService,
    );
    final transitionService = TaskTransitionService();
    final planService = TaskExecutionPlanService(
      taskDefinitionService: definitionService,
    );

    test('selects next runnable task after dependency succeeds', () {
      // 中文注释: 这里验证任务选择器会跳过依赖未满足的任务，并找到真正可运行的下一项。
      final task = selectionService.nextRunnableTaskFromTasks(<Object?>[
        <String, Object?>{
          'id': 't1',
          'title': 'done',
          'status': TaskRuntimeConstants.statusSucceeded,
        },
        <String, Object?>{
          'id': 't2',
          'title': 'next',
          'status': TaskRuntimeConstants.statusQueued,
          'depends_on': <String>['t1'],
        },
      ]);

      expect(task['id'], 't2');
    });

    test('prevents transition out of terminal status', () {
      // 中文注释: 这里验证终态任务不能被错误恢复，避免宿主误把已完成任务重新推进。
      expect(
        transitionService.canTransition(
          TaskRuntimeConstants.statusSucceeded,
          TaskRuntimeConstants.statusQueued,
        ),
        isFalse,
      );
    });

    test('builds planning execution plan with planning-specific steps', () {
      // 中文注释: 这里验证不同任务类型会产出对应的步骤模板，而不是套用统一正文流程。
      final plan = planService.executionPlan(<String, Object?>{
        'id': 'plan-1',
        'task_type': 'planning',
      });

      expect((plan['steps'] as List<Object?>).length, greaterThan(3));
      expect(
        ((plan['steps'] as List<Object?>).first as Map<String, Object?>)['id'],
        'read_seed',
      );
    });

    test('adds chapter gate steps for autorun baseline chapter task', () {
      final plan = planService.executionPlan(<String, Object?>{
        'id': 'chapter-1',
        'task_type': 'chapter',
        'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
        'metadata': <String, Object?>{
          'runtime_baseline_id': 'chapter_collaboration_autorun',
        },
      });

      final stepIds = (plan['steps'] as List<Object?>)
          .whereType<Map<String, Object?>>()
          .map((item) => item['id'])
          .toList(growable: false);
      expect(stepIds, contains('run_chapter_gate_review'));
      expect(stepIds, contains('repair_if_gate_failed'));
      expect(stepIds, contains('advance_after_gate'));
    });
  });
}
