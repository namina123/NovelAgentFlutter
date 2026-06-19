import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/task_center/application/services/task_center_refresh_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';

void main() {
  group('TaskCenterRefreshService', () {
    test('builds stable empty view when no project exists', () async {
      const service = TaskCenterRefreshService(
        runtimeQueryPort: _FakeRuntimeQueryPort(),
      );

      final result = await service.refresh(
        const TaskCenterRefreshRequest(
          project: null,
          selectedTaskId: '',
          selectedLongTaskRunPath: '',
          selectedTaskQueueRunPath: '',
          statusMessage: '',
          taskCenterCommandInFlight: false,
          runtimeProfile: null,
          projectStorageStrategy: null,
        ),
      );

      expect(result.tasks, isEmpty);
      expect(result.selectedTaskId, isEmpty);
      expect(result.statusMessage, '请先创建或打开项目。');
      expect(result.viewData.detailBody, contains('请先创建或打开项目。'));
    });

    test('resolves task, run paths and status from runtime contract', () async {
      const service = TaskCenterRefreshService(
        runtimeQueryPort: _FakeRuntimeQueryPort(),
      );

      final result = await service.refresh(
        TaskCenterRefreshRequest(
          project: ProjectDescriptor(
            id: 'project_refresh',
            name: 'refresh',
            rootPath: 'D:/projects/refresh',
          ),
          selectedTaskId: '',
          selectedLongTaskRunPath: '',
          selectedTaskQueueRunPath: '',
          statusMessage: '正在刷新任务中心...',
          taskCenterCommandInFlight: false,
          runtimeProfile: null,
          projectStorageStrategy: ProjectStorageStrategy.markdownProjectStore,
        ),
      );

      expect(result.tasks, hasLength(1));
      expect(result.selectedTaskId, 'tasks/task_001.json');
      expect(
        result.selectedLongTaskRunPath,
        'tracking/long_task_runs/run_001.json',
      );
      expect(
        result.selectedTaskQueueRunPath,
        'tracking/task_queue_runs/queue_001.json',
      );
      expect(result.statusMessage, '当前任务已进入等待确认，可使用右侧动作继续。');
      expect(result.viewData.status, '当前任务已进入等待确认，可使用右侧动作继续。');
      expect(result.viewData.detailBody, contains('待确认任务'));
      expect(result.viewData.longTaskRuns.single.isSelected, isTrue);
      expect(result.viewData.taskQueueRuns.single.isSelected, isTrue);
      expect(result.viewData.resumeBriefBody, contains('恢复现场'));
      expect(result.viewData.actionGroups, hasLength(1));
    });
  });
}

class _FakeRuntimeQueryPort implements TaskCenterRuntimeQueryPort {
  const _FakeRuntimeQueryPort();

  @override
  Future<JsonMap> buildCheckpointGuidanceRevisitPackage(
    ProjectDescriptor project,
    String checkpointReviewPath,
  ) async {
    return const <String, Object?>{
      'ok': true,
      'summary': '长期约束回看',
      'focus_domains': <String>['style'],
      'items': <Object?>[],
    };
  }

  @override
  Future<JsonMap> buildCheckpointReviewActionPackage(
    ProjectDescriptor project,
    String checkpointReviewPath,
  ) async {
    return const <String, Object?>{
      'ok': true,
      'checkpoint_review_path': 'reviews/checkpoint.md',
      'review': <String, Object?>{
        'task': <String, Object?>{'relative_path': 'tasks/task_001.json'},
      },
      'actions': <Object?>[
        <String, Object?>{
          'id': 'revisit_mode_guidance',
          'label': '回看',
          'note': '回看',
          'tone': 'neutral',
          'enabled': true,
          'host_command': 'apply_checkpoint_review_action',
        },
      ],
      'severity_label': '中',
      'action_summary': '可回看',
    };
  }

  @override
  Future<JsonMap> buildRevisionResolution(
    ProjectDescriptor project,
    JsonMap selector,
  ) async {
    return const <String, Object?>{
      'ok': true,
      'checkpoint_review_path': 'reviews/checkpoint.md',
      'task': <String, Object?>{'relative_path': 'tasks/task_001.json'},
      'actions': <Object?>[],
      'stage_label': '处理中',
      'action_summary': '',
    };
  }

  @override
  Future<List<JsonMap>> listLongTaskRuns(
    ProjectDescriptor project, {
    int limit = 12,
  }) async {
    return const <JsonMap>[
      <String, Object?>{
        'relative_path': 'tracking/long_task_runs/run_001.json',
        'status': 'waiting_gate',
        'run_center_contract': <String, Object?>{
          'resume_brief': <String, Object?>{
            'resume_title': '恢复现场',
            'resume_summary': '继续推进。',
            'last_step_summary': '上一步已停下。',
            'next_action_summary': '请继续。',
          },
          'controls': <Object?>[],
          'waiting_user': true,
          'status_label': '等待门禁',
          'phase_label': '等待',
        },
      },
    ];
  }

  @override
  Future<List<JsonMap>> listTaskQueueRuns(
    ProjectDescriptor project, {
    int limit = 12,
  }) async {
    return const <JsonMap>[
      <String, Object?>{
        'relative_path': 'tracking/task_queue_runs/queue_001.json',
        'status': 'completed',
      },
    ];
  }

  @override
  Future<List<JsonMap>> listWorkflowTasks(
    ProjectDescriptor project, {
    JsonMap filters = const <String, Object?>{},
  }) async {
    return const <JsonMap>[
      <String, Object?>{
        'relative_path': 'tasks/task_001.json',
        'id': 'task_001',
        'title': '待确认任务',
        'status': TaskRuntimeConstants.statusWaitingUser,
        'task_type': 'chapter',
        'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
        'metadata': <String, Object?>{'sort_order': 1},
        'depends_on': <Object?>[],
        'output_paths': <Object?>[],
        'created_at': '2026-06-15T00:00:00Z',
      },
    ];
  }

  @override
  Future<JsonMap> loadLongTaskRun(
    ProjectDescriptor project,
    String relativePath,
  ) async {
    return const <String, Object?>{
      'relative_path': 'tracking/long_task_runs/run_001.json',
      'status': 'waiting_gate',
      'run_center_contract': <String, Object?>{
        'resume_brief': <String, Object?>{
          'resume_title': '恢复现场',
          'resume_summary': '继续推进。',
          'last_step_summary': '上一步已停下。',
          'next_action_summary': '请继续。',
        },
        'controls': <Object?>[],
        'waiting_user': true,
        'status_label': '等待门禁',
        'phase_label': '等待',
      },
    };
  }

  @override
  Future<JsonMap> loadTaskQueueRun(
    ProjectDescriptor project,
    String relativePath,
  ) async {
    return const <String, Object?>{
      'relative_path': 'tracking/task_queue_runs/queue_001.json',
      'status': 'completed',
    };
  }

  @override
  Future<JsonMap> loadWorkflowTaskExecution(
    ProjectDescriptor project,
    JsonMap selector,
  ) async {
    return const <String, Object?>{
      'pending_user_options': <Object?>[
        <String, Object?>{
          'label': '继续',
          'description': '继续',
          'prompt': '继续',
          'source_question': '要继续吗？',
        },
      ],
    };
  }

  @override
  List<JsonMap> listTaskRuntimeModes() {
    return const <JsonMap>[
      <String, Object?>{
        'id': TaskRuntimeConstants.modeHumanOutlineAiDraft,
        'name': '人定大纲 AI 写作',
        'description': '',
      },
    ];
  }

  @override
  String renderLongTaskRunMarkdown(JsonMap record) => '# long run';

  @override
  String renderTaskQueueRunMarkdown(JsonMap record) => '# queue run';

  @override
  Future<JsonMap> longTaskSchedulerPlan(
    ProjectDescriptor project, {
    String relativePath = '',
    JsonMap options = const <String, Object?>{},
  }) async {
    return const <String, Object?>{
      'ok': true,
      'action': 'idle',
      'worker_state': 'ready',
      'relative_path': 'tracking/long_task_runs/run_001.json',
      'stop_reason': '',
    };
  }

  @override
  Future<JsonMap> taskQueuePreflight(
    ProjectDescriptor project, {
    JsonMap options = const <String, Object?>{},
  }) async {
    return const <String, Object?>{'runnable': true};
  }

  @override
  Future<JsonMap> workflowChainView(
    ProjectDescriptor project, {
    JsonMap filters = const <String, Object?>{},
  }) async {
    return const <String, Object?>{
      'task_count': 1,
      'chains': <Object?>[],
      'next_task': <String, Object?>{'relative_path': 'tasks/task_001.json'},
      'next_postprocess_task': <String, Object?>{},
    };
  }

  @override
  Future<JsonMap> saveWorkflowChainSnapshot(
    ProjectDescriptor project, {
    JsonMap filters = const <String, Object?>{},
  }) async {
    return const <String, Object?>{
      'ok': true,
      'snapshot_path': 'tracking/workflow_chain_snapshots/snapshot_001.json',
    };
  }
}
