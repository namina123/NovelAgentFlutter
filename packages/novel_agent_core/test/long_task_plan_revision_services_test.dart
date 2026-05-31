import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Long task plan and revision services', () {
    final modeService = LongTaskModeService();
    final pathPolicyService = LongTaskPathPolicyService();
    final taskFactoryService = LongTaskTaskFactoryService(
      modeService: modeService,
      pathPolicyService: pathPolicyService,
    );
    final planRecordService = LongTaskPlanRecordService(
      modeService: modeService,
    );
    final planChangedPathsService = LongTaskPlanChangedPathsService();
    final planMarkdownRenderer = LongTaskPlanMarkdownRenderer();
    final buildPlanUseCase = BuildLongTaskPlanUseCase(
      taskFactoryService: taskFactoryService,
      planRecordService: planRecordService,
      changedPathsService: planChangedPathsService,
      markdownRenderer: planMarkdownRenderer,
    );
    final dynamicTaskFactoryService = LongTaskDynamicTaskFactoryService(
      modeService: modeService,
      pathPolicyService: pathPolicyService,
    );
    final revisionPlanService = LongTaskRevisionPlanService(
      dynamicTaskFactoryService: dynamicTaskFactoryService,
    );
    final buildRevisionUseCase = BuildLongTaskRevisionPlanUseCase(
      revisionPlanService: revisionPlanService,
    );

    test('builds long task plan with markdown and changed paths', () {
      // 中文注释: 这里验证计划入口会统一生成任务、计划记录、Markdown 和变更路径集合。
      final result = buildPlanUseCase.execute(
        TaskRuntimeConstants.modeHumanOutlineAiDraft,
        'plan_alpha',
        options: const <String, Object?>{
          'outline_text': '第一章：雨夜短信\n第二章：追踪真相',
          'chapter_count': 2,
        },
        createdAt: '2026-05-23T13:00:00Z',
      );

      expect(result['ok'], isTrue);
      final plan = result['plan'] as Map<String, Object?>;
      final tasks = result['tasks'] as List<Object?>;
      expect(plan['id'], 'plan_alpha');
      expect(tasks.length, 2);
      expect(result['markdown'], contains('长任务队列计划'));
      expect(result['changed_paths'], contains('tracking/long_task/plan.json'));
    });

    test('builds revision plan for checkpoint confirm and append chapter', () {
      // 中文注释: 这里验证运行中的修订命令既能确认检查点，也能动态追加新章节任务。
      final tasks = <Object?>[
        const <String, Object?>{
          'id': 'checkpoint_001',
          'title': '检查点：确认方向',
          'task_type': 'checkpoint',
          'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
          'status': TaskRuntimeConstants.statusWaitingUser,
          'output_paths': <Object?>['chapters/第01章.md'],
          'metadata': <String, Object?>{
            'sort_order': 1,
            'stage': 'checkpoint',
            'persistent_context_paths': <Object?>[
              'tracking/modes/full_outline_consensus/guidance.md',
              'styles/full_outline_consensus_style.md',
            ],
          },
        },
      ];
      final confirmPlan = buildRevisionUseCase.execute(
        const <String, Object?>{
          'id': 'run_alpha',
          'plan_id': 'plan_alpha',
          'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
        },
        tasks,
        'confirm_checkpoint',
        createdAt: '2026-05-23T13:05:00Z',
      );
      final appendPlan = buildRevisionUseCase.execute(
        const <String, Object?>{
          'id': 'run_alpha',
          'plan_id': 'plan_alpha',
          'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
          'last_task_id': 'checkpoint_001',
        },
        tasks,
        'append_chapter',
        arguments: const <String, Object?>{
          'title': '新的转折',
          'brief': '在确认方向后续写下一章。',
        },
        createdAt: '2026-05-23T13:06:00Z',
      );

      expect(confirmPlan['ok'], isTrue);
      expect((confirmPlan['task_updates'] as List<Object?>), hasLength(1));
      final update =
          (confirmPlan['task_updates'] as List<Object?>).first
              as Map<String, Object?>;
      expect(update['status'], TaskRuntimeConstants.statusSucceeded);

      expect(appendPlan['ok'], isTrue);
      expect((appendPlan['new_tasks'] as List<Object?>), hasLength(1));
      final newTask =
          (appendPlan['new_tasks'] as List<Object?>).first
              as Map<String, Object?>;
      expect(newTask['task_type'], 'chapter');
      expect(newTask['depends_on'], contains('checkpoint_001'));
      expect(
        (newTask['output_paths'] as List<Object?>).first,
        contains('chapters/'),
      );
      final sourcePaths = ValueReaders.stringList(newTask['source_paths']);
      expect(sourcePaths, contains('styles/full_outline_consensus_style.md'));
      final metadata = ValueReaders.mapValue(newTask['metadata']);
      expect(
        ValueReaders.stringList(metadata['persistent_context_paths']),
        contains('tracking/modes/full_outline_consensus/guidance.md'),
      );
    });
  });
}

