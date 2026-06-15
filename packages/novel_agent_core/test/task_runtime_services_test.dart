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

    test('does not select sample task before readiness checkpoint succeeds', () {
      final task = selectionService.nextRunnableTaskFromTasks(<Object?>[
        <String, Object?>{
          'id': 'sample_001',
          'title': '样章：开篇验证',
          'task_type': 'chapter',
          'status': TaskRuntimeConstants.statusQueued,
          'metadata': const <String, Object?>{'stage': 'sample'},
        },
      ]);

      expect(task, isEmpty);
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

    test('allows paused task to complete after explicit confirmation', () {
      expect(
        transitionService.canTransition(
          TaskRuntimeConstants.statusPaused,
          TaskRuntimeConstants.statusSucceeded,
        ),
        isTrue,
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

    test(
      'normalizes summary-like workflow task away from chapter semantics',
      () {
        final normalized = definitionService.normalizeTask(<String, Object?>{
          'id': 'save_summary',
          'title': '保存章节摘要',
          'task_type': 'chapter',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'goal': '将本章摘要写入 summaries/',
          'output_paths': <Object?>['summaries/保存章节摘要.summary.md'],
          'metadata': <String, Object?>{'stage': 'sample'},
        });

        expect(ValueReaders.stringValue(normalized['task_type']), 'summary');
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(normalized['metadata'])['stage'],
          ),
          'summary',
        );

        final plan = planService.executionPlan(normalized);
        final stepIds = (plan['steps'] as List<Object?>)
            .whereType<Map<String, Object?>>()
            .map((item) => ValueReaders.stringValue(item['id']))
            .toList(growable: false);
        expect(stepIds, contains('read_sources'));
        expect(stepIds, contains('save_summary'));
        expect(stepIds, isNot(contains('draft_chapter')));
        expect(stepIds, isNot(contains('run_chapter_gate_review')));
      },
    );

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

    test(
      'skips task already postprocessed when selecting next postprocess',
      () {
        // 中文注释: 这里验证后处理选择器不会反复捞起同一条已经跑完后处理的 waiting_user 任务。
        final task = selectionService.nextPostprocessTaskFromTasks(<Object?>[
          <String, Object?>{
            'id': 'chapter-1',
            'title': 'sample',
            'task_type': 'chapter',
            'status': TaskRuntimeConstants.statusWaitingUser,
            'atomic_execution_path':
                'tracking/chapter_atomic/sample.execution.json',
            'output_paths': <String>['chapters/第01章.md'],
            'postprocess_ran_at': '2026-05-26T01:20:00.000Z',
          },
          <String, Object?>{
            'id': 'chapter-2',
            'title': 'chapter 2',
            'task_type': 'chapter',
            'status': TaskRuntimeConstants.statusWaitingUser,
            'atomic_execution_path':
                'tracking/chapter_atomic/ch02.execution.json',
            'output_paths': <String>['chapters/第02章.md'],
          },
        ]);

        expect(task['id'], 'chapter-2');
      },
    );
  });
}
