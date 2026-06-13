import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Chapter atomic runtime services', () {
    final taskDefinition = TaskDefinitionService();
    final executionPlan = TaskExecutionPlanService(
      taskDefinitionService: taskDefinition,
    );
    final contextBudget = ContextBudgetService();
    final staticSection = ContextStaticSectionService(
      projectPromptContract: ProjectPromptContract(),
    );
    final fileSection = ContextProjectFileSectionService();
    final assembler = ContextAssemblerService(
      budgetService: contextBudget,
      staticSectionService: staticSection,
      projectFileSectionService: fileSection,
    );
    final promptBuilder = ChapterAtomicPromptBuilderService(
      taskDefinitionService: taskDefinition,
    );
    final stepState = ChapterAtomicStepStateService();
    final eventService = ChapterAtomicEventService();
    final executionBuilder = ChapterAtomicExecutionBuilderService(
      promptBuilderService: promptBuilder,
      intentService: ChapterAtomicIntentService(),
      outputPathService: ChapterAtomicOutputPathService(),
      stepStateService: stepState,
      eventService: eventService,
      contextAssemblerService: assembler,
      executionPlanService: executionPlan,
    );
    final recorder = ChapterAtomicResultRecorderService(
      stepStateService: stepState,
      eventService: eventService,
    );
    final renderer = ChapterAtomicMarkdownRenderer();

    test('prepares execution package and records model/postprocess result', () {
      // 中文注释: 这里验证章节原子执行包会生成步骤游标、上下文包和拟写入路径，并能推进后续步骤。
      final prepared = executionBuilder.prepareExecution(<String, Object?>{
        'project': <String, Object?>{'id': 'p1', 'name': '项目'},
        'task': <String, Object?>{
          'id': 'task_1',
          'title': '第一章',
          'task_type': 'chapter',
          'mode': TaskRuntimeConstants.modeSingleChapterAtomic,
          'goal': '写出第一章',
          'brief': '主角在雨夜收到短信。',
          'source_paths': <String>['outline/总纲.md'],
        },
        'project_files': <Object?>[],
        'project_file_contents': <String, Object?>{},
        'context_settings': <String, Object?>{
          'context_pack_budget_chars': 2000,
        },
        'model_profile': <String, Object?>{'context_window': 8000},
      });
      expect(prepared['ok'], isTrue);

      final execution = (prepared['execution'] as Map<String, Object?>);
      expect((execution['steps'] as List<Object?>).isNotEmpty, isTrue);

      final afterModel = recorder.recordModelResult(
        execution,
        <String, Object?>{'id': 'resp_1', 'result_markdown': '正文结果'},
        <Object?>['chapters/第01章_第一章.md'],
      );
      final afterPostprocess = recorder.recordPostprocessResult(
        afterModel['execution'] as Map<String, Object?>,
        <String, Object?>{'id': 'resp_2'},
        <Object?>['summaries/第01章_第一章.summary.md'],
        <Object?>['summarize_context', 'run_continuity_check'],
      );

      expect(
        renderer.renderMarkdown(
          afterPostprocess['execution'] as Map<String, Object?>,
        ),
        contains('最近模型输出摘要'),
      );
      expect(
        ((afterPostprocess['execution'] as Map<String, Object?>)['output_paths']
                as List<Object?>)
            .length,
        2,
      );
    });

    test('planning recorder recognizes canonical outline artifact roots', () {
      final prepared = executionBuilder.prepareExecution(<String, Object?>{
        'project': <String, Object?>{'id': 'p1', 'name': '项目'},
        'task': <String, Object?>{
          'id': 'planning_1',
          'title': '规划任务',
          'task_type': 'planning',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'goal': '落地规格与大纲',
          'brief': '从种子扩展成长篇规划。',
          'source_paths': <String>['specs/project_spec.md'],
        },
        'project_files': <Object?>[],
        'project_file_contents': <String, Object?>{},
        'context_settings': <String, Object?>{
          'context_pack_budget_chars': 2000,
        },
        'model_profile': <String, Object?>{'context_window': 8000},
      });
      expect(prepared['ok'], isTrue);

      final execution = prepared['execution'] as Map<String, Object?>;
      final afterModel = recorder.recordModelResult(
        execution,
        <String, Object?>{'id': 'resp_planning', 'result_markdown': '规划结果'},
        <Object?>[
          'specs/project_spec.md',
          'outlines/story/总纲.md',
          'outlines/chapters/章节任务清单.md',
        ],
      );
      final steps = ValueReaders.mapList(
        (afterModel['execution'] as Map<String, Object?>)['steps'],
      );
      final saveProjectSpec = steps.firstWhere(
        (step) => ValueReaders.stringValue(step['id']) == 'save_project_spec',
      );
      final saveOutline = steps.firstWhere(
        (step) => ValueReaders.stringValue(step['id']) == 'save_outline',
      );

      expect(
        ValueReaders.stringValue(saveProjectSpec['status']),
        ChapterAtomicConstants.stepSucceeded,
      );
      expect(
        ValueReaders.stringValue(saveOutline['status']),
        ChapterAtomicConstants.stepSucceeded,
      );
    });

    test(
      'planning-stage workflow subtask does not propose chapter outputs',
      () {
        final outputs = ChapterAtomicOutputPathService().proposedOutputPaths(
          <String, Object?>{
            'id': 'update_character_state',
            'title': '更新主角状态',
            'task_type': 'agent_task',
            'output_paths': <Object?>['assets/characters/主角.md'],
            'metadata': const <String, Object?>{
              'plan_id': 'plan_seed',
              'stage': 'planning',
              'generated_by': 'LongTaskPlanner',
            },
          },
        );

        expect(outputs.containsKey('chapter'), isFalse);
        expect(
          ValueReaders.stringValue(outputs['primary']),
          'assets/characters/主角.md',
        );
        expect(
          ValueReaders.stringValue(outputs['planning_note']),
          contains('tracking/planning/'),
        );
      },
    );
  });
}
