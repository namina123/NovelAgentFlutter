import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Long task runtime entry use cases', () {
    final modeService = LongTaskModeService();
    final pathPolicyService = LongTaskPathPolicyService();
    final strategyService = LongTaskModeStrategyService(
      modeService: modeService,
    );
    final optionService = LongTaskRunOptionService();
    final taskSummaryService = LongTaskTaskSummaryService();
    final recordService = LongTaskRunRecordService(
      modeService: modeService,
      strategyService: strategyService,
      optionService: optionService,
      taskSummaryService: taskSummaryService,
    );
    final planIdentityService = LongTaskRunPlanIdentityService(
      modeService: modeService,
    );
    final runPathService = LongTaskRunPathService(
      pathPolicyService: pathPolicyService,
    );
    final startRunUseCase = StartLongTaskRunUseCase(
      planIdentityService: planIdentityService,
      runRecordService: recordService,
      runPathService: runPathService,
    );
    final taskDefinitionService = TaskDefinitionService();
    final taskSelectionService = TaskSelectionService(
      taskDefinitionService: taskDefinitionService,
    );
    final profileService = LongTaskControllerProfileService(
      modeService: modeService,
      strategyService: strategyService,
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
    final schedulerTickPlanService = LongTaskSchedulerTickPlanService(
      modeService: modeService,
      recoveryService: LongTaskRecoveryService(),
      nextBatchPlanService: nextBatchPlanService,
      runCenterContractService: runCenterContractService,
    );
    final schedulerSnapshotUseCase = BuildLongTaskSchedulerSnapshotUseCase(
      schedulerTickPlanService: schedulerTickPlanService,
      batchOptionService: LongTaskBatchOptionService(),
      schedulerMarkdownRenderer: LongTaskSchedulerMarkdownRenderer(),
    );
    final finalizeStepUseCase = FinalizeLongTaskStepUseCase(
      stepRecorderService: LongTaskRunStepRecorderService(
        taskSummaryService: taskSummaryService,
      ),
      stopAfterStepService: LongTaskStopAfterStepService(
        profileService: profileService,
        modeService: modeService,
      ),
      finishDispositionService: LongTaskFinishDispositionService(
        profileService: profileService,
      ),
      lifecycleService: LongTaskRunLifecycleService(),
    );
    final revisionApplyService = LongTaskRevisionApplyService(
      runPathService: runPathService,
      transitionService: TaskTransitionService(),
      taskDefinitionService: taskDefinitionService,
    );

    test('starts run with derived plan and generated paths', () {
      // 中文注释: 这里验证共用运行入口能从任务池直接推导计划身份并补齐运行路径。
      final result = startRunUseCase.execute(
        <Object?>[
          <String, Object?>{
            'id': 'chapter_001',
            'title': '第一章',
            'task_type': 'chapter',
            'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
            'status': TaskRuntimeConstants.statusQueued,
            'metadata': <String, Object?>{
              'plan_id': 'plan_beta',
              'sort_order': 1,
            },
          },
        ],
        options: const <String, Object?>{'run_id': 'run_beta'},
        createdAt: '2026-05-23T14:00:00Z',
      );

      expect(result['ok'], isTrue);
      expect(result['run_id'], 'run_beta');
      expect(
        result['relative_path'],
        contains('tracking/long_task_runs/run_beta.json'),
      );
      final record = result['record'] as Map<String, Object?>;
      expect(record['plan_id'], 'plan_beta');
      expect(record['summary_path'], contains('run_beta.md'));
    });

    test('builds scheduler snapshot with batch limited options', () {
      // 中文注释: 这里验证共用调度快照会同时产出宿主动作、限流参数和可读摘要。
      final result = schedulerSnapshotUseCase.execute(
        const <String, Object?>{
          'id': 'run_gamma',
          'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
          'status': TaskRuntimeConstants.statusRunning,
        },
        <Object?>[
          <String, Object?>{
            'id': 'chapter_001',
            'title': '第一章',
            'task_type': 'chapter',
            'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
            'status': TaskRuntimeConstants.statusQueued,
            'metadata': <String, Object?>{'sort_order': 1},
          },
        ],
        options: const <String, Object?>{
          'max_steps': 9,
          'worker_enabled': true,
        },
      );

      expect(result['ok'], isTrue);
      final schedulerPlan = result['scheduler_plan'] as Map<String, Object?>;
      final batchOptions =
          result['batch_limited_options'] as Map<String, Object?>;
      expect(schedulerPlan['action'], 'dispatch_batch');
      expect(batchOptions['long_task_batch_action'], 'dispatch_batch');
      expect(result['markdown'], contains('长任务后台调度'));
    });

    test('finalizes step and pauses record at chapter boundary', () {
      // 中文注释: 这里验证单步执行后可直接得到已审计、已停机处理过的新 record。
      final result = finalizeStepUseCase.execute(
        const <String, Object?>{
          'id': 'run_delta',
          'mode': TaskRuntimeConstants.modeSupervisedChapterQueue,
          'status': TaskRuntimeConstants.statusRunning,
          'steps': <Object?>[],
        },
        const <String, Object?>{
          'id': 'chapter_001',
          'title': '第一章',
          'task_type': 'chapter',
          'mode': TaskRuntimeConstants.modeSupervisedChapterQueue,
          'status': TaskRuntimeConstants.statusSucceeded,
        },
        const <String, Object?>{
          'ok': true,
          'output_paths': <Object?>['drafts/第01章.md'],
          'response': <String, Object?>{},
        },
        options: const <String, Object?>{
          'mode': TaskRuntimeConstants.modeSupervisedChapterQueue,
        },
        createdAt: '2026-05-23T14:10:00Z',
      );

      final record = result['record'] as Map<String, Object?>;
      final stopDecision = result['stop_decision'] as Map<String, Object?>;
      expect(stopDecision['reason'], 'supervised_chapter_completed');
      expect(record['status'], TaskRuntimeConstants.statusPaused);
      expect(record['completed_steps'], 1);
    });

    test('applies revision plan in memory and appends new task path', () {
      // 中文注释: 这里验证 revision apply 会更新旧任务并给新增任务补齐 relative_path。
      final result = revisionApplyService.applyRevisionPlan(
        <Object?>[
          <String, Object?>{
            'id': 'checkpoint_001',
            'title': '检查点',
            'task_type': 'checkpoint',
            'status': TaskRuntimeConstants.statusWaitingUser,
            'history': <Object?>[],
          },
        ],
        const <String, Object?>{
          'ok': true,
          'task_updates': <Object?>[
            <String, Object?>{
              'task_id': 'checkpoint_001',
              'status': TaskRuntimeConstants.statusSucceeded,
              'note': '确认继续。',
            },
          ],
          'new_tasks': <Object?>[
            <String, Object?>{
              'id': 'chapter_002',
              'title': '第二章',
              'task_type': 'chapter',
              'status': TaskRuntimeConstants.statusQueued,
              'metadata': <String, Object?>{'sort_order': 2},
            },
          ],
        },
        createdAt: '2026-05-23T14:15:00Z',
      );

      expect(result['ok'], isTrue);
      final tasks = result['tasks'] as List<Object?>;
      expect(tasks, hasLength(2));
      final updated = tasks.first as Map<String, Object?>;
      final appended = tasks.last as Map<String, Object?>;
      expect(updated['status'], TaskRuntimeConstants.statusSucceeded);
      expect((updated['history'] as List<Object?>), isNotEmpty);
      expect(appended['relative_path'], 'tasks/chapter_002.json');
    });
  });
}
