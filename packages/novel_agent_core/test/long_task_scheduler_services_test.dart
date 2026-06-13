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
      'does not pause continuous autonomous revision agent task only because output paths are empty',
      () {
        final decision = stopAfterStep.stopAfterStep(
          <String, Object?>{'mode': TaskRuntimeConstants.modeSeedToFullNovel},
          <String, Object?>{
            'task_type': 'agent_task',
            'mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'status': TaskRuntimeConstants.statusSucceeded,
            'metadata': <String, Object?>{
              'runtime_baseline_id': 'continuous_autonomous',
              'generated_by': 'LongTaskRevision',
            },
          },
          <String, Object?>{
            'ok': true,
            'output_paths': const <Object?>[],
            'response': const <String, Object?>{},
          },
        );

        expect(decision['stop'], isFalse);
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

    test(
      'tightens unattended batch cadence on consecutive structured risk',
      () {
        // 中文注释: 这里验证运行态结构化风险会同步进入 strategy 和 batch plan，而不是只停留在 record 摘要里。
        final tasks = <Object?>[
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
          <String, Object?>{
            'id': 'chapter_002',
            'title': '第二章',
            'task_type': 'chapter',
            'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
            'status': TaskRuntimeConstants.statusQueued,
            'depends_on': <Object?>['chapter_001'],
            'metadata': <String, Object?>{'sort_order': 2, 'stage': 'draft'},
            'relative_path': 'tasks/chapter_002.json',
          },
          <String, Object?>{
            'id': 'chapter_003',
            'title': '第三章',
            'task_type': 'chapter',
            'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
            'status': TaskRuntimeConstants.statusQueued,
            'depends_on': <Object?>['chapter_002'],
            'metadata': <String, Object?>{'sort_order': 3, 'stage': 'draft'},
            'relative_path': 'tasks/chapter_003.json',
          },
        ];

        final record = <String, Object?>{
          'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
          'status': TaskRuntimeConstants.statusRunning,
          'last_checkpoint_review_severity': 'medium',
          'last_writing_execution_category': 'waiting_user',
          'last_information_risk_category': 'checkpoint_user',
          'steps': const <Object?>[
            <String, Object?>{
              'checkpoint_review_severity': 'medium',
              'writing_execution_category': 'success',
              'information_risk_category': 'accept',
            },
            <String, Object?>{
              'checkpoint_review_severity': 'medium',
              'writing_execution_category': 'waiting_user',
              'information_risk_category': 'checkpoint_user',
            },
          ],
        };

        final strategy = unattendedStrategyService.unattendedStrategy(
          record,
          tasks,
          options: const <String, Object?>{
            'max_steps': 4,
            'checkpoint_interval': 3,
          },
        );
        final cadence = ValueReaders.mapValue(strategy['checkpoint_cadence']);
        final batch = nextBatchPlanService.nextBatchPlan(
          record,
          tasks,
          options: const <String, Object?>{
            'max_steps': 4,
            'checkpoint_interval': 3,
          },
        );

        expect(ValueReaders.stringValue(cadence['risk_level']), 'high');
        expect(ValueReaders.intValue(cadence['effective_batch_steps']), 1);
        expect(
          ValueReaders.intValue(cadence['effective_checkpoint_interval']),
          1,
        );
        expect(batch['boundary_reason'], 'risk_tightened_batch');
        expect(batch['recommended_max_steps'], 1);
        expect(ValueReaders.intValue(batch['max_seconds']), 3600);
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
          'status': TaskRuntimeConstants.statusQueued,
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

      expect(contract['reason'], 'checkpoint_task');
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

    test(
      'does not expose confirm checkpoint for blocked checkpoint dependency',
      () {
        final tasks = <Object?>[
          <String, Object?>{
            'id': 'chapter_001',
            'title': '第一章',
            'task_type': 'chapter',
            'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
            'status': TaskRuntimeConstants.statusRunning,
            'depends_on': <Object?>[],
            'relative_path': 'tasks/chapter_001.json',
            'metadata': <String, Object?>{'sort_order': 1, 'stage': 'draft'},
          },
          <String, Object?>{
            'id': 'checkpoint_001',
            'title': '检查点',
            'task_type': 'checkpoint',
            'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
            'status': TaskRuntimeConstants.statusQueued,
            'depends_on': <Object?>['chapter_001'],
            'relative_path': 'tracking/checkpoint_001.json',
            'metadata': <String, Object?>{
              'sort_order': 2,
              'stage': 'checkpoint',
            },
          },
        ];

        final contract = runCenterContractService
            .runCenterContract(<String, Object?>{
              'id': 'run_blocked_checkpoint',
              'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
              'status': TaskRuntimeConstants.statusRunning,
            }, tasks);
        final controls = ValueReaders.mapList(contract['controls']);
        final confirm = controls.firstWhere(
          (item) =>
              ValueReaders.stringValue(item['id']) == 'confirm_checkpoint',
        );

        expect(ValueReaders.boolValue(contract['waiting_user']), isFalse);
        expect(ValueReaders.boolValue(confirm['enabled']), isFalse);
      },
    );

    test(
      'ignores covered failed planning task once later checkpoint and chapters already succeeded',
      () {
        final tasks = <Object?>[
          <String, Object?>{
            'id': 'planning',
            'title': '规划',
            'task_type': 'planning',
            'mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'status': TaskRuntimeConstants.statusFailed,
            'depends_on': <Object?>[],
            'relative_path': 'tasks/planning.json',
            'metadata': <String, Object?>{'sort_order': 1, 'stage': 'planning'},
          },
          <String, Object?>{
            'id': 'checkpoint_outline',
            'title': '检查点：确认总纲',
            'task_type': 'checkpoint',
            'mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'status': TaskRuntimeConstants.statusSucceeded,
            'depends_on': <Object?>['planning'],
            'relative_path': 'tasks/checkpoint_outline.json',
            'metadata': <String, Object?>{
              'sort_order': 2,
              'stage': 'checkpoint',
            },
          },
          <String, Object?>{
            'id': 'chapter_001',
            'title': '第一章',
            'task_type': 'chapter',
            'mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'status': TaskRuntimeConstants.statusSucceeded,
            'depends_on': <Object?>['checkpoint_outline'],
            'relative_path': 'tasks/chapter_001.json',
            'metadata': <String, Object?>{'sort_order': 3, 'stage': 'sample'},
          },
          <String, Object?>{
            'id': 'checkpoint_004',
            'title': '检查点：第 4 章后确认',
            'task_type': 'checkpoint',
            'mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'status': TaskRuntimeConstants.statusWaitingUser,
            'depends_on': <Object?>['chapter_001'],
            'relative_path': 'tasks/checkpoint_004.json',
            'metadata': <String, Object?>{
              'sort_order': 4,
              'stage': 'checkpoint',
            },
          },
        ];

        final batch = nextBatchPlanService.nextBatchPlan(<String, Object?>{
          'id': 'run_covered_failure',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'status': TaskRuntimeConstants.statusRunning,
        }, tasks);
        final contract = runCenterContractService
            .runCenterContract(<String, Object?>{
              'id': 'run_covered_failure',
              'mode': TaskRuntimeConstants.modeSeedToFullNovel,
              'status': TaskRuntimeConstants.statusRunning,
            }, tasks);

        expect(batch['reason'], 'waiting_user_checkpoint');
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(contract['active_task'])['id'],
          ),
          'checkpoint_004',
        );
        final enabledControlIds = ValueReaders.mapList(contract['controls'])
            .where((item) => ValueReaders.boolValue(item['enabled']))
            .map((item) => ValueReaders.stringValue(item['id']));
        expect(enabledControlIds, contains('confirm_checkpoint'));
        expect(enabledControlIds, isNot(contains('retry_failed')));
      },
    );

    test(
      'does not expose confirm checkpoint for dynamic checkpoint whose dependency chapter is still queued',
      () {
        final tasks = <Object?>[
          <String, Object?>{
            'id': 'chapter_003',
            'title': '第03章',
            'task_type': 'chapter',
            'mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'status': TaskRuntimeConstants.statusSucceeded,
            'depends_on': <Object?>['checkpoint_003'],
            'relative_path': 'tasks/chapter_003.json',
            'metadata': <String, Object?>{'sort_order': 19, 'stage': 'draft'},
          },
          <String, Object?>{
            'id': 'chapter_004',
            'title': '第04章',
            'task_type': 'chapter',
            'mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'status': TaskRuntimeConstants.statusQueued,
            'depends_on': <Object?>['chapter_003'],
            'relative_path': 'tasks/chapter_004.json',
            'metadata': <String, Object?>{'sort_order': 20, 'stage': 'draft'},
          },
          <String, Object?>{
            'id': 'checkpoint_004',
            'title': '检查点：第 4 章后确认',
            'task_type': 'checkpoint',
            'mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'status': TaskRuntimeConstants.statusQueued,
            'depends_on': <Object?>['chapter_004'],
            'relative_path': 'tasks/checkpoint_004.json',
            'metadata': <String, Object?>{
              'sort_order': 21,
              'stage': 'checkpoint',
              'manual_checkpoint': true,
            },
          },
        ];

        final batch = nextBatchPlanService.nextBatchPlan(<String, Object?>{
          'id': 'run_dynamic_checkpoint_blocked',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'status': TaskRuntimeConstants.statusRunning,
        }, tasks);
        final contract = runCenterContractService
            .runCenterContract(<String, Object?>{
              'id': 'run_dynamic_checkpoint_blocked',
              'mode': TaskRuntimeConstants.modeSeedToFullNovel,
              'status': TaskRuntimeConstants.statusRunning,
            }, tasks);

        expect(batch['action'], 'dispatch_batch');
        final batchTasks = ValueReaders.mapList(batch['tasks']);
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(batchTasks.first)['id'],
          ),
          'chapter_004',
        );
        expect(ValueReaders.boolValue(contract['waiting_user']), isFalse);
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(contract['active_task'])['id'],
          ),
          'chapter_004',
        );
        final confirm = ValueReaders.mapList(contract['controls']).firstWhere(
          (item) =>
              ValueReaders.stringValue(item['id']) == 'confirm_checkpoint',
        );
        expect(ValueReaders.boolValue(confirm['enabled']), isFalse);
      },
    );

    test(
      'resumes into next chapter after checkpoint confirmation even when history keeps stale waiting-user step',
      () {
        final tasks = <Object?>[
          <String, Object?>{
            'id': 'planning',
            'title': '规划：扩展作品规格与总纲',
            'task_type': 'planning',
            'mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'status': TaskRuntimeConstants.statusSucceeded,
            'depends_on': <Object?>[],
            'relative_path': 'tasks/planning.json',
            'metadata': <String, Object?>{'sort_order': 1, 'stage': 'planning'},
          },
          <String, Object?>{
            'id': 'checkpoint_outline',
            'title': '检查点：确认总纲与章节任务',
            'task_type': 'checkpoint',
            'mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'status': TaskRuntimeConstants.statusSucceeded,
            'depends_on': <Object?>['planning'],
            'relative_path': 'tasks/checkpoint_outline.json',
            'metadata': <String, Object?>{
              'sort_order': 2,
              'stage': 'checkpoint',
              'manual_checkpoint': true,
            },
          },
          <String, Object?>{
            'id': 'chapter_001',
            'title': '样章：第01章',
            'task_type': 'chapter',
            'mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'status': TaskRuntimeConstants.statusQueued,
            'depends_on': <Object?>['checkpoint_outline'],
            'relative_path': 'tasks/chapter_001.json',
            'metadata': <String, Object?>{'sort_order': 3, 'stage': 'sample'},
          },
          <String, Object?>{
            'id': 'checkpoint_001',
            'title': '检查点：确认样章',
            'task_type': 'checkpoint',
            'mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'status': TaskRuntimeConstants.statusQueued,
            'depends_on': <Object?>['chapter_001'],
            'relative_path': 'tasks/checkpoint_001.json',
            'metadata': <String, Object?>{
              'sort_order': 4,
              'stage': 'checkpoint',
              'manual_checkpoint': true,
            },
          },
        ];

        final record = <String, Object?>{
          'id': 'run_resume_after_checkpoint',
          'relative_path': 'tracking/long_task_runs/run_resume_after_checkpoint.json',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'status': TaskRuntimeConstants.statusRunning,
          'plan_id': 'plan_001',
          'last_task_id': 'planning',
          'last_checkpoint_review_path':
              'tracking/checkpoint_reviews/planning.json',
          'last_information_risk_category': 'accept',
          'last_writing_execution_category': 'success',
          'last_writing_execution_status': 'success',
          'last_writing_execution_summary': '用户已通过 checkpoint review 确认当前产物，长任务恢复继续调度。',
          'last_writing_execution_next_action': 'resume_dispatch',
          'last_writing_execution_result': <String, Object?>{
            'execution_id': '',
            'workflow_kind': 'long_task_checkpoint_acknowledged',
            'overall_status': WritingExecutionOutcomeStatuses.success,
            'summary': '用户已通过 checkpoint review 确认当前产物，长任务恢复继续调度。',
            'delivery': const <String, Object?>{},
            'constraints': const <String, Object?>{},
            'information': const <String, Object?>{
              'present': false,
              'risk_category': 'accept',
              'summary': '',
            },
            'collaboration': const <String, Object?>{},
            'recovery': const <String, Object?>{},
            'next_action': 'resume_dispatch',
            'blocks_progress': false,
            'retryable': false,
            'requires_user_action': false,
            'schema_version': 1,
            'metadata': const <String, Object?>{
              'checkpoint_review_acknowledged': true,
              'checkpoint_review_path':
                  'tracking/checkpoint_reviews/planning.json',
            },
          },
          'steps': const <Object?>[
            <String, Object?>{
              'writing_execution_next_action': 'resume_when_user_confirms',
              'information_risk_category': 'checkpoint_user',
              'writing_execution_result': <String, Object?>{
                'execution_id': 'planning_step_wait',
                'workflow_kind': 'workflow_task',
                'overall_status':
                    WritingExecutionOutcomeStatuses.userActionRequired,
                'summary': '当前步骤正在等待用户确认。',
                'delivery': <String, Object?>{},
                'constraints': <String, Object?>{},
                'information': <String, Object?>{
                  'present': true,
                  'risk_category': 'checkpoint_user',
                  'summary': '当前节点需要用户确认后再继续。',
                },
                'collaboration': <String, Object?>{},
                'recovery': <String, Object?>{
                  'present': true,
                  'recommended_action': 'resume_when_user_confirms',
                  'reason': 'waiting_user_choice',
                  'note': '当前步骤正在等待用户确认。',
                },
                'next_action': 'resume_when_user_confirms',
                'blocks_progress': true,
                'retryable': false,
                'requires_user_action': true,
                'schema_version': 1,
                'metadata': <String, Object?>{},
              },
            },
          ],
          'options': const <String, Object?>{
            'runtime_mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'max_steps': 3,
            'max_seconds': 900,
            'stop_on_user_checkpoint': true,
            'stop_on_failed_task': true,
            'allow_stream_guidance': true,
            'safe_after_crash': true,
            'resume_after_crash': true,
            'auto_retry_failed_task': true,
            'recovery_retry_budget': 1,
            'recovery_exhausted_disposition': 'manual_attention',
            'unattended': true,
            'auto_advance_chapters': true,
          },
        };

        final batch = nextBatchPlanService.nextBatchPlan(
          record,
          tasks,
          options: ValueReaders.mapValue(record['options']),
        );
        final contract = runCenterContractService.runCenterContract(
          record,
          tasks,
          options: ValueReaders.mapValue(record['options']),
        );
        final scheduler = schedulerTickPlanService.schedulerTickPlan(
          record,
          tasks,
          options: ValueReaders.mapValue(record['options']),
        );
        final confirm = ValueReaders.mapList(contract['controls']).firstWhere(
          (item) =>
              ValueReaders.stringValue(item['id']) == 'confirm_checkpoint',
        );

        expect(batch['action'], 'dispatch_batch');
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              ValueReaders.mapList(batch['tasks']).first,
            )['id'],
          ),
          'chapter_001',
        );
        expect(ValueReaders.boolValue(contract['waiting_user']), isFalse);
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(contract['active_task'])['id'],
          ),
          'chapter_001',
        );
        expect(ValueReaders.boolValue(confirm['enabled']), isFalse);
        expect(scheduler['action'], 'dispatch_batch');
        expect(scheduler['worker_state'], 'ready');
      },
    );

    test(
      'does not expose confirm checkpoint for non-checkpoint waiting user task',
      () {
        final tasks = <Object?>[
          <String, Object?>{
            'id': 'write_spec',
            'title': '写入作品规格',
            'task_type': 'agent_task',
            'mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'status': TaskRuntimeConstants.statusWaitingUser,
            'relative_path': 'tasks/write_spec.task.json',
            'depends_on': <Object?>[],
            'metadata': <String, Object?>{
              'sort_order': 1,
              'stage': 'planning',
            },
          },
          <String, Object?>{
            'id': 'write_outline',
            'title': '写入总纲',
            'task_type': 'agent_task',
            'mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'status': TaskRuntimeConstants.statusQueued,
            'relative_path': 'tasks/write_outline.task.json',
            'depends_on': <Object?>['write_spec'],
            'metadata': <String, Object?>{
              'sort_order': 2,
              'stage': 'planning',
            },
          },
        ];

        final contract = runCenterContractService.runCenterContract(
          <String, Object?>{
            'id': 'run_waiting_user_agent_task',
            'mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'status': TaskRuntimeConstants.statusPaused,
            'stop_reason': 'waiting_user',
          },
          tasks,
        );

        expect(ValueReaders.boolValue(contract['waiting_user']), isTrue);
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(contract['active_task'])['id'],
          ),
          'write_spec',
        );
        final confirm = ValueReaders.mapList(contract['controls']).firstWhere(
          (item) =>
              ValueReaders.stringValue(item['id']) == 'confirm_checkpoint',
        );
        expect(ValueReaders.boolValue(confirm['enabled']), isFalse);
      },
    );

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

    test(
      'builds scheduler tick plan for auto retry and exhausted recovery',
      () {
        final autoRetryPlan = schedulerTickPlanService.schedulerTickPlan(
          <String, Object?>{
            'id': 'run_retry_auto',
            'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
            'status': TaskRuntimeConstants.statusRunning,
            'last_writing_execution_result': <String, Object?>{
              'execution_id': 'task_retry_auto',
              'workflow_kind': 'workflow_task',
              'overall_status':
                  WritingExecutionOutcomeStatuses.technicalFailure,
              'summary': '模型临时失败，可自动重试。',
              'delivery': const <String, Object?>{},
              'constraints': const <String, Object?>{},
              'information': const <String, Object?>{},
              'collaboration': const <String, Object?>{},
              'recovery': const <String, Object?>{
                'present': true,
                'recommended_action': 'pause_for_failure',
                'reason': 'technical_retryable',
                'note': '模型临时失败，可自动重试。',
                'retryable': true,
              },
              'next_action': '',
              'blocks_progress': true,
              'retryable': true,
              'requires_user_action': false,
              'schema_version': 1,
              'metadata': const <String, Object?>{},
            },
            'recovery_retry_counts': const <String, Object?>{'chapter_fail': 0},
          },
          const <Object?>[
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
          options: const <String, Object?>{
            'auto_retry_failed_task': true,
            'recovery_retry_budget': 2,
          },
        );
        final exhaustedPlan = schedulerTickPlanService.schedulerTickPlan(
          <String, Object?>{
            'id': 'run_retry_exhausted',
            'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
            'status': TaskRuntimeConstants.statusRunning,
            'last_writing_execution_result': <String, Object?>{
              'execution_id': 'task_retry_exhausted',
              'workflow_kind': 'workflow_task',
              'overall_status':
                  WritingExecutionOutcomeStatuses.technicalFailure,
              'summary': '模型持续失败。',
              'delivery': const <String, Object?>{},
              'constraints': const <String, Object?>{},
              'information': const <String, Object?>{},
              'collaboration': const <String, Object?>{},
              'recovery': const <String, Object?>{
                'present': true,
                'recommended_action': 'pause_for_failure',
                'reason': 'technical_retryable',
                'note': '模型持续失败。',
                'retryable': true,
              },
              'next_action': '',
              'blocks_progress': true,
              'retryable': true,
              'requires_user_action': false,
              'schema_version': 1,
              'metadata': const <String, Object?>{},
            },
            'recovery_retry_counts': const <String, Object?>{'chapter_fail': 1},
          },
          const <Object?>[
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
          options: const <String, Object?>{
            'auto_retry_failed_task': true,
            'recovery_retry_budget': 1,
            'recovery_exhausted_disposition': 'stop_run',
          },
        );

        expect(autoRetryPlan['action'], 'retry_failed_task');
        expect(autoRetryPlan['should_dispatch'], isTrue);
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(autoRetryPlan['recovery_state'])['state'],
          ),
          'ready_retry',
        );
        expect(exhaustedPlan['action'], 'stop_after_recovery_exhausted');
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(exhaustedPlan['recovery_state'])['state'],
          ),
          'exhausted',
        );
      },
    );

    test('keeps autorun checkpoint interval at zero under critical risk', () {
      // 中文注释: autorun 基线在高风险时只能缩 batch，不应重新要求人工 checkpoint 间隔。
      final strategy = unattendedStrategyService.unattendedStrategy(
        <String, Object?>{
          'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
          'status': TaskRuntimeConstants.statusRunning,
          'last_checkpoint_review_severity': 'critical',
          'last_writing_execution_category': 'technical_failed',
          'last_information_risk_category': 'manual_attention',
          'steps': const <Object?>[
            <String, Object?>{
              'checkpoint_review_severity': 'critical',
              'writing_execution_category': 'technical_failed',
              'information_risk_category': 'manual_attention',
            },
          ],
        },
        const <Object?>[],
        options: const <String, Object?>{
          'runtime_baseline_id': 'chapter_collaboration_autorun',
        },
      );
      final cadence = ValueReaders.mapValue(strategy['checkpoint_cadence']);

      expect(
        ValueReaders.intValue(cadence['effective_checkpoint_interval']),
        0,
      );
      expect(ValueReaders.intValue(cadence['effective_batch_steps']), 1);
      expect(ValueReaders.intValue(cadence['effective_batch_seconds']), 1800);
    });
  });
}
