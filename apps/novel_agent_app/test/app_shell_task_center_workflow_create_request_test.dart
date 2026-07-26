import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_app/features/task_center/presentation/models/task_center_view_data.dart';
import 'package:novel_agent_app/features/workbench/application/controllers/generate_draft_use_case_factory.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import 'hfvv_viewmodel_harness_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Task center workflow create forwards chapter length settings into long task workflow options',
    () async {
      late _SpyCreateWorkflowRuntimeService workflowRuntimeService;
      final harness = await HfvvAppShellHarness.create(
        generateDraftUseCase: _idleGenerateDraftUseCase(),
        workflowRuntimeServiceFactory:
            ({
              required AdapterBundle bundle,
              required GenerateDraftUseCaseFactory generateDraftUseCaseFactory,
              required ProjectTaskRepository projectTaskRepository,
              required ProjectPromptTemplateService promptTemplateService,
            }) {
              workflowRuntimeService = _SpyCreateWorkflowRuntimeService(
                taskRepository: projectTaskRepository,
                promptTemplateService: promptTemplateService,
                generateDraftUseCaseFactory: generateDraftUseCaseFactory,
              );
              return workflowRuntimeService;
            },
      );
      addTearDown(harness.controller.dispose);

      await harness.createProject(
        title: 'Task Center Workflow Create Request',
        projectTypeId: 'long_novel',
        runtimeBaselineId: 'chapter_collaboration_autorun',
      );
      harness.controller.onTaskCenterWorkflowCreateSubmitted(
        const TaskWorkflowCreateRequestViewData(
          mode: TaskRuntimeConstants.modeSeedToFullNovel,
          outlinePath: 'outlines/story/总纲.md',
          seedPrompt: '请从江南小镇起步，缓慢推进产业改良。',
          chapterCount: 60,
          checkpointInterval: 4,
          chapterLength: TaskCenterChapterLengthConfigViewData(
            enableChapterWordConstraints: true,
            chapterWordTarget: 2300,
            chapterWordMin: 1800,
            chapterWordMax: 2900,
            sampleChapterWordTarget: 1700,
            sampleChapterWordMin: 1400,
            sampleChapterWordMax: 2200,
          ),
        ),
      );
      await harness.waitUntil(
        () => workflowRuntimeService.callCount == 1,
        description: 'workflow create captured',
        timeout: const Duration(seconds: 10),
      );
      await harness.waitUntil(
        () =>
            harness.controller.taskCenterPageListenable.value.status ==
            '长任务队列已生成。',
        description: 'workflow create settled',
        timeout: const Duration(seconds: 60),
      );

      expect(
        workflowRuntimeService.lastMode,
        TaskRuntimeConstants.modeSeedToFullNovel,
      );
      expect(
        workflowRuntimeService.lastOptions,
        containsPair('outline_path', 'outlines/story/总纲.md'),
      );
      expect(
        workflowRuntimeService.lastOptions,
        containsPair('chapter_count', 60),
      );
      expect(
        workflowRuntimeService.lastOptions,
        containsPair('checkpoint_interval', 4),
      );
      expect(
        workflowRuntimeService.lastOptions,
        containsPair('enable_chapter_word_constraints', true),
      );
      expect(
        workflowRuntimeService.lastOptions,
        containsPair('chapter_word_target', 2300),
      );
      expect(
        workflowRuntimeService.lastOptions,
        containsPair('chapter_word_min', 1800),
      );
      expect(
        workflowRuntimeService.lastOptions,
        containsPair('chapter_word_max', 2900),
      );
      expect(
        workflowRuntimeService.lastOptions,
        containsPair('sample_chapter_word_target', 1700),
      );
      expect(
        workflowRuntimeService.lastOptions,
        containsPair('sample_chapter_word_min', 1400),
      );
      expect(
        workflowRuntimeService.lastOptions,
        containsPair('sample_chapter_word_max', 2200),
      );
    },
  );
}

ScriptedGenerateDraftUseCase _idleGenerateDraftUseCase() {
  return ScriptedGenerateDraftUseCase(
    resultBuilder:
        ({
          required ProjectDescriptor project,
          required String userPrompt,
          required String modelId,
        }) => DraftGenerationResult(
          project: project,
          projectInfo: const <String, Object?>{},
          userPrompt: userPrompt,
          prompt: userPrompt,
          modelId: modelId,
          draftMarkdown: '',
          contextPack: const <String, Object?>{},
          selectedPaths: const <String>[],
          executedTools: const <Object?>[],
          writtenPaths: const <String>[],
          changedPaths: const <String>[],
          transcriptMessages: const <JsonMap>[],
          waitingForUserChoice: false,
          reasoningContent: '',
          stoppedByToolError: false,
          toolErrorSummary: '',
        ),
  )..releaseResult();
}

class _SpyCreateWorkflowRuntimeService extends ProjectWorkflowRuntimeService {
  _SpyCreateWorkflowRuntimeService({
    required super.taskRepository,
    required super.promptTemplateService,
    required super.generateDraftUseCaseFactory,
  }) : super();

  int callCount = 0;
  String lastMode = '';
  JsonMap lastOptions = const <String, Object?>{};

  @override
  Future<JsonMap> createLongTaskWorkflow(
    ProjectDescriptor project,
    String mode, {
    JsonMap options = const <String, Object?>{},
  }) async {
    callCount += 1;
    lastMode = mode;
    lastOptions = ValueReaders.deepCopyMap(options);
    return const <String, Object?>{
      'ok': true,
      'created_tasks': <Object?>[],
      'changed_paths': <Object?>[],
    };
  }
}
