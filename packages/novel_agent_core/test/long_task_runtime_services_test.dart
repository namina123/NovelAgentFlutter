import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Long task runtime services', () {
    final modeService = LongTaskModeService();
    final pathPolicy = LongTaskPathPolicyService();
    final strategy = LongTaskModeStrategyService(modeService: modeService);
    final taskSummary = LongTaskTaskSummaryService();
    final optionService = LongTaskRunOptionService();
    final recordService = LongTaskRunRecordService(
      modeService: modeService,
      strategyService: strategy,
      optionService: optionService,
      taskSummaryService: taskSummary,
    );
    final actionService = LongTaskRunActionService(strategyService: strategy);
    final lifecycle = LongTaskRunLifecycleService();
    final stepRecorder = LongTaskRunStepRecorderService(
      taskSummaryService: taskSummary,
    );
    final contextService = LongTaskTransactionContextService(
      modeService: modeService,
      pathPolicyService: pathPolicy,
    );
    final contractService = LongTaskTransactionContractService(
      modeService: modeService,
      pathPolicyService: pathPolicy,
    );
    final transactionService = LongTaskTaskTransactionService(
      modeService: modeService,
      strategyService: strategy,
      contextService: contextService,
      contractService: contractService,
    );
    final promptRenderer = LongTaskTaskPromptRenderer(
      contractService: contractService,
    );
    final postprocessTransaction = LongTaskPostprocessTransactionService(
      modeService: modeService,
      pathPolicyService: pathPolicy,
      contextService: contextService,
    );
    final postprocessRenderer = LongTaskPostprocessPromptRenderer(
      contractService: contractService,
    );
    final recovery = LongTaskRecoveryService();
    final failure = LongTaskFailureActionService(lifecycleService: lifecycle);
    final factory = LongTaskTaskFactoryService(
      modeService: modeService,
      pathPolicyService: pathPolicy,
    );
    final markdown = LongTaskRunMarkdownRenderer();

    test('builds run record, prompt transaction and next action', () {
      // 中文注释: 这里验证长任务运行记录、事务提示和下一步调度能在纯 core 中独立成立。
      final tasks = factory.buildTasks(
        TaskRuntimeConstants.modeSeedToFullNovel,
        'plan_a',
        options: <String, Object?>{
          'seed_prompt': '都市异能长篇',
          'chapter_count': 3,
          'persistent_context_paths': <Object?>[
            'tracking/modes/seed_autopilot_novel/guidance.md',
            'styles/seed_autopilot_style.md',
          ],
        },
        createdAt: '2026-05-23T10:00:00Z',
      );
      final record = recordService.startRecord(
        <String, Object?>{
          'id': 'plan_a',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
        },
        tasks,
        options: <String, Object?>{
          'run_id': 'run_a',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
        },
        createdAt: '2026-05-23T10:00:00Z',
      );
      final action = actionService.nextAction(record, tasks);
      final transaction = transactionService.buildTaskTransaction(
        tasks.first,
        runRecord: record,
        options: <String, Object?>{
          'project_templates': <String, Object?>{
            'long_task_planning': '模板：{{task_goal}}',
          },
        },
      );
      final prompt = promptRenderer.renderTaskPrompt(transaction);

      expect(record['status'], TaskRuntimeConstants.statusRunning);
      expect(action['action'], 'call_model');
      expect(prompt, contains('长篇任务流单步'));
      expect(prompt, contains('项目模板'));
      expect(
        ValueReaders.stringList(tasks.first['source_paths']),
        contains('styles/seed_autopilot_style.md'),
      );
      expect(
        ValueReaders.stringList(transaction['context_needs']),
        contains('把长期约束路径中的风格、世界、角色与模式摘要视为持续硬约束；除非用户明确改动，否则不要自行漂移。'),
      );
    });

    test(
      'records steps, renders postprocess, and handles recovery/failure',
      () {
        // 中文注释: 这里验证长任务运行步骤审计、修订后处理提示、恢复建议和失败动作合同。
        final task = <String, Object?>{
          'id': 'task_revision',
          'title': '修订第一章',
          'task_type': 'revision',
          'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
          'status': TaskRuntimeConstants.statusFailed,
          'source_paths': <String>['reviews/general/report.md'],
          'output_paths': <String>['chapters/ch01.md'],
          'metadata': <String, Object?>{
            'review_report_path': 'reviews/general/report.md',
          },
        };
        final record = <String, Object?>{
          'id': 'run_b',
          'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
          'status': TaskRuntimeConstants.statusRunning,
          'steps': <Object?>[],
        };
        final stepped = stepRecorder.recordStep(record, task, <String, Object?>{
          'ok': false,
          'error': '模型失败',
          'output_paths': <Object?>[],
          'checkpoint_review': <String, Object?>{
            'relative_path': 'tracking/checkpoint_reviews/rev.json',
            'review': <String, Object?>{
              'summary': '需要人工判断是否重试。',
              'severity': 'critical',
              'action_summary': '建议动作：回看长期约束、生成后续审稿',
            },
          },
          'response': <String, Object?>{},
        }, createdAt: '2026-05-23T10:01:00Z');
        final postTx = postprocessTransaction.buildPostprocessTransaction(
          task,
          <String, Object?>{
            'relative_path': 'tracking/chapter_atomic/rev.execution.json',
            'revision_diff_path': 'tracking/revision_diffs/rev.md',
          },
          <Object?>['chapters/ch01.md'],
        );
        final postPrompt = postprocessRenderer.renderPostprocessPrompt(postTx);
        final recoveryPlan = recovery.recoveryPlan(record, <Object?>[task]);
        final failureAction = failure.failureAction(
          record,
          task,
          'retry',
          createdAt: '2026-05-23T10:02:00Z',
        );

        expect(stepped['status'], TaskRuntimeConstants.statusPaused);
        expect(postPrompt, contains('修复任务后处理'));
        expect(recoveryPlan['action'], 'pause_for_failure');
        expect(failureAction['task_status'], TaskRuntimeConstants.statusQueued);
        expect(markdown.renderMarkdown(stepped), contains('模型失败'));
        expect(
          markdown.renderMarkdown(stepped),
          contains('tracking/checkpoint_reviews/rev.json'),
        );
        expect(markdown.renderMarkdown(stepped), contains('风险级别：critical'));
        expect(markdown.renderMarkdown(stepped), contains('动作建议：建议动作'));
      },
    );
  });
}
