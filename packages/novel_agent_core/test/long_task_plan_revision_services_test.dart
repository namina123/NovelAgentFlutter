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

    test(
      'plan record keeps chapter length options needed by dynamic queue extension',
      () {
        final record = planRecordService.planRecord(
          'plan_length',
          TaskRuntimeConstants.modeSeedToFullNovel,
          options: const <String, Object?>{
            'runtime_baseline_id': 'continuous_autonomous',
            'chapter_count': 60,
            'enable_chapter_word_constraints': true,
            'chapter_word_target': 1800,
            'chapter_word_min': 1400,
            'chapter_word_max': 2400,
            'sample_chapter_word_target': 1400,
            'sample_chapter_word_min': 1100,
            'sample_chapter_word_max': 1800,
            'chapter_length_rolling_window': 4,
            'chapter_length_mild_deviation_ratio': 0.18,
            'chapter_length_severe_deviation_ratio': 0.35,
          },
          createdAt: '2026-06-13T00:00:00Z',
        );

        final options = ValueReaders.mapValue(record['options']);

        expect(
          ValueReaders.boolValue(options['enable_chapter_word_constraints']),
          isTrue,
        );
        expect(ValueReaders.intValue(options['chapter_word_target']), 1800);
        expect(ValueReaders.intValue(options['chapter_word_min']), 1400);
        expect(ValueReaders.intValue(options['chapter_word_max']), 2400);
        expect(
          ValueReaders.intValue(options['sample_chapter_word_target']),
          1400,
        );
        expect(
          ValueReaders.doubleValue(
            options['chapter_length_mild_deviation_ratio'],
          ),
          0.18,
        );
      },
    );

    test('builds revision plan for checkpoint confirm and append chapter', () {
      // 中文注释: 这里验证运行中的修订命令既能确认检查点，也能动态追加新章节任务。
      final tasks = <Object?>[
        const <String, Object?>{
          'id': 'chapter_001',
          'title': '第一章',
          'task_type': 'chapter',
          'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
          'status': TaskRuntimeConstants.statusSucceeded,
          'output_paths': <Object?>['chapters/第01章.md'],
          'metadata': <String, Object?>{'sort_order': 1, 'stage': 'draft'},
        },
        const <String, Object?>{
          'id': 'checkpoint_001',
          'title': '检查点：确认方向',
          'task_type': 'checkpoint',
          'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
          'status': TaskRuntimeConstants.statusQueued,
          'depends_on': <Object?>['chapter_001'],
          'output_paths': <Object?>['chapters/第01章.md'],
          'metadata': <String, Object?>{
            'sort_order': 2,
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

    test(
      'append chapter keeps chapter length metadata when sourced from saved plan options',
      () {
        final planRecord = planRecordService.planRecord(
          'plan_seed',
          TaskRuntimeConstants.modeSeedToFullNovel,
          options: const <String, Object?>{
            'runtime_baseline_id': 'continuous_autonomous',
            'chapter_count': 60,
            'checkpoint_interval': 4,
            'enable_chapter_word_constraints': true,
            'chapter_word_target': 1800,
            'chapter_word_min': 1400,
            'chapter_word_max': 2400,
            'chapter_length_rolling_window': 4,
            'chapter_length_mild_deviation_ratio': 0.18,
            'chapter_length_severe_deviation_ratio': 0.35,
            'chapter_length_mild_adjacent_delta_ratio': 0.22,
            'chapter_length_severe_adjacent_delta_ratio': 0.45,
          },
          createdAt: '2026-06-13T00:01:00Z',
        );
        final existingTasks = <Object?>[
          const <String, Object?>{
            'id': 'plan_seed_checkpoint_outline',
            'title': '检查点：确认总纲与章节任务',
            'task_type': 'checkpoint',
            'mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'status': TaskRuntimeConstants.statusSucceeded,
            'depends_on': <Object?>['plan_seed_planning'],
            'output_paths': <Object?>[
              'outlines/story/总纲.md',
              'outlines/chapters/章节任务清单.md',
            ],
            'metadata': <String, Object?>{
              'sort_order': 2,
              'stage': 'checkpoint',
              'runtime_baseline_id': 'continuous_autonomous',
            },
          },
        ];

        final appendPlan = buildRevisionUseCase.execute(
          const <String, Object?>{
            'id': 'run_seed',
            'plan_id': 'plan_seed',
            'mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'last_task_id': 'plan_seed_checkpoint_outline',
          },
          existingTasks,
          'append_chapter',
          arguments: <String, Object?>{
            ...ValueReaders.mapValue(planRecord['options']),
            'after_task_id': 'plan_seed_checkpoint_outline',
            'chapter_number': 3,
            'title': '第03章',
            'task_title': '第03章',
            'chapter': '第03章',
            'brief': '根据规划任务继续写第三章。',
            'stage': 'draft',
            'source_paths': const <Object?>[
              'specs/project_spec.md',
              'outlines/story/总纲.md',
              'outlines/chapters/章节任务清单.md',
            ],
          },
          createdAt: '2026-06-13T00:02:00Z',
        );

        expect(appendPlan['ok'], isTrue);
        final newTask =
            (appendPlan['new_tasks'] as List<Object?>).single
                as Map<String, Object?>;
        final metadata = ValueReaders.mapValue(newTask['metadata']);
        final profile = ValueReaders.mapValue(
          metadata['chapter_length_profile'],
        );
        final policy = ValueReaders.mapValue(
          metadata['chapter_length_distribution_policy'],
        );

        expect(ValueReaders.intValue(metadata['chapter_word_target']), 1800);
        expect(ValueReaders.intValue(metadata['chapter_word_min']), 1400);
        expect(ValueReaders.intValue(metadata['chapter_word_max']), 2400);
        expect(ValueReaders.boolValue(profile['enabled']), isTrue);
        expect(ValueReaders.intValue(profile['target_length']), 1800);
        expect(ValueReaders.intValue(profile['preferred_min']), 1400);
        expect(ValueReaders.intValue(profile['preferred_max']), 2400);
        expect(ValueReaders.intValue(policy['rolling_window']), 4);
      },
    );

    test(
      'confirm checkpoint ignores blocked checkpoint whose dependency is not done',
      () {
        final blockedPlan = buildRevisionUseCase.execute(
          const <String, Object?>{
            'id': 'run_blocked',
            'plan_id': 'plan_blocked',
            'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
          },
          const <Object?>[
            <String, Object?>{
              'id': 'chapter_001',
              'title': '第一章',
              'task_type': 'chapter',
              'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
              'status': TaskRuntimeConstants.statusRunning,
            },
            <String, Object?>{
              'id': 'checkpoint_001',
              'title': '检查点：确认方向',
              'task_type': 'checkpoint',
              'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
              'status': TaskRuntimeConstants.statusWaitingUser,
              'depends_on': <Object?>['chapter_001'],
            },
          ],
          'confirm_checkpoint',
          createdAt: '2026-05-23T13:08:00Z',
        );

        expect(blockedPlan['ok'], isFalse);
        expect(
          ValueReaders.stringValue(blockedPlan['error']),
          contains('没有找到可确认的检查点任务'),
        );
      },
    );

    test('normalizes dynamic appended chapter output path from bare title', () {
      final appendPlan = buildRevisionUseCase.execute(
        const <String, Object?>{
          'id': 'run_beta',
          'plan_id': 'plan_beta',
          'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
        },
        const <Object?>[],
        'append_chapter',
        arguments: const <String, Object?>{
          'chapter_number': 4,
          'title': '第04章',
          'brief': '继续推进第四章。',
        },
        createdAt: '2026-05-23T13:07:00Z',
      );

      expect(appendPlan['ok'], isTrue);
      final newTask =
          (appendPlan['new_tasks'] as List<Object?>).single
              as Map<String, Object?>;
      expect(
        (newTask['output_paths'] as List<Object?>).single,
        'chapters/第04章.md',
      );
    });

    test(
      'dynamic inserted checkpoint stays queued until its dependency is done',
      () {
        final revisionPlan = buildRevisionUseCase.execute(
          const <String, Object?>{
            'id': 'run_gamma',
            'plan_id': 'plan_gamma',
            'mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'last_task_id': 'chapter_004',
          },
          const <Object?>[
            <String, Object?>{
              'id': 'chapter_004',
              'title': '第04章',
              'task_type': 'chapter',
              'mode': TaskRuntimeConstants.modeSeedToFullNovel,
              'status': TaskRuntimeConstants.statusQueued,
              'depends_on': <Object?>['chapter_003'],
              'output_paths': <Object?>['chapters/第04章.md'],
              'metadata': <String, Object?>{'sort_order': 20, 'stage': 'draft'},
            },
          ],
          'insert_checkpoint',
          arguments: const <String, Object?>{
            'id': 'checkpoint_004',
            'title': '检查点：第 4 章后确认',
          },
          createdAt: '2026-06-11T06:02:51Z',
        );

        expect(revisionPlan['ok'], isTrue);
        final checkpoint =
            (revisionPlan['new_tasks'] as List<Object?>).single
                as Map<String, Object?>;
        expect(checkpoint['status'], TaskRuntimeConstants.statusQueued);
        expect(checkpoint['depends_on'], contains('chapter_004'));
      },
    );
  });
}
