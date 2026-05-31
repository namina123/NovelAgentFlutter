import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectLongTaskStationDetailService', () {
    late Directory tempDirectory;
    late ProjectDescriptor project;
    late ProjectTaskRepository taskRepository;
    late ProjectReviewReportService reviewReportService;
    late ProjectLongTaskStationDetailService service;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel_agent_station_detail_test_',
      );
      final workspacePort = LocalProjectWorkspacePort();
      taskRepository = ProjectTaskRepository(workspacePort: workspacePort);
      reviewReportService = ProjectReviewReportService(
        workspacePort: workspacePort,
        taskRepository: taskRepository,
      );
      service = ProjectLongTaskStationDetailService(
        taskRepository: taskRepository,
        reviewReportService: reviewReportService,
      );
      project = ProjectDescriptor(
        id: 'station_detail_project',
        name: '总站详情测试',
        rootPath: tempDirectory.path,
        projectType: 'long_novel',
      );
      await _seedProject(taskRepository, project);
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('loads active chain and recent checkpoint review/repair signals', () async {
      final baseline = const RuntimeBaselineCatalogService().byId(
        'continuous_autonomous',
      )!;
      final run = const RunInstanceFactoryService()
          .createLongTaskInstance(
            runId: 'run_station_demo',
            project: project,
            runtimeBaseline: baseline,
            modeId: TaskRuntimeConstants.modeSeedToFullNovel,
            workflowStrategyId: 'resumable_long_task',
            initialStatus: LongTaskRunStatus.waitingGate,
            now: DateTime.parse('2026-05-26T08:00:00.000Z'),
          )
          .copyWith(
            activeTaskId: 'checkpoint_001',
            activeTaskTitle: '检查点：第一卷收束',
            stopReason: 'waiting_user_checkpoint',
            note: 'checkpoint waiting for user decision',
          );

      final detail = await service.loadForRun(run);

      expect(detail.activeTask, isNotNull);
      expect(detail.activeTask!.id, 'checkpoint_001');
      expect(detail.chain, isNotNull);
      expect(detail.chain!.items, hasLength(3));
      expect(detail.chain!.blockingCheckpointTitles, contains('检查点：第一卷收束'));

      expect(detail.latestCheckpointReview, isNotNull);
      expect(
        detail.latestCheckpointReview!.relativePath,
        'tracking/checkpoint_reviews/ch01_checkpoint.json',
      );
      expect(detail.latestCheckpointReview!.status, 'high');

      expect(detail.latestReviewReport, isNotNull);
      expect(
        detail.latestReviewReport!.relativePath,
        'reviews/continuity/ch01_gate.md',
      );
      expect(detail.latestReviewReport!.title, '第01章连贯性审稿');

      expect(detail.latestRepairTask, isNotNull);
      expect(detail.latestRepairTask!.id, 'revision_001');
      expect(detail.latestRepairTask!.relativePath, 'tasks/revision_001.json');

      expect(detail.blocker.code, 'waiting_user_checkpoint');
      expect(detail.blocker.note, isNotEmpty);
      expect(detail.blocker.detail, contains('当前任务'));
    });
  });
}

Future<void> _seedProject(
  ProjectTaskRepository taskRepository,
  ProjectDescriptor project,
) async {
  await taskRepository.saveTasks(project, <Object?>[
    <String, Object?>{
      'id': 'chapter_001',
      'title': '第01章：风雪旧城',
      'task_type': 'chapter',
      'mode': TaskRuntimeConstants.modeSeedToFullNovel,
      'status': TaskRuntimeConstants.statusSucceeded,
      'relative_path': 'tasks/chapter_001.json',
      'output_paths': <Object?>['chapters/ch01.md'],
      'created_at': '2026-05-26T08:01:00.000Z',
      'updated_at': '2026-05-26T08:06:00.000Z',
      'metadata': <String, Object?>{
        'plan_id': 'plan_alpha',
        'sort_order': 1,
        'stage': 'chapter',
      },
    },
    <String, Object?>{
      'id': 'checkpoint_001',
      'title': '检查点：第一卷收束',
      'task_type': 'checkpoint',
      'mode': TaskRuntimeConstants.modeSeedToFullNovel,
      'status': TaskRuntimeConstants.statusWaitingUser,
      'relative_path': 'tasks/checkpoint_001.json',
      'checkpoint_review_path':
          'tracking/checkpoint_reviews/ch01_checkpoint.json',
      'created_at': '2026-05-26T08:07:00.000Z',
      'updated_at': '2026-05-26T08:10:00.000Z',
      'metadata': <String, Object?>{
        'plan_id': 'plan_alpha',
        'sort_order': 2,
        'stage': 'checkpoint',
        'manual_checkpoint': true,
      },
    },
    <String, Object?>{
      'id': 'revision_001',
      'title': '修订：处理第01章连贯性问题',
      'task_type': 'revision',
      'mode': TaskRuntimeConstants.modeSeedToFullNovel,
      'status': TaskRuntimeConstants.statusQueued,
      'relative_path': 'tasks/revision_001.json',
      'review_report_path': 'reviews/continuity/ch01_gate.md',
      'created_at': '2026-05-26T08:11:00.000Z',
      'updated_at': '2026-05-26T08:12:00.000Z',
      'metadata': <String, Object?>{
        'plan_id': 'plan_alpha',
        'sort_order': 3,
        'stage': 'repair',
        'origin': 'review_report',
        'review_report_path': 'reviews/continuity/ch01_gate.md',
        'origin_checkpoint_review_path':
            'tracking/checkpoint_reviews/ch01_checkpoint.json',
      },
    },
  ]);
  await taskRepository.saveRecord(
    project,
    'tracking/checkpoint_reviews/ch01_checkpoint.json',
    <String, Object?>{
      'id': 'checkpoint_review_ch01',
      'title': '第01章检查点复盘',
      'summary': '当前章在角色动机与伏笔收束上存在继续确认的必要。',
      'action_summary': '建议先人工确认当前检查点，再决定是否继续推进。',
      'severity': 'high',
      'continuation_disposition': 'blocked_wait_user',
      'updated_at': '2026-05-26T08:09:30.000Z',
    },
  );
  await taskRepository.saveRecord(
    project,
    'reviews/continuity/ch01_gate.json',
    <String, Object?>{
      'id': 'review_ch01_gate',
      'title': '第01章连贯性审稿',
      'summary': '需要修补角色动机衔接与一处伏笔提示。',
      'review_type': 'continuity',
      'scope': 'chapters/ch01.md',
      'issues': <Object?>[
        <String, Object?>{
          'id': 'issue_1',
          'title': '角色动机衔接偏弱',
        },
      ],
      'created_at': '2026-05-26T08:10:30.000Z',
      'updated_at': '2026-05-26T08:10:30.000Z',
    },
  );
  await taskRepository.writeTextFile(
    project,
    'reviews/continuity/ch01_gate.md',
    '# 第01章连贯性审稿\n\n- 范围：chapters/ch01.md\n\n需要修补角色动机衔接与一处伏笔提示。',
  );
  await taskRepository.saveRecord(
    project,
    'tracking/long_task_runs/run_station_demo.json',
    <String, Object?>{
      'id': 'run_station_demo',
      'status': 'waiting_gate',
      'stop_reason': 'waiting_user_checkpoint',
      'stop_note': '检查点已创建，请用户决定是否继续推进。',
      'last_task_id': 'checkpoint_001',
      'last_checkpoint_review_path':
          'tracking/checkpoint_reviews/ch01_checkpoint.json',
      'updated_at': '2026-05-26T08:12:30.000Z',
    },
  );
}
