import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/task_center/application/services/task_center_view_data_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  test('TaskCenterViewDataService projects long task run contract fields', () {
    const service = TaskCenterViewDataService();

    final viewData = service.build(
      tasks: const <JsonMap>[],
      modeDefinitions: const <JsonMap>[],
      selectedTaskId: '',
      detailBody: '',
      queueSummary: '',
      schedulerSummary: '',
      chainMarkdown: '',
      longTaskRuns: const <JsonMap>[
        <String, Object?>{
          'relative_path': 'tracking/long_task_runs/run_001.json',
          'status': 'running',
          'runtime_baseline_id': 'chapter_collaboration_autorun',
          'mode': 'human_outline_ai_draft',
          'updated_at': '2026-05-31T20:30:00Z',
          'run_center_contract': <String, Object?>{
            'status_label': '运行中',
            'phase_label': '执行当前任务',
            'waiting_user': true,
            'active_task_title': '第 8 章',
            'updated_at': '2026-05-31T20:31:00Z',
            'control_summary': '可操作：暂停、停止',
            'progress': <String, Object?>{'overall_percent': 42},
          },
        },
      ],
      taskQueueRuns: const <JsonMap>[],
      selectedLongTaskRunPath: 'tracking/long_task_runs/run_001.json',
      selectedTaskQueueRunPath: '',
      longTaskRunLog: '',
      taskQueueRunLog: '',
    );

    expect(viewData.longTaskRuns, hasLength(1));
    final item = viewData.longTaskRuns.single;
    expect(item.statusLabel, '运行中');
    expect(item.phaseLabel, '执行当前任务');
    expect(item.progressPercent, 42);
    expect(item.activeTaskTitle, '第 8 章');
    expect(item.updatedAt, '2026-05-31T20:31:00Z');
    expect(item.isWaitingUser, isTrue);
    expect(item.controlSummary, '可操作：暂停、停止');
    expect(item.isSelected, isTrue);
    expect(item.subtitle, contains('执行当前任务'));
    expect(item.subtitle, contains('42%'));
    expect(item.subtitle, contains('第 8 章'));
    expect(item.subtitle, contains('等待确认'));
  });

  test('TaskCenterViewDataService renders resume brief from run contract', () {
    const service = TaskCenterViewDataService();

    final body = service.buildResumeBriefBody(
      const <String, Object?>{
        'run_center_contract': <String, Object?>{
          'resume_brief': <String, Object?>{
            'resume_title': '当前停在用户确认点',
            'resume_summary': '等待你确认检查点。',
            'last_step_summary': '最近停在：检查点（tasks/checkpoint.json）',
            'next_action_summary': '建议下一步：处理检查点',
            'requires_user_action': true,
            'action_package_available': true,
            'revision_resolution_available': false,
          },
        },
      },
      checkpointActionPackage: const <String, Object?>{'ok': true},
    );

    expect(body, contains('## 恢复现场'));
    expect(body, contains('当前停在用户确认点'));
    expect(body, contains('最近停在：检查点'));
    expect(body, contains('建议下一步：处理检查点'));
    expect(body, contains('检查点动作包'));
    expect(body, isNot(contains('run_center_contract')));
    expect(body, isNot(contains('requires_user_action')));
    expect(body, isNot(contains('action_package_available')));
    expect(body, isNot(contains('revision_resolution_available')));
  });

  test(
    'TaskCenterViewDataService defaults outline path to canonical story outline',
    () {
      const service = TaskCenterViewDataService();

      final viewData = service.build(
        tasks: const <JsonMap>[],
        modeDefinitions: const <JsonMap>[],
        selectedTaskId: '',
        detailBody: '',
        queueSummary: '',
        schedulerSummary: '',
        chainMarkdown: '',
        longTaskRuns: const <JsonMap>[],
        taskQueueRuns: const <JsonMap>[],
        selectedLongTaskRunPath: '',
        selectedTaskQueueRunPath: '',
        longTaskRunLog: '',
        taskQueueRunLog: '',
      );

      expect(viewData.defaultOutlinePath, 'outlines/story/总纲.md');
      expect(
        viewData.defaultChapterLength.enableChapterWordConstraints,
        isTrue,
      );
      expect(viewData.defaultChapterLength.chapterWordTarget, 2000);
      expect(viewData.defaultChapterLength.sampleChapterWordTarget, 1800);
    },
  );

  test(
    'TaskCenterViewDataService projects chapter length defaults from runtime profile options',
    () {
      const service = TaskCenterViewDataService();

      final viewData = service.build(
        tasks: const <JsonMap>[],
        modeDefinitions: const <JsonMap>[],
        selectedTaskId: '',
        detailBody: '',
        queueSummary: '',
        schedulerSummary: '',
        chainMarkdown: '',
        longTaskRuns: const <JsonMap>[],
        taskQueueRuns: const <JsonMap>[],
        selectedLongTaskRunPath: '',
        selectedTaskQueueRunPath: '',
        longTaskRunLog: '',
        taskQueueRunLog: '',
        runtimeProfile: const ProjectRuntimeProfile(
          projectType: 'long_novel',
          runtimeBaselineId: 'continuous_autonomous',
          runtimeMode: TaskRuntimeConstants.modeSeedToFullNovel,
          initialRunOptions: <String, Object?>{
            'enable_chapter_word_constraints': false,
            'chapter_word_target': 3200,
            'chapter_word_min': 2600,
            'chapter_word_max': 4200,
            'sample_chapter_word_target': 2400,
            'sample_chapter_word_min': 1800,
            'sample_chapter_word_max': 3000,
          },
        ),
      );

      expect(
        viewData.defaultChapterLength.enableChapterWordConstraints,
        isFalse,
      );
      expect(viewData.defaultChapterLength.chapterWordTarget, 3200);
      expect(viewData.defaultChapterLength.chapterWordMin, 2600);
      expect(viewData.defaultChapterLength.chapterWordMax, 4200);
      expect(viewData.defaultChapterLength.sampleChapterWordTarget, 2400);
      expect(viewData.defaultChapterLength.sampleChapterWordMin, 1800);
      expect(viewData.defaultChapterLength.sampleChapterWordMax, 3000);
    },
  );

  test(
    'TaskCenterViewDataService prefers active waiting task over stale succeeded selection',
    () {
      const service = TaskCenterViewDataService();

      final resolved = service.resolveSelectedTaskId(
        tasks: const <JsonMap>[
          <String, Object?>{
            'relative_path': 'tasks/planning.json',
            'status': 'succeeded',
          },
          <String, Object?>{
            'relative_path': 'tasks/chapter_001.json',
            'status': 'waiting_user',
          },
        ],
        selectedTaskId: 'tasks/planning.json',
        selectedLongTaskRun: const <String, Object?>{
          'run_center_contract': <String, Object?>{
            'active_task': <String, Object?>{
              'relative_path': 'tasks/chapter_001.json',
            },
          },
        },
      );

      expect(resolved, 'tasks/chapter_001.json');
    },
  );

  test(
    'TaskCenterViewDataService prefers active waiting task from selected long task run when stale selection has same priority',
    () {
      const service = TaskCenterViewDataService();

      final resolved = service.resolveSelectedTaskId(
        tasks: const <JsonMap>[
          <String, Object?>{
            'relative_path': 'tasks/write_spec.json',
            'status': 'waiting_user',
            'task_type': 'agent_task',
          },
          <String, Object?>{
            'relative_path': 'tasks/update_profile.json',
            'status': 'waiting_user',
            'task_type': 'planning',
          },
        ],
        selectedTaskId: 'tasks/write_spec.json',
        selectedLongTaskRun: const <String, Object?>{
          'run_center_contract': <String, Object?>{
            'active_task': <String, Object?>{
              'relative_path': 'tasks/update_profile.json',
            },
          },
        },
      );

      expect(resolved, 'tasks/update_profile.json');
    },
  );

  test(
    'TaskCenterViewDataService prefers waiting user choice task over stale waiting planning selection',
    () {
      const service = TaskCenterViewDataService();

      final resolved = service.resolveSelectedTaskId(
        tasks: const <JsonMap>[
          <String, Object?>{
            'relative_path': 'tasks/planning.json',
            'status': 'waiting_user',
            'task_type': 'planning',
          },
          <String, Object?>{
            'relative_path': 'tasks/chapter_001.json',
            'status': 'waiting_user',
            'task_type': 'chapter',
            'waiting_for_user_choice': true,
          },
        ],
        selectedTaskId: 'tasks/planning.json',
      );

      expect(resolved, 'tasks/chapter_001.json');
    },
  );

  test(
    'TaskCenterViewDataService prefers higher priority checkpoint over preferred active planning task',
    () {
      const service = TaskCenterViewDataService();

      final resolved = service.resolveSelectedTaskId(
        tasks: const <JsonMap>[
          <String, Object?>{
            'relative_path': 'tasks/planning.json',
            'status': 'waiting_user',
            'task_type': 'planning',
          },
          <String, Object?>{
            'relative_path': 'tasks/checkpoint_outline.json',
            'status': 'waiting_user',
            'task_type': 'checkpoint',
          },
        ],
        selectedTaskId: '',
        selectedLongTaskRun: const <String, Object?>{
          'run_center_contract': <String, Object?>{
            'active_task': <String, Object?>{
              'relative_path': 'tasks/planning.json',
            },
          },
        },
      );

      expect(resolved, 'tasks/checkpoint_outline.json');
    },
  );

  test(
    'TaskCenterViewDataService prefers queue source task when constraint gate pause leaves followup checkpoint on succeeded task',
    () {
      const service = TaskCenterViewDataService();

      final resolved = service.resolveSelectedTaskId(
        tasks: const <JsonMap>[
          <String, Object?>{
            'relative_path': 'tasks/plan.json',
            'status': 'retrying',
            'task_type': 'planning',
          },
          <String, Object?>{
            'relative_path': 'tasks/source_agent_task.json',
            'status': 'succeeded',
            'task_type': 'agent_task',
            'checkpoint_review_path': 'tracking/checkpoint_reviews/t2.json',
          },
        ],
        selectedTaskId: 'tasks/plan.json',
        selectedTaskQueueRun: const <String, Object?>{
          'stop_reason': 'constraint_gate_pause',
          'last_task_relative_path': 'tasks/source_agent_task.json',
        },
      );

      expect(resolved, 'tasks/source_agent_task.json');
    },
  );

  test(
    'TaskCenterViewDataService projects waiting user options into action group and resume brief',
    () {
      const service = TaskCenterViewDataService();
      const task = <String, Object?>{
        'relative_path': 'tasks/chapter_001.json',
        'status': 'waiting_user',
      };
      const execution = <String, Object?>{
        'pending_user_options': <Object?>[
          <String, Object?>{
            'label': '保留旧入口',
            'description': '让第一章先保持既有冲突入口。',
            'prompt': '保留旧入口',
            'source_question': '第一章先走哪个冲突入口？',
            'approval_record_id': 'approval_001',
            'approval_option_id': 'allow_once',
          },
        ],
      };

      final group = service.buildUserOptionActionGroup(
        task: task,
        execution: execution,
      );
      final body = service.buildResumeBriefBody(
        const <String, Object?>{
          'run_center_contract': <String, Object?>{
            'resume_brief': <String, Object?>{'resume_title': '当前停在用户确认点'},
          },
        },
        selectedTask: task,
        selectedTaskExecution: execution,
      );

      expect(group, isNotNull);
      expect(group!.actions.single.invocationKind, 'task_user_option');
      expect(group.actions.single.userOptionPrompt, '保留旧入口');
      expect(group.actions.single.permissionApprovalId, 'approval_001');
      expect(group.actions.single.permissionApprovalOptionId, 'allow_once');
      expect(body, contains('第一章先走哪个冲突入口'));
      expect(body, contains('保留旧入口'));
    },
  );

  test(
    'TaskCenterViewDataService projects enabled checkpoint confirm control into action group',
    () {
      const service = TaskCenterViewDataService();

      final group = service.buildRunControlActionGroup(
        longTaskRun: const <String, Object?>{
          'run_center_contract': <String, Object?>{
            'controls': <Object?>[
              <String, Object?>{
                'id': 'confirm_checkpoint',
                'label': '确认检查点',
                'enabled': true,
                'tone': 'success',
                'host_command': 'apply_long_task_revision',
                'arguments': <String, Object?>{
                  'relative_path': 'tasks/checkpoint_outline.json',
                  'task_id': 'checkpoint_outline',
                  'revision_command': 'confirm_checkpoint',
                },
              },
            ],
          },
        },
        task: const <String, Object?>{
          'id': 'checkpoint_outline',
          'relative_path': 'tasks/checkpoint_outline.json',
          'task_type': 'checkpoint',
          'status': 'waiting_user',
        },
        selectedLongTaskRunPath: 'tracking/long_task_runs/run_001.json',
      );

      expect(group, isNotNull);
      final action = group!.actions.single;
      expect(action.invocationKind, 'run_center_control');
      expect(action.id, 'confirm_checkpoint');
      expect(action.ownerTaskId, 'checkpoint_outline');
      expect(action.longTaskRunPath, 'tracking/long_task_runs/run_001.json');
    },
  );

  test(
    'TaskCenterViewDataService adopts newer task queue run when current selection is stale terminal run',
    () {
      const service = TaskCenterViewDataService();

      final resolved = service.resolveSelectedTaskQueueRunPath(
        taskQueueRuns: const <JsonMap>[
          <String, Object?>{
            'relative_path': 'tracking/task_queue_runs/queue_old.json',
            'status': 'stopped',
            'updated_at': '2026-06-13T19:20:00Z',
          },
          <String, Object?>{
            'relative_path': 'tracking/task_queue_runs/queue_new.json',
            'status': 'running',
            'updated_at': '2026-06-13T19:23:01Z',
          },
        ],
        selectedTaskQueueRunPath: 'tracking/task_queue_runs/queue_old.json',
      );

      expect(resolved, 'tracking/task_queue_runs/queue_new.json');
    },
  );

  test(
    'TaskCenterViewDataService keeps selected task queue run when it is already the active latest run',
    () {
      const service = TaskCenterViewDataService();

      final resolved = service.resolveSelectedTaskQueueRunPath(
        taskQueueRuns: const <JsonMap>[
          <String, Object?>{
            'relative_path': 'tracking/task_queue_runs/queue_old.json',
            'status': 'stopped',
            'updated_at': '2026-06-13T19:20:00Z',
          },
          <String, Object?>{
            'relative_path': 'tracking/task_queue_runs/queue_new.json',
            'status': 'running',
            'updated_at': '2026-06-13T19:23:01Z',
          },
        ],
        selectedTaskQueueRunPath: 'tracking/task_queue_runs/queue_new.json',
      );

      expect(resolved, 'tracking/task_queue_runs/queue_new.json');
    },
  );

  test(
    'TaskCenterViewDataService trusts explicit run control checkpoint target even when selected task is checkpoint',
    () {
      const service = TaskCenterViewDataService();

      final group = service.buildRunControlActionGroup(
        longTaskRun: const <String, Object?>{
          'run_center_contract': <String, Object?>{
            'controls': <Object?>[
              <String, Object?>{
                'id': 'confirm_checkpoint',
                'label': '确认检查点',
                'enabled': true,
                'tone': 'success',
                'host_command': 'apply_long_task_revision',
                'arguments': <String, Object?>{
                  'relative_path': 'tasks/planning.json',
                  'task_id': 'planning',
                  'revision_command': 'confirm_checkpoint',
                },
              },
            ],
          },
        },
        task: const <String, Object?>{
          'id': 'checkpoint_outline',
          'relative_path': 'tasks/checkpoint_outline.json',
          'task_type': 'checkpoint',
          'status': 'waiting_user',
        },
        selectedLongTaskRunPath: 'tracking/long_task_runs/run_001.json',
      );

      expect(group, isNotNull);
      expect(group!.actions.single.id, 'confirm_checkpoint');
      expect(group.actions.single.ownerTaskId, 'planning');
      expect(group.actions.single.ownerTaskPath, 'tasks/planning.json');
    },
  );

  test(
    'TaskCenterViewDataService keeps checkpoint confirm control for paused checkpoint awaiting user confirmation',
    () {
      const service = TaskCenterViewDataService();

      final group = service.buildRunControlActionGroup(
        longTaskRun: const <String, Object?>{
          'run_center_contract': <String, Object?>{
            'controls': <Object?>[
              <String, Object?>{
                'id': 'confirm_checkpoint',
                'label': '确认检查点',
                'enabled': true,
                'tone': 'success',
                'host_command': 'apply_long_task_revision',
                'arguments': <String, Object?>{
                  'relative_path': 'tasks/checkpoint_001.json',
                  'task_id': 'checkpoint_001',
                  'revision_command': 'confirm_checkpoint',
                },
              },
            ],
          },
        },
        task: const <String, Object?>{
          'id': 'checkpoint_001',
          'relative_path': 'tasks/checkpoint_001.json',
          'task_type': 'checkpoint',
          'status': 'paused',
        },
        selectedLongTaskRunPath: 'tracking/long_task_runs/run_001.json',
      );

      expect(group, isNotNull);
      expect(group!.actions.single.id, 'confirm_checkpoint');
      expect(group.actions.single.ownerTaskId, 'checkpoint_001');
    },
  );

  test(
    'TaskCenterViewDataService projects checkpoint confirm control when selected task is follow-up review',
    () {
      const service = TaskCenterViewDataService();

      final group = service.buildRunControlActionGroup(
        longTaskRun: const <String, Object?>{
          'run_center_contract': <String, Object?>{
            'controls': <Object?>[
              <String, Object?>{
                'id': 'confirm_checkpoint',
                'label': '确认检查点',
                'enabled': true,
                'tone': 'success',
                'host_command': 'apply_long_task_revision',
                'arguments': <String, Object?>{
                  'relative_path': 'tasks/checkpoint_004.json',
                  'task_id': 'checkpoint_004',
                  'revision_command': 'confirm_checkpoint',
                },
              },
            ],
          },
        },
        task: const <String, Object?>{
          'id': 'task_1781153911064712',
          'relative_path': 'tasks/task_1781153911064712.json',
          'task_type': 'review',
          'status': 'waiting_user',
        },
        selectedLongTaskRunPath: 'tracking/long_task_runs/run_001.json',
      );

      expect(group, isNotNull);
      expect(group!.actions.single.id, 'confirm_checkpoint');
      expect(group.actions.single.ownerTaskId, 'checkpoint_004');
      expect(group.actions.single.ownerTaskPath, 'tasks/checkpoint_004.json');
      expect(group.summary, contains('检查点确认'));
    },
  );

  test(
    'TaskCenterViewDataService projects retry and skip controls for failed task',
    () {
      const service = TaskCenterViewDataService();

      final group = service.buildRunControlActionGroup(
        longTaskRun: const <String, Object?>{
          'run_center_contract': <String, Object?>{
            'controls': <Object?>[
              <String, Object?>{
                'id': 'retry_failed',
                'label': '重试失败任务',
                'enabled': true,
                'tone': 'accent',
                'host_command': 'long_task_failure_action',
                'arguments': <String, Object?>{
                  'relative_path': 'tasks/planning.json',
                  'task_id': 'planning',
                  'failure_command': 'retry',
                },
              },
              <String, Object?>{
                'id': 'skip_failed',
                'label': '跳过失败任务',
                'enabled': true,
                'tone': 'warm',
                'host_command': 'long_task_failure_action',
                'arguments': <String, Object?>{
                  'relative_path': 'tasks/planning.json',
                  'task_id': 'planning',
                  'failure_command': 'skip',
                },
              },
            ],
          },
        },
        task: const <String, Object?>{
          'id': 'planning',
          'relative_path': 'tasks/planning.json',
          'task_type': 'planning',
          'status': 'failed',
        },
        selectedLongTaskRunPath: 'tracking/long_task_runs/run_001.json',
      );

      expect(group, isNotNull);
      expect(group!.actions, hasLength(2));
      expect(group.actions.first.id, 'retry_failed');
      expect(group.actions.last.id, 'skip_failed');
    },
  );

  test(
    'TaskCenterViewDataService projects generic paused run controls into action group',
    () {
      const service = TaskCenterViewDataService();

      final group = service.buildRunControlActionGroup(
        longTaskRun: const <String, Object?>{
          'run_center_contract': <String, Object?>{
            'controls': <Object?>[
              <String, Object?>{
                'id': 'resume',
                'label': '继续',
                'enabled': true,
                'tone': 'accent',
                'host_command': 'resume_long_task_run',
              },
              <String, Object?>{
                'id': 'stop',
                'label': '停止',
                'enabled': true,
                'tone': 'danger',
                'host_command': 'stop_long_task_run',
              },
            ],
          },
        },
        task: const <String, Object?>{
          'id': 'planning',
          'relative_path': 'tasks/planning.json',
          'task_type': 'planning',
          'status': 'waiting_user',
        },
        selectedLongTaskRunPath: 'tracking/long_task_runs/run_001.json',
      );

      expect(group, isNotNull);
      expect(group!.actions, hasLength(2));
      expect(
        group.actions.map((action) => action.id),
        containsAll(<String>['resume', 'stop']),
      );
      expect(group.actions.first.invocationKind, 'run_center_control');
      expect(group.summary, contains('已暂停'));
    },
  );
}
