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
        <Object?>['drafts/第01章_第一章.md'],
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
  });
}
