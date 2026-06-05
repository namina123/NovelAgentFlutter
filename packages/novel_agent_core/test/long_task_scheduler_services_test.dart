import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Long task scheduler services', () {
    final modeService = LongTaskModeService();
    final strategyService = LongTaskModeStrategyService(
      modeService: modeService,
    );
    final profileService = LongTaskControllerProfileService(
      modeService: modeService,
      strategyService: strategyService,
    );
    final loopGuard = LongTaskLoopGuardService(profileService: profileService);
    final stopAfterStep = LongTaskStopAfterStepService(
      profileService: profileService,
      modeService: modeService,
    );
    final finishDisposition = LongTaskFinishDispositionService(
      profileService: profileService,
    );
    final taskSummaryService = LongTaskTaskSummaryService();
    final taskDefinitionService = TaskDefinitionService();
    final taskSelectionService = TaskSelectionService(
      taskDefinitionService: taskDefinitionService,
    );
    final unattendedStrategyService = LongTaskUnattendedStrategyService(
      modeService: modeService,
      strategyService: strategyService,
      profileService: profileService,
    );
    final nextBatchPlanService = LongTaskNextBatchPlanService(
      modeService: modeService,
      profileService: profileService,
      unattendedStrategyService: unattendedStrategyService,
      taskSummaryService: taskSummaryService,
      taskSelectionService: taskSelectionService,
    );
    final runCenterContractService = LongTaskRunCenterContractService(
      nextBatchPlanService: nextBatchPlanService,
      taskSummaryService: taskSummaryService,
    );
    final runCenterMarkdown = LongTaskRunCenterMarkdownRenderer();
    final recoveryService = LongTaskRecoveryService();
    final schedulerTickPlanService = LongTaskSchedulerTickPlanService(
      modeService: modeService,
      recoveryService: recoveryService,
      nextBatchPlanService: nextBatchPlanService,
      runCenterContractService: runCenterContractService,
    );
    final schedulerMarkdown = LongTaskSchedulerMarkdownRenderer();

    test('builds controller profile and loop guard for supervised mode', () {
      // 中文注释: 这里验证模式画像和循环守卫会在监督式模式下自动收紧为单步运行。
      final profile = profileService.controllerProfile(
        TaskRuntimeConstants.modeSupervisedChapterQueue,
      );
      final guard = loopGuard.loopGuard(
        1,
        1000,
        options: <String, Object?>{
          'mode': TaskRuntimeConstants.modeSupervisedChapterQueue,
        },
      );

      expect(profile['checkpoint_policy'], 'after_each_chapter');
      expect(profile['max_steps'], 1);
      expect(guard['stop'], isTrue);
      expect(guard['reason'], 'max_steps');
    });

    test(
      'stops after planning/sample boundaries and computes finish disposition',
      () {
        // 中文注释: 这里覆盖单步后停机规则，确保规划与失败都能落到正确控制分支。
        final planningStop = stopAfterStep.stopAfterStep(
          <String, Object?>{'mode': TaskRuntimeConstants.modeSeedToFullNovel},
          <String, Object?>{
            'task_type': 'planning',
            'status': TaskRuntimeConstants.statusSucceeded,
            'metadata': <String, Object?>{'stage': 'planning'},
          },
          <String, Object?>{
            'ok': true,
            'output_paths': <Object?>['outline/总纲.md'],
            'response': <String, Object?>{},
          },
        );
        final failedStop = stopAfterStep.stopAfterStep(
          <String, Object?>{
            'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
          },
          <String, Object?>{
            'task_type': 'chapter',
            'status': TaskRuntimeConstants.statusRunning,
          },
          <String, Object?>{'ok': false, 'error': '模型失败'},
        );
        final finish = finishDisposition.finishDisposition(
          'step_failed',
          1,
          options: <String, Object?>{
            'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
          },
        );

        expect(planningStop['reason'], 'planning_completed');
        expect(planningStop['long_task_status'], 'paused');
        expect(failedStop['reason'], 'step_failed');
        expect(finish['record_action'], 'pause');
        expect(finish['ok'], isFalse);
      },
    );

    test(
      'builds unattended strategy and batch plan with milestone boundary',
      () {
        // 中文注释: 这里验证种子模式会在规划任务后形成一批可派发任务并声明边界。
        final tasks = <Object?>[
          <String, Object?>{
            'id': 'planning',
            'title': '规划',
            'task_type': 'planning',
            'mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'status': TaskRuntimeConstants.statusQueued,
            'depends_on': <Object?>[],
            'metadata': <String, Object?>{'sort_order': 1, 'stage': 'planning'},
            'output_paths': <Object?>['outline/总纲.md'],
          },
          <String, Object?>{
            'id': 'checkpoint_outline',
            'title': '检查点',
            'task_type': 'checkpoint',
            'mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'status': TaskRuntimeConstants.statusWaitingUser,
            'depends_on': <Object?>['planning'],
            'metadata': <String, Object?>{
              'sort_order': 2,
              'stage': 'checkpoint',
            },
          },
        ];

        final strategy = unattendedStrategyService.unattendedStrategy(
          <String, Object?>{'mode': TaskRuntimeConstants.modeSeedToFullNovel},
          tasks,
        );
        final batch = nextBatchPlanService.nextBatchPlan(<String, Object?>{
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'status': TaskRuntimeConstants.statusRunning,
        }, tasks);

        expect(strategy['autonomy_level'], 'milestone_gated');
        expect(batch['action'], 'dispatch_batch');
        expect(batch['boundary_reason'], 'planning_review_boundary');
        expect((batch['tasks'] as List<Object?>).length, 1);
      },
    );

    test('waits on ready checkpoint and exposes run center controls', () {
      // 中文注释: 这里验证检查点到达后运行中心会切换为等待用户并开放确认入口。
      final tasks = <Object?>[
        <String, Object?>{
          'id': 'chapter_001',
          'title': '第一章',
          'task_type': 'chapter',
          'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
          'status': TaskRuntimeConstants.statusSucceeded,
          'depends_on': <Object?>[],
          'metadata': <String, Object?>{'sort_order': 1, 'stage': 'draft'},
        },
        <String, Object?>{
          'id': 'checkpoint_001',
          'title': '检查点',
          'task_type': 'checkpoint',
          'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
          'status': TaskRuntimeConstants.statusWaitingUser,
          'depends_on': <Object?>['chapter_001'],
          'relative_path': 'tracking/checkpoint_001.json',
          'metadata': <String, Object?>{'sort_order': 2, 'stage': 'checkpoint'},
        },
      ];

      final contract = runCenterContractService
          .runCenterContract(<String, Object?>{
            'id': 'run_wait',
            'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
            'status': TaskRuntimeConstants.statusRunning,
          }, tasks);
      final markdown = runCenterMarkdown.renderMarkdown(contract);
      final controls = (contract['controls'] as List<Object?>)
          .whereType<Map<String, Object?>>()
          .toList(growable: false);
      final confirm = controls.firstWhere(
        (item) => item['id'] == 'confirm_checkpoint',
      );

      expect(contract['reason'], 'waiting_user_checkpoint');
      expect(contract['phase'], 'waiting_checkpoint');
      expect(contract['waiting_user'], isTrue);
      expect(
        ValueReaders.stringValue(
          ValueReaders.mapValue(contract['resume_brief'])['resume_title'],
        ),
        '当前停在用户确认点',
      );
      expect(
        ValueReaders.stringValue(
          ValueReaders.mapValue(
            contract['resume_brief'],
          )['next_action_summary'],
        ),
        contains('处理检查点'),
      );
      expect(confirm['enabled'], isTrue);
      expect(markdown, contains('长任务运行中心'));
      expect(markdown, contains('阶段：等待检查点'));
      expect(markdown, contains('可操作：'));
    });

    test('builds resume brief for paused and failed states', () {
      final pausedContract = runCenterContractService.runCenterContract(
        <String, Object?>{
          'id': 'run_pause',
          'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
          'status': TaskRuntimeConstants.statusPaused,
          'stop_reason': 'manual_pause',
        },
        <Object?>[
          <String, Object?>{
            'id': 'chapter_002',
            'title': '第二章',
            'task_type': 'chapter',
            'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
            'status': TaskRuntimeConstants.statusQueued,
            'relative_path': 'tasks/chapter_002.json',
            'depends_on': <Object?>[],
            'metadata': <String, Object?>{'sort_order': 1},
          },
        ],
      );
      final pausedBrief = ValueReaders.mapValue(pausedContract['resume_brief']);
      expect(ValueReaders.stringValue(pausedBrief['resume_title']), '长任务已暂停');
      expect(
        ValueReaders.stringValue(pausedBrief['resume_summary']),
        contains('暂停'),
      );
      expect(
        ValueReaders.boolValue(pausedBrief['requires_user_action']),
        isTrue,
      );

      final failedContract = runCenterContractService.runCenterContract(
        <String, Object?>{
          'id': 'run_failed',
          'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
          'status': TaskRuntimeConstants.statusRunning,
        },
        <Object?>[
          <String, Object?>{
            'id': 'chapter_fail',
            'title': '失败章节',
            'task_type': 'chapter',
            'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
            'status': TaskRuntimeConstants.statusFailed,
            'relative_path': 'tasks/chapter_fail.json',
            'depends_on': <Object?>[],
            'metadata': <String, Object?>{'sort_order': 1},
          },
        ],
      );
      final failedBrief = ValueReaders.mapValue(failedContract['resume_brief']);
      expect(
        ValueReaders.stringValue(failedBrief['resume_title']),
        '长任务停在失败节点',
      );
      expect(
        ValueReaders.stringValue(failedBrief['last_step_summary']),
        contains('失败章节'),
      );
      expect(
        ValueReaders.stringValue(failedBrief['next_action_summary']),
        contains('处理失败任务'),
      );
    });

    test('builds scheduler tick plan for dispatch and recovery branches', () {
      // 中文注释: 这里同时覆盖普通派发和失败恢复，确认调度器能稳定驱动 GUI/CLI 共用控制层。
      final dispatchTasks = <Object?>[
        <String, Object?>{
          'id': 'chapter_001',
          'title': '第一章',
          'task_type': 'chapter',
          'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
          'status': TaskRuntimeConstants.statusQueued,
          'depends_on': <Object?>[],
          'metadata': <String, Object?>{'sort_order': 1, 'stage': 'draft'},
          'relative_path': 'tasks/chapter_001.json',
        },
      ];
      final dispatchPlan = schedulerTickPlanService.schedulerTickPlan(
        <String, Object?>{
          'id': 'run_dispatch',
          'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
          'status': TaskRuntimeConstants.statusRunning,
        },
        dispatchTasks,
        options: <String, Object?>{'worker_enabled': true},
      );

      final recoveryPlan = schedulerTickPlanService.schedulerTickPlan(
        <String, Object?>{
          'id': 'run_failure',
          'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
          'status': TaskRuntimeConstants.statusRunning,
        },
        <Object?>[
          <String, Object?>{
            'id': 'chapter_fail',
            'title': '失败章节',
            'task_type': 'chapter',
            'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
            'status': TaskRuntimeConstants.statusFailed,
            'depends_on': <Object?>[],
            'metadata': <String, Object?>{'sort_order': 1},
          },
        ],
      );

      expect(dispatchPlan['action'], 'dispatch_batch');
      expect(dispatchPlan['should_dispatch'], isTrue);
      expect(dispatchPlan['host_command'], 'run_long_task_batch');
      expect(recoveryPlan['action'], 'pause_for_failure');
      expect(
        schedulerMarkdown.renderMarkdown(dispatchPlan),
        contains('长任务后台调度'),
      );
    });

    test(
      'builds scheduler tick plan for shared repair and manual attention actions',
      () {
        final repairPlan = schedulerTickPlanService.schedulerTickPlan(
          <String, Object?>{
            'id': 'run_repair',
            'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
            'status': TaskRuntimeConstants.statusPaused,
            'last_writing_execution_result': <String, Object?>{
              'execution_id': 'task_repair',
              'workflow_kind': 'workflow_task',
              'overall_status':
                  WritingExecutionOutcomeStatuses.recoverableFailure,
              'summary': '正文未真正落盘，需要补写。',
              'delivery': const <String, Object?>{
                'present': true,
                'state': 'missing_output_recoverable',
                'summary': '正文未真正落盘，需要补写。',
                'blocks_progress': true,
              },
              'constraints': const <String, Object?>{},
              'information': const <String, Object?>{},
              'collaboration': const <String, Object?>{},
              'recovery': const <String, Object?>{},
              'next_action': '',
              'blocks_progress': true,
              'retryable': true,
              'requires_user_action': false,
              'schema_version': 1,
              'metadata': const <String, Object?>{},
            },
          },
          const <Object?>[],
        );
        final manualAttentionPlan = schedulerTickPlanService.schedulerTickPlan(
          <String, Object?>{
            'id': 'run_manual_attention',
            'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
            'status': TaskRuntimeConstants.statusPaused,
            'last_writing_execution_result': <String, Object?>{
              'execution_id': 'task_manual',
              'workflow_kind': 'workflow_task',
              'overall_status':
                  WritingExecutionOutcomeStatuses.contentQualityIssue,
              'summary': '正文质量不达标，需要人工复核。',
              'delivery': const <String, Object?>{
                'present': true,
                'state': 'invalid_output_rewrite_required',
                'summary': '正文质量不达标，需要人工复核。',
                'blocks_progress': true,
              },
              'constraints': const <String, Object?>{},
              'information': const <String, Object?>{},
              'collaboration': const <String, Object?>{},
              'recovery': const <String, Object?>{},
              'next_action': '',
              'blocks_progress': true,
              'retryable': false,
              'requires_user_action': false,
              'schema_version': 1,
              'metadata': const <String, Object?>{},
            },
          },
          const <Object?>[],
        );

        expect(repairPlan['action'], 'pause_for_repair');
        expect(manualAttentionPlan['action'], 'pause_for_manual_attention');
      },
    );
  });
}
