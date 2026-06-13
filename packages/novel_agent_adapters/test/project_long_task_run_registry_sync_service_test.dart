import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_adapters/src/runtime/project_long_task_run_registry_sync_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectLongTaskRunRegistrySyncService', () {
    late Directory tempDirectory;
    late LocalProjectWorkspacePort workspacePort;
    late ProjectTaskRepository taskRepository;
    late LongTaskSupervisor supervisor;
    late ProjectLongTaskRunRegistrySyncService service;
    late ProjectDescriptor project;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel_agent_run_registry_sync_test_',
      );
      workspacePort = LocalProjectWorkspacePort();
      taskRepository = ProjectTaskRepository(workspacePort: workspacePort);
      supervisor = LongTaskSupervisor(
        runRegistry: LocalLongTaskRunRegistry(
          settingsRootPath: tempDirectory.path,
        ),
      );
      service = ProjectLongTaskRunRegistrySyncService(
        supervisor: supervisor,
        taskRepository: taskRepository,
      );
      project = ProjectDescriptor(
        id: 'run_registry_sync_project',
        name: '运行实例同步测试',
        rootPath: '${tempDirectory.path}${Platform.pathSeparator}project',
        projectType: 'long_novel',
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'mirrors running project long task record into global registry',
      () async {
        await taskRepository.saveTasks(project, <JsonMap>[
          <String, Object?>{
            'id': 'planning',
            'title': '规划：扩展作品规格与总纲',
            'task_type': 'planning',
            'status': TaskRuntimeConstants.statusRunning,
            'relative_path': 'tasks/planning.json',
          },
          <String, Object?>{
            'id': 'chapter_001',
            'title': '样章：第01章',
            'task_type': 'chapter',
            'status': TaskRuntimeConstants.statusQueued,
            'relative_path': 'tasks/chapter_001.json',
          },
        ]);

        await service.syncRecord(project, <String, Object?>{
          'id': 'plan_001_run',
          'relative_path': 'tracking/long_task_runs/plan_001_run.json',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'runtime_baseline_id': 'continuous_autonomous',
          'strategy': <String, Object?>{
            'transaction_model': 'plan_then_sample_then_series',
          },
          'status': TaskRuntimeConstants.statusRunning,
          'created_at': '2026-06-13T02:28:45.000000Z',
          'updated_at': '2026-06-13T02:29:13.000000Z',
        });

        final runs = await supervisor.listProjectRuns(project.rootPath);
        expect(runs, hasLength(1));
        expect(runs.single.id, 'plan_001_run');
        expect(runs.single.status, LongTaskRunStatus.running);
        expect(runs.single.activeTaskId, 'planning');
        expect(runs.single.activeTaskTitle, '规划：扩展作品规格与总纲');
      },
    );

    test('projects failed task state as manual attention run', () async {
      await taskRepository.saveTasks(project, <JsonMap>[
        <String, Object?>{
          'id': 'chapter_001',
          'title': '样章：第01章',
          'task_type': 'chapter',
          'status': TaskRuntimeConstants.statusFailed,
          'relative_path': 'tasks/chapter_001.json',
        },
      ]);

      await service.syncRecord(project, <String, Object?>{
        'id': 'plan_002_run',
        'relative_path': 'tracking/long_task_runs/plan_002_run.json',
        'mode': TaskRuntimeConstants.modeSeedToFullNovel,
        'runtime_baseline_id': 'continuous_autonomous',
        'status': TaskRuntimeConstants.statusRunning,
        'created_at': '2026-06-13T02:36:11.000000Z',
        'updated_at': '2026-06-13T02:38:29.000000Z',
        'stop_note': '自动重试预算已耗尽，等待人工处理。',
      });

      final run = await supervisor.loadRun('plan_002_run');
      expect(run, isNotNull);
      expect(run!.status, LongTaskRunStatus.failedManualAttention);
      expect(run.stopReason, 'failed_task');
      expect(run.activeTaskTitle, '样章：第01章');
      expect(
        ValueReaders.stringValue(run.metadata['record_relative_path']),
        'tracking/long_task_runs/plan_002_run.json',
      );
    });

    test(
      'ignores obsolete planner waiting user sidecar once checkpoint chain has advanced',
      () async {
        await taskRepository.saveTasks(project, <JsonMap>[
          <String, Object?>{
            'id': 'wait_user_confirmation',
            'title': '等待用户确认',
            'task_type': 'agent_task',
            'status': TaskRuntimeConstants.statusWaitingUser,
            'relative_path': 'tasks/等待用户确认.task.json',
            'metadata': <String, Object?>{
              'plan_id': 'plan_003',
              'generated_by': 'LongTaskPlanner',
              'stage': 'planning',
            },
          },
          <String, Object?>{
            'id': 'plan_003_checkpoint_001',
            'title': '检查点：确认样章',
            'task_type': 'checkpoint',
            'status': TaskRuntimeConstants.statusSucceeded,
            'relative_path': 'tasks/plan_003_checkpoint_001.json',
            'metadata': <String, Object?>{
              'plan_id': 'plan_003',
              'generated_by': 'LongTaskPlanner',
              'stage': 'checkpoint',
            },
          },
          <String, Object?>{
            'id': 'plan_003_chapter_002',
            'title': '第02章',
            'task_type': 'chapter',
            'status': TaskRuntimeConstants.statusQueued,
            'relative_path': 'tasks/plan_003_chapter_002.json',
            'depends_on': const <Object?>['plan_003_checkpoint_001'],
            'metadata': <String, Object?>{
              'plan_id': 'plan_003',
              'generated_by': 'LongTaskPlanner',
              'stage': 'series',
            },
          },
        ]);

        await service.syncRecord(project, <String, Object?>{
          'id': 'plan_003_run',
          'relative_path': 'tracking/long_task_runs/plan_003_run.json',
          'plan_id': 'plan_003',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'runtime_baseline_id': 'continuous_autonomous',
          'status': TaskRuntimeConstants.statusRunning,
          'created_at': '2026-06-13T11:00:00.000000Z',
          'updated_at': '2026-06-13T11:05:00.000000Z',
        });

        final run = await supervisor.loadRun('plan_003_run');
        expect(run, isNotNull);
        expect(run!.status, LongTaskRunStatus.running);
        expect(run.activeTaskId, 'plan_003_chapter_002');
        expect(run.activeTaskTitle, '第02章');
        expect(run.stopReason, isEmpty);
      },
    );
  });
}
