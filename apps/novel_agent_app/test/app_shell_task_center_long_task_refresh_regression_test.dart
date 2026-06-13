import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/routing/app_destination.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_app/features/task_center/presentation/models/task_center_view_data.dart';
import 'package:novel_agent_app/features/workbench/application/controllers/generate_draft_use_case_factory.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import 'hfvv_viewmodel_harness_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Long task station refresh backfills task center run snapshots after run files land',
    () async {
      final harness = await HfvvAppShellHarness.create(
        generateDraftUseCase: ScriptedGenerateDraftUseCase(
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
        )..releaseResult(),
      );
      addTearDown(harness.controller.dispose);

      await harness.createProject(
        title: 'Task Center Long Task Refresh Regression',
      );

      harness.controller.showTaskCenter();
      await harness.waitUntil(
        () =>
            harness.controller.viewModel.destination ==
            AppDestination.longTaskStation,
        description: 'long task station destination',
      );

      harness.controller.onTaskCenterRefreshRequested();
      await harness.waitUntil(
        () => harness.controller.taskCenterPageListenable.value.schedulerSummary
            .contains('Long task run not found.'),
        description: 'initial stale task center scheduler summary',
      );

      final project = ProjectDescriptor(
        id: harness.workbench.projectName,
        name: harness.workbench.projectName,
        rootPath: harness.workbench.projectPath,
        projectType: 'novel',
        storageStrategy: ProjectStorageStrategy.markdownProjectStore,
      );
      final repository = ProjectTaskRepository(
        workspacePort: harness.bundle.projectWorkspacePort,
      );

      await repository.saveTask(project, <String, Object?>{
        'schema_version': 1,
        'id': 'style_review_waiting',
        'title': '文风审稿：seed_autopilot_style',
        'task_type': 'review',
        'mode': TaskRuntimeConstants.modeSeedToFullNovel,
        'status': TaskRuntimeConstants.statusWaitingUser,
        'depends_on': const <Object?>[],
        'source_paths': const <Object?>[],
        'output_paths': const <Object?>[
          'reviews/style/文风审稿：seed_autopilot_style.md',
        ],
        'metadata': <String, Object?>{
          'plan_id': 'plan_refresh_regression',
          'workflow_mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'sort_order': 2,
        },
        'created_at': '2026-06-10T21:19:07Z',
        'updated_at': '2026-06-10T21:19:07Z',
        'history': const <Object?>[
          <String, Object?>{
            'status': TaskRuntimeConstants.statusWaitingUser,
            'note': '模型已写入项目文件，等待用户确认后继续。',
            'created_at': '2026-06-10T21:19:07Z',
          },
        ],
        'relative_path': 'tasks/style_review_waiting.json',
      });
      await repository.saveRecord(
        project,
        'tracking/long_task_runs/run_refresh_regression.json',
        const <String, Object?>{
          'id': 'run_refresh_regression',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'status': 'waiting_gate',
          'options': <String, Object?>{
            'mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'max_steps': 3,
          },
          'updated_at': '2026-06-10T21:19:08Z',
          'relative_path':
              'tracking/long_task_runs/run_refresh_regression.json',
        },
      );
      await repository.saveRecord(
        project,
        'tracking/task_queue_runs/queue_refresh_regression.json',
        const <String, Object?>{
          'id': 'queue_refresh_regression',
          'status': 'stopped',
          'completed_steps': 2,
          'updated_at': '2026-06-10T21:19:08Z',
          'last_task_id': 'style_review_waiting',
          'relative_path':
              'tracking/task_queue_runs/queue_refresh_regression.json',
        },
      );

      await harness.controller.longTaskStationController.refresh();
      await harness.waitUntil(
        () =>
            harness
                    .controller
                    .taskCenterPageListenable
                    .value
                    .longTaskRuns
                    .length ==
                1 &&
            harness
                    .controller
                    .taskCenterPageListenable
                    .value
                    .taskQueueRuns
                    .length ==
                1 &&
            harness.controller.taskCenterPageListenable.value.tasks.any(
              (item) => item.relativePath == 'tasks/style_review_waiting.json',
            ),
        description: 'task center backfilled run snapshots',
        timeout: const Duration(seconds: 10),
      );

      final taskCenter = harness.controller.taskCenterPageListenable.value;
      expect(
        taskCenter.schedulerSummary.contains('Long task run not found.'),
        isFalse,
      );
      expect(taskCenter.longTaskRuns.single.relativePath, endsWith('.json'));
      expect(taskCenter.taskQueueRuns.single.relativePath, endsWith('.json'));
      expect(
        taskCenter.tasks.single.relativePath,
        'tasks/style_review_waiting.json',
      );
      expect(taskCenter.status, isNot(contains('正在')));

      final projectPath = harness.workbench.projectPath;
      expect(
        File(
          '$projectPath${Platform.pathSeparator}tracking'
          '${Platform.pathSeparator}long_task_runs'
          '${Platform.pathSeparator}run_refresh_regression.json',
        ).existsSync(),
        isTrue,
      );
    },
  );

  test(
    'Task center keeps pending status during queue run pulse and selects newest run snapshot after completion',
    () async {
      late _DelayedTaskQueueWorkflowRuntimeService workflowRuntimeService;
      final harness = await HfvvAppShellHarness.create(
        generateDraftUseCase: ScriptedGenerateDraftUseCase(
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
        )..releaseResult(),
        workflowRuntimeServiceFactory:
            ({
              required AdapterBundle bundle,
              required GenerateDraftUseCaseFactory generateDraftUseCaseFactory,
              required ProjectTaskRepository projectTaskRepository,
              required ProjectPromptTemplateService promptTemplateService,
            }) {
              workflowRuntimeService = _DelayedTaskQueueWorkflowRuntimeService(
                taskRepository: projectTaskRepository,
                promptTemplateService: promptTemplateService,
                generateDraftUseCaseFactory: generateDraftUseCaseFactory,
              );
              return workflowRuntimeService;
            },
      );
      addTearDown(harness.controller.dispose);

      await harness.createProject(
        title: 'Task Center Queue Pulse Pending Regression',
      );

      final project = ProjectDescriptor(
        id: harness.workbench.projectName,
        name: harness.workbench.projectName,
        rootPath: harness.workbench.projectPath,
        projectType: 'long_novel',
        storageStrategy: ProjectStorageStrategy.markdownProjectStore,
      );
      final repository = ProjectTaskRepository(
        workspacePort: harness.bundle.projectWorkspacePort,
      );
      await repository.saveTask(project, <String, Object?>{
        'schema_version': 1,
        'id': 'queued_task_001',
        'title': '样章：第01章',
        'task_type': 'chapter',
        'mode': TaskRuntimeConstants.modeSeedToFullNovel,
        'status': TaskRuntimeConstants.statusQueued,
        'depends_on': const <Object?>[],
        'source_paths': const <Object?>[],
        'output_paths': const <Object?>['chapters/ch01.md'],
        'created_at': '2026-06-10T22:00:00Z',
        'updated_at': '2026-06-10T22:00:00Z',
        'relative_path': 'tasks/queued_task_001.json',
      });
      await repository.saveRecord(
        project,
        'tracking/long_task_runs/run_old.json',
        const <String, Object?>{
          'id': 'run_old',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'status': 'waiting_gate',
          'updated_at': '2026-06-10T22:00:00Z',
          'relative_path': 'tracking/long_task_runs/run_old.json',
        },
      );
      await repository.saveRecord(
        project,
        'tracking/task_queue_runs/queue_old.json',
        const <String, Object?>{
          'id': 'queue_old',
          'status': 'stopped',
          'completed_steps': 1,
          'stop_reason': 'waiting_user_choice',
          'updated_at': '2026-06-10T22:00:00Z',
          'relative_path': 'tracking/task_queue_runs/queue_old.json',
        },
      );

      harness.controller.showTaskCenter();
      await harness.waitUntil(
        () =>
            harness.controller.viewModel.destination ==
            AppDestination.longTaskStation,
        description: 'task center destination',
      );
      harness.controller.onTaskCenterRefreshRequested();
      await harness.waitUntil(
        () =>
            harness
                    .controller
                    .taskCenterPageListenable
                    .value
                    .selectedLongTaskRunPath ==
                'tracking/long_task_runs/run_old.json' &&
            harness
                    .controller
                    .taskCenterPageListenable
                    .value
                    .selectedTaskQueueRunPath ==
                'tracking/task_queue_runs/queue_old.json',
        description: 'old run selection loaded',
      );

      harness.controller.onTaskCenterRunQueueRequested();
      await harness.waitUntil(
        () =>
            harness.controller.taskCenterPageListenable.value.status ==
            '正在启动受控连续运行...',
        description: 'pending queue status',
      );

      await Future<void>.delayed(const Duration(milliseconds: 1400));

      expect(
        harness.controller.taskCenterPageListenable.value.status,
        '正在启动受控连续运行...',
      );
      expect(workflowRuntimeService.runStarted, isTrue);

      workflowRuntimeService.complete();

      await harness.waitUntil(
        () =>
            harness
                    .controller
                    .taskCenterPageListenable
                    .value
                    .selectedLongTaskRunPath ==
                'tracking/long_task_runs/run_new.json' &&
            harness
                    .controller
                    .taskCenterPageListenable
                    .value
                    .selectedTaskQueueRunPath ==
                'tracking/task_queue_runs/queue_new.json',
        description: 'new run selection adopted',
        timeout: const Duration(seconds: 10),
      );
      await harness.waitUntil(
        () =>
            harness.controller.taskCenterPageListenable.value.status ==
            '队列运行已推进。',
        description: 'queue status settled',
        timeout: const Duration(seconds: 10),
      );

      final taskCenter = harness.controller.taskCenterPageListenable.value;
      expect(taskCenter.status, '队列运行已推进。');
      expect(
        taskCenter.selectedLongTaskRunPath,
        'tracking/long_task_runs/run_new.json',
      );
      expect(
        taskCenter.selectedTaskQueueRunPath,
        'tracking/task_queue_runs/queue_new.json',
      );
    },
  );

  test(
    'Task center keeps polling long task station while queue start is pending and run files appear late',
    () async {
      late _DelayedTaskQueueWorkflowRuntimeService workflowRuntimeService;
      final harness = await HfvvAppShellHarness.create(
        generateDraftUseCase: ScriptedGenerateDraftUseCase(
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
        )..releaseResult(),
        workflowRuntimeServiceFactory:
            ({
              required AdapterBundle bundle,
              required GenerateDraftUseCaseFactory generateDraftUseCaseFactory,
              required ProjectTaskRepository projectTaskRepository,
              required ProjectPromptTemplateService promptTemplateService,
            }) {
              workflowRuntimeService = _DelayedTaskQueueWorkflowRuntimeService(
                taskRepository: projectTaskRepository,
                promptTemplateService: promptTemplateService,
                generateDraftUseCaseFactory: generateDraftUseCaseFactory,
                runAppearanceDelay: const Duration(milliseconds: 1600),
              );
              return workflowRuntimeService;
            },
      );
      addTearDown(harness.controller.dispose);

      await harness.createProject(
        title: 'Task Center Late Run Appearance Regression',
      );

      harness.controller.showTaskCenter();
      await harness.waitUntil(
        () =>
            harness.controller.viewModel.destination ==
            AppDestination.longTaskStation,
        description: 'task center destination',
      );

      harness.controller.onTaskCenterRunQueueRequested();
      await harness.waitUntil(
        () =>
            harness.controller.taskCenterPageListenable.value.status ==
            '正在启动受控连续运行...',
        description: 'pending queue status',
      );

      await harness.waitUntil(
        () =>
            harness
                    .controller
                    .taskCenterPageListenable
                    .value
                    .selectedLongTaskRunPath ==
                'tracking/long_task_runs/run_new.json' &&
            harness
                    .controller
                    .taskCenterPageListenable
                    .value
                    .selectedTaskQueueRunPath ==
                'tracking/task_queue_runs/queue_new.json' &&
            harness
                .controller
                .taskCenterPageListenable
                .value
                .longTaskRuns
                .isNotEmpty &&
            harness.controller.taskCenterPageListenable.value.status ==
                '正在启动受控连续运行...',
        description: 'late run snapshot adopted while pending',
        timeout: const Duration(seconds: 10),
      );

      final pendingTaskCenter =
          harness.controller.taskCenterPageListenable.value;
      expect(
        pendingTaskCenter.schedulerSummary.contains('Long task run not found.'),
        isFalse,
      );
      expect(pendingTaskCenter.longTaskRuns, isNotEmpty);
      expect(
        pendingTaskCenter.taskQueueRuns.single.relativePath,
        'tracking/task_queue_runs/queue_new.json',
      );

      workflowRuntimeService.complete();

      await harness.waitUntil(
        () =>
            harness.controller.taskCenterPageListenable.value.status ==
            '队列运行已推进。',
        description: 'queue status settled after late run appearance',
        timeout: const Duration(seconds: 10),
      );
    },
  );

  test(
    'Real workflow queue start surfaces pending run evidence before first draft call completes',
    () async {
      final generateDraftUseCase = ScriptedGenerateDraftUseCase(
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
      );
      final harness = await HfvvAppShellHarness.create(
        generateDraftUseCase: generateDraftUseCase,
      );
      addTearDown(harness.controller.dispose);

      await harness.createProject(title: 'Task Center Real Pending Evidence');

      harness.controller.showTaskCenter();
      await harness.waitUntil(
        () =>
            harness.controller.viewModel.destination ==
            AppDestination.longTaskStation,
        description: 'task center destination',
      );

      harness.controller.onTaskCenterWorkflowCreateSubmitted(
        const TaskWorkflowCreateRequestViewData(
          mode: TaskRuntimeConstants.modeSeedToFullNovel,
          outlinePath: 'outlines/story/总纲.md',
          seedPrompt: '请从零开始规划并写作一部长篇，先稳住样章与章节承接。',
          chapterCount: 12,
          checkpointInterval: 4,
          chapterLength: TaskCenterChapterLengthConfigViewData(
            enableChapterWordConstraints: true,
            chapterWordTarget: 2000,
            chapterWordMin: 1600,
            chapterWordMax: 2600,
            sampleChapterWordTarget: 1800,
            sampleChapterWordMin: 1400,
            sampleChapterWordMax: 2400,
          ),
        ),
      );
      await harness.waitUntil(
        () =>
            harness.controller.taskCenterPageListenable.value.status ==
            '长任务队列已生成。',
        description: 'workflow create settled',
        timeout: const Duration(seconds: 30),
      );

      harness.controller.onTaskCenterRunQueueRequested();
      await harness.waitUntil(
        () =>
            harness.controller.taskCenterPageListenable.value.status ==
            '正在启动受控连续运行...',
        description: 'pending queue status',
        timeout: const Duration(seconds: 30),
      );

      await harness.waitUntil(
        () =>
            harness
                .controller
                .longTaskStationController
                .viewData
                .runs
                .isNotEmpty ||
            harness
                .controller
                .taskCenterPageListenable
                .value
                .longTaskRuns
                .isNotEmpty ||
            harness
                .controller
                .taskCenterPageListenable
                .value
                .taskQueueRuns
                .isNotEmpty,
        description: 'pending run evidence from real workflow queue start',
        timeout: const Duration(seconds: 12),
      );

      final longTaskStation =
          harness.controller.longTaskStationController.viewData;
      final taskCenter = harness.controller.taskCenterPageListenable.value;
      expect(
        longTaskStation.runs.isNotEmpty ||
            taskCenter.longTaskRuns.isNotEmpty ||
            taskCenter.taskQueueRuns.isNotEmpty,
        isTrue,
        reason:
            'stationRuns=${longTaskStation.runs.length} '
            'taskCenterLongRuns=${taskCenter.longTaskRuns.length} '
            'taskCenterQueueRuns=${taskCenter.taskQueueRuns.length} '
            'stationStatus=${longTaskStation.statusMessage} '
            'taskCenterStatus=${taskCenter.status} '
            'scheduler=${taskCenter.schedulerSummary}',
      );

      generateDraftUseCase.releaseResult();
      await harness.waitUntil(
        () => !harness.controller.taskCenterPageListenable.value.status
            .startsWith('正在'),
        description: 'real workflow queue settled after releasing draft result',
        timeout: const Duration(seconds: 30),
      );
    },
  );

  test(
    'Real workflow queue start still surfaces pending run evidence when first draft call blocks synchronously',
    () async {
      final harness = await HfvvAppShellHarness.create(
        generateDraftUseCase: _BlockingScriptedGenerateDraftUseCase(
          blockDuration: const Duration(seconds: 2),
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
        ),
      );
      addTearDown(harness.controller.dispose);

      await harness.createProject(
        title: 'Task Center Blocking Pending Evidence',
      );

      harness.controller.showTaskCenter();
      await harness.waitUntil(
        () =>
            harness.controller.viewModel.destination ==
            AppDestination.longTaskStation,
        description: 'task center destination',
      );

      harness.controller.onTaskCenterWorkflowCreateSubmitted(
        const TaskWorkflowCreateRequestViewData(
          mode: TaskRuntimeConstants.modeSeedToFullNovel,
          outlinePath: 'outlines/story/总纲.md',
          seedPrompt: '请从零开始规划并写作一部长篇，先稳住样章与章节承接。',
          chapterCount: 12,
          checkpointInterval: 4,
          chapterLength: TaskCenterChapterLengthConfigViewData(
            enableChapterWordConstraints: true,
            chapterWordTarget: 2000,
            chapterWordMin: 1600,
            chapterWordMax: 2600,
            sampleChapterWordTarget: 1800,
            sampleChapterWordMin: 1400,
            sampleChapterWordMax: 2400,
          ),
        ),
      );
      await harness.waitUntil(
        () =>
            harness.controller.taskCenterPageListenable.value.status ==
            '长任务队列已生成。',
        description: 'workflow create settled',
        timeout: const Duration(seconds: 30),
      );

      harness.controller.onTaskCenterRunQueueRequested();
      await harness.waitUntil(
        () =>
            harness.controller.taskCenterPageListenable.value.status ==
            '正在启动受控连续运行...',
        description: 'pending queue status',
        timeout: const Duration(seconds: 30),
      );

      await harness.waitUntil(
        () =>
            harness
                .controller
                .longTaskStationController
                .viewData
                .runs
                .isNotEmpty ||
            harness
                .controller
                .taskCenterPageListenable
                .value
                .longTaskRuns
                .isNotEmpty ||
            harness
                .controller
                .taskCenterPageListenable
                .value
                .taskQueueRuns
                .isNotEmpty,
        description: 'pending run evidence under blocking draft call',
        timeout: const Duration(seconds: 6),
      );

      await harness.waitUntil(
        () => !harness.controller.taskCenterPageListenable.value.status
            .startsWith('正在'),
        description: 'blocking draft workflow settles',
        timeout: const Duration(seconds: 30),
      );
    },
  );
}

class _DelayedTaskQueueWorkflowRuntimeService
    extends ProjectWorkflowRuntimeService {
  _DelayedTaskQueueWorkflowRuntimeService({
    required super.taskRepository,
    required super.promptTemplateService,
    required super.generateDraftUseCaseFactory,
    this.runAppearanceDelay = Duration.zero,
  }) : _taskRepository = taskRepository,
       super();

  final ProjectTaskRepository _taskRepository;
  final Duration runAppearanceDelay;
  final Completer<void> _completion = Completer<void>();
  bool runStarted = false;

  void complete() {
    if (!_completion.isCompleted) {
      _completion.complete();
    }
  }

  @override
  Future<JsonMap> runWorkflowTaskQueue(
    ProjectDescriptor project,
    AppSettings settings, {
    JsonMap options = const <String, Object?>{},
    JsonMap agent = const <String, Object?>{},
  }) async {
    runStarted = true;
    if (runAppearanceDelay > Duration.zero) {
      await Future<void>.delayed(runAppearanceDelay);
    }
    await _taskRepository.saveRecord(
      project,
      'tracking/long_task_runs/run_new.json',
      const <String, Object?>{
        'id': 'run_new',
        'mode': TaskRuntimeConstants.modeSeedToFullNovel,
        'status': 'running',
        'updated_at': '2026-06-10T22:05:00Z',
        'relative_path': 'tracking/long_task_runs/run_new.json',
      },
    );
    await _taskRepository.saveRecord(
      project,
      'tracking/task_queue_runs/queue_new.json',
      const <String, Object?>{
        'id': 'queue_new',
        'status': 'running',
        'completed_steps': 0,
        'updated_at': '2026-06-10T22:05:00Z',
        'relative_path': 'tracking/task_queue_runs/queue_new.json',
      },
    );
    await _completion.future;
    await _taskRepository.saveRecord(
      project,
      'tracking/long_task_runs/run_new.json',
      const <String, Object?>{
        'id': 'run_new',
        'mode': TaskRuntimeConstants.modeSeedToFullNovel,
        'status': 'waiting_gate',
        'updated_at': '2026-06-10T22:05:05Z',
        'relative_path': 'tracking/long_task_runs/run_new.json',
      },
    );
    await _taskRepository.saveRecord(
      project,
      'tracking/task_queue_runs/queue_new.json',
      const <String, Object?>{
        'id': 'queue_new',
        'status': 'stopped',
        'completed_steps': 1,
        'stop_reason': 'waiting_user_choice',
        'updated_at': '2026-06-10T22:05:05Z',
        'relative_path': 'tracking/task_queue_runs/queue_new.json',
      },
    );
    return const <String, Object?>{
      'ok': true,
      'relative_path': 'tracking/task_queue_runs/queue_new.json',
      'summary_path': 'tracking/task_queue_runs/queue_new.md',
      'stop_reason': 'waiting_user_choice',
      'stop_note': '模型正在等待用户选择，队列已暂停。',
      'steps_run': 1,
      'record': <String, Object?>{
        'relative_path': 'tracking/task_queue_runs/queue_new.json',
      },
      'long_task_run_path': 'tracking/long_task_runs/run_new.json',
      'long_task_record': <String, Object?>{
        'relative_path': 'tracking/long_task_runs/run_new.json',
      },
    };
  }
}

class _BlockingScriptedGenerateDraftUseCase
    extends ScriptedGenerateDraftUseCase {
  _BlockingScriptedGenerateDraftUseCase({
    required this.blockDuration,
    required super.resultBuilder,
  });

  final Duration blockDuration;

  @override
  Future<DraftGenerationResult> execute({
    required ProjectDescriptor project,
    required String userPrompt,
    required String modelId,
    String title = '',
    String intent = 'draft',
    JsonMap agent = const <String, Object?>{},
    JsonMap selectedCollaborationGroup = const <String, Object?>{},
    String sessionContext = '',
    JsonMap requestOptions = const <String, Object?>{},
    JsonMap contextSettings = const <String, Object?>{},
    JsonMap modelProfile = const <String, Object?>{},
    JsonMap skillRoutingContext = const <String, Object?>{},
    AppSettings? subAgentRuntimeSettings,
    List<ProjectAgentBinding> subAgentBindings = const <ProjectAgentBinding>[],
    String subAgentBindingModeId = '',
    String subAgentBindingStageId = '',
    List<String> exposedToolIds = const <String>[],
    List<Object?> memorySections = const <Object?>[],
    List<Object?> expressionConstraintProfiles = const <Object?>[],
    List<Object?> projectExpressionConstraintBindings = const <Object?>[],
    JsonMap writingExecutionConstraints = const <String, Object?>{},
    List<Object?> projectFileSectionPlan = const <Object?>[],
    JsonMap projectFileContents = const <String, Object?>{},
    String activeDocumentPath = '',
    String activeDocumentBody = '',
    DraftGenerationCancellationToken? cancellationToken,
    void Function(DraftGenerationProgress progress)? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < blockDuration) {}
    return resultBuilder(
      project: project,
      userPrompt: userPrompt,
      modelId: modelId,
    );
  }
}
