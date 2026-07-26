import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_app/app/routing/app_destination.dart';
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
                executedTools: const <String>[],
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

      harness.controller.showLongTaskStation();
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
}
