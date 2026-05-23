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
      expect(confirm['enabled'], isTrue);
      expect(markdown, contains('长任务运行中心'));
      expect(markdown, contains('可操作：'));
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
  });
}
