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

      await harness.createProject(title: 'Task Center Workflow Create Request');

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
        timeout: const Duration(seconds: 10),
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

  test(
    'Task center workflow create persists chapter length settings into plan, sample chapter, and dynamically appended chapters',
    () async {
      final harness = await HfvvAppShellHarness.create(
        generateDraftUseCase: _idleGenerateDraftUseCase(),
      );
      addTearDown(harness.controller.dispose);

      await harness.createProject(title: 'Task Center Workflow Create Persist');

      harness.controller.onTaskCenterWorkflowCreateSubmitted(
        const TaskWorkflowCreateRequestViewData(
          mode: TaskRuntimeConstants.modeSeedToFullNovel,
          outlinePath: 'outlines/story/总纲.md',
          seedPrompt: '请从江南小镇起步，缓慢推进产业改良。',
          chapterCount: 12,
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
        () =>
            harness.controller.taskCenterPageListenable.value.status ==
            '长任务队列已生成。',
        description: 'workflow create settled',
        timeout: const Duration(seconds: 20),
      );

      final project = await harness.bundle.projectRepository.openByPath(
        harness.workbench.projectPath,
      );
      expect(project, isNotNull);
      final projectDescriptor = project!;
      final taskRepository = ProjectTaskRepository(
        workspacePort: harness.bundle.projectWorkspacePort,
      );
      final promptTemplateService = ProjectPromptTemplateService(
        workspacePort: harness.bundle.projectWorkspacePort,
      );
      final tasks = await taskRepository.listTasks(projectDescriptor);
      final planningTask = tasks.firstWhere(
        (task) => ValueReaders.stringValue(task['task_type']) == 'planning',
      );
      final planId = ValueReaders.stringValue(
        ValueReaders.mapValue(planningTask['metadata'])['plan_id'],
      );
      final plan = await taskRepository.loadRecord(
        projectDescriptor,
        'tracking/long_task/$planId.plan.json',
      );
      final planOptions = ValueReaders.mapValue(plan['options']);

      expect(
        planOptions,
        allOf(
          containsPair('enable_chapter_word_constraints', true),
          containsPair('chapter_word_target', 2300),
          containsPair('chapter_word_min', 1800),
          containsPair('chapter_word_max', 2900),
          containsPair('sample_chapter_word_target', 1700),
          containsPair('sample_chapter_word_min', 1400),
          containsPair('sample_chapter_word_max', 2200),
        ),
      );

      final sampleTask = tasks.firstWhere(
        (task) =>
            ValueReaders.stringValue(task['task_type']) == 'chapter' &&
            ValueReaders.stringValue(
                  ValueReaders.mapValue(task['metadata'])['stage'],
                ) ==
                'sample',
      );
      final sampleMetadata = ValueReaders.mapValue(sampleTask['metadata']);
      final sampleProfile = ValueReaders.mapValue(
        sampleMetadata['chapter_length_profile'],
      );

      expect(
        ValueReaders.intValue(sampleMetadata['chapter_word_target']),
        1700,
      );
      expect(ValueReaders.intValue(sampleMetadata['chapter_word_min']), 1400);
      expect(ValueReaders.intValue(sampleMetadata['chapter_word_max']), 2200);
      expect(ValueReaders.boolValue(sampleProfile['enabled']), isTrue);
      expect(ValueReaders.intValue(sampleProfile['target_length']), 1700);
      expect(ValueReaders.intValue(sampleProfile['preferred_min']), 1400);
      expect(ValueReaders.intValue(sampleProfile['preferred_max']), 2200);
      expect(ValueReaders.stringValue(sampleProfile['stage']), 'sample');

      for (final task in tasks) {
        await taskRepository.transitionTask(
          projectDescriptor,
          <String, Object?>{
            'relative_path': ValueReaders.stringValue(task['relative_path']),
          },
          TaskRuntimeConstants.statusSucceeded,
          note: 'test confirm',
        );
      }

      final workflowRuntimeService = ProjectWorkflowRuntimeService(
        taskRepository: taskRepository,
        promptTemplateService: promptTemplateService,
        generateDraftUseCaseFactory: (_, __) => harness.generateDraftUseCase,
      );
      final nextTask = await workflowRuntimeService.nextWorkflowTask(
        projectDescriptor,
      );

      expect(ValueReaders.stringValue(nextTask['id']), contains('chapter_002'));
      final appendedChapter = await taskRepository.loadTask(
        projectDescriptor,
        <String, Object?>{'task_id': ValueReaders.stringValue(nextTask['id'])},
      );
      final appendedMetadata = ValueReaders.mapValue(
        appendedChapter['metadata'],
      );
      final appendedProfile = ValueReaders.mapValue(
        appendedMetadata['chapter_length_profile'],
      );

      expect(
        ValueReaders.intValue(appendedMetadata['chapter_word_target']),
        2300,
      );
      expect(ValueReaders.intValue(appendedMetadata['chapter_word_min']), 1800);
      expect(ValueReaders.intValue(appendedMetadata['chapter_word_max']), 2900);
      expect(ValueReaders.boolValue(appendedProfile['enabled']), isTrue);
      expect(ValueReaders.intValue(appendedProfile['target_length']), 2300);
      expect(ValueReaders.intValue(appendedProfile['preferred_min']), 1800);
      expect(ValueReaders.intValue(appendedProfile['preferred_max']), 2900);
      expect(ValueReaders.stringValue(appendedProfile['stage']), 'draft');
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
