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
      final chapterTask = tasks.firstWhere(
        (task) => ValueReaders.stringValue(task['task_type']) == 'chapter',
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
        chapterTask,
        runRecord: record,
        options: <String, Object?>{
          'project_templates': <String, Object?>{
            'chapter_atomic': '模板：{{task_goal}}',
          },
          'project_constitution_markdown': '''
# 项目创作宪法

本书长期承诺是高压权谋与持续逆转。

## 核心原则

- 重大设定前后一致。
''',
          'project_file_contents': <String, Object?>{
            'tracking/modes/seed_autopilot_novel/guidance.md': '''
# 灵感托管式长篇 引导摘要

当前已经确认主线方向。

## 阶段答案

- 高压权谋与持续逆转。
- 总纲和重大转折先确认。
''',
            'styles/seed_autopilot_style.md': '''
---
id: style.main
display_name: 主风格
guardrails:
  - 每章必须推进情报
---

# 主风格

干净利落，强钩子。
''',
          },
          'expression_constraint_profiles': <Object?>[
            <String, Object?>{
              'id': 'de_ai',
              'display_name': '去 AI 风',
              'summary': '降低模板化表达和解释腔。',
              'kind': 'natural_expression',
              'rules': <Object?>['减少工整排比和空心总结。'],
            },
          ],
          'project_expression_constraint_bindings': <Object?>[
            <String, Object?>{
              'profile_id': 'de_ai',
              'default_for_project': true,
            },
          ],
        },
      );
      final prompt = promptRenderer.renderTaskPrompt(transaction);

      expect(record['status'], TaskRuntimeConstants.statusRunning);
      expect(action['action'], 'call_model');
      expect(prompt, contains('长篇任务流单步'));
      expect(prompt, contains('项目模板'));
      expect(prompt, contains('技能路由策略'));
      expect(prompt, contains('novel-control-station'));
      expect(prompt, contains('创作约束栈'));
      expect(prompt, contains('表达限制细则'));
      expect(prompt, contains('减少工整排比和空心总结'));
      expect(prompt, contains('项目创作宪法'));
      expect(
        ValueReaders.stringList(chapterTask['source_paths']),
        contains('styles/seed_autopilot_style.md'),
      );
      expect(
        ValueReaders.stringList(transaction['context_needs']),
        contains('把长期约束路径中的风格、世界、角色与模式摘要视为持续硬约束；除非用户明确改动，否则不要自行漂移。'),
      );
      expect(
        ValueReaders.stringList(transaction['context_needs']),
        contains(
          '需要时读取 specs/project_spec.md、styles/、knowledge/ 等只读信息投影和相关人物/世界状态；长期事实仍以结构化 information/continuity 合同为准。',
        ),
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
          'changed_paths': <Object?>[
            '.novel_agent/continuity/ledgers/main/entries.jsonl',
            '.novel_agent/continuity/reviews/review_001.json',
          ],
          'activation_report_path':
              'tracking/chapter_atomic/task_revision.activation_report.json',
          'activation_report_summary': '已注入长期约束与模式引导。',
          'chapter_delivery_state':
              ChapterDeliveryStateStatuses.missingOutputRecoverable,
          'chapter_delivery_path': 'chapters/ch01.md',
          'checkpoint_review': <String, Object?>{
            'relative_path': 'tracking/checkpoint_reviews/rev.json',
            'review': <String, Object?>{
              'summary': '需要人工判断是否重试。',
              'severity': 'critical',
              'action_summary': '建议动作：回看长期约束、生成后续审稿',
              'information_signal': <String, Object?>{
                'present': true,
                'category': 'repair',
                'summary': '待研究 1 项，required 信息省略 1 项，information 改动 2 项',
                'changed_paths': <Object?>[
                  '.novel_agent/information/research_requests/request_1.json',
                  'knowledge/项目知识摘要.md',
                ],
              },
            },
          },
          'response': <String, Object?>{},
        }, createdAt: '2026-05-23T10:01:00Z');
        final postTx = postprocessTransaction.buildPostprocessTransaction(
          task,
          <String, Object?>{
            'relative_path': 'tracking/chapter_atomic/rev.execution.json',
            'revision_diff_path': 'tracking/revision_diffs/rev.md',
            'context_pack': <String, Object?>{
              'creative_rule_stack': <String, Object?>{
                'expression_constraints': <Object?>[
                  <String, Object?>{
                    'id': 'de_ai',
                    'display_name': '去 AI 风',
                    'summary': '降低模板化表达和解释腔。',
                    'kind': 'natural_expression',
                  },
                ],
              },
            },
          },
          <Object?>['chapters/ch01.md'],
          options: const <String, Object?>{
            'creative_rule_stack': <String, Object?>{
              'constitution': <String, Object?>{
                'id': 'project_constitution',
                'title': '项目创作宪法',
                'summary': '保持高压权谋与持续逆转。',
              },
            },
          },
        );
        final postPrompt = postprocessRenderer.renderPostprocessPrompt(postTx);
        final recoveryPlan = recovery.recoveryPlan(stepped, <Object?>[task]);
        final failureAction = failure.failureAction(
          record,
          task,
          'retry',
          createdAt: '2026-05-23T10:02:00Z',
        );

        expect(stepped['status'], TaskRuntimeConstants.statusPaused);
        expect(
          ValueReaders.stringValue(stepped['last_activation_report_path']),
          'tracking/chapter_atomic/task_revision.activation_report.json',
        );
        expect(
          ValueReaders.stringValue(stepped['last_chapter_delivery_state']),
          ChapterDeliveryStateStatuses.missingOutputRecoverable,
        );
        expect(
          ValueReaders.stringList(stepped['last_changed_paths']),
          contains('.novel_agent/continuity/ledgers/main/entries.jsonl'),
        );
        expect(
          ValueReaders.stringList(stepped['last_information_changed_paths']),
          contains('.novel_agent/information/research_requests/request_1.json'),
        );
        expect(
          ValueReaders.stringValue(stepped['last_information_risk_category']),
          'repair',
        );
        expect(
          ValueReaders.stringList(
            ValueReaders.mapList(stepped['steps']).single['changed_paths'],
          ),
          contains('.novel_agent/continuity/reviews/review_001.json'),
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapList(
              stepped['steps'],
            ).single['information_summary'],
          ),
          contains('待研究 1 项'),
        );
        expect(postPrompt, contains('修复任务后处理'));
        expect(postPrompt, contains('创作约束栈'));
        expect(postPrompt, contains('Mini Recheck'));
        expect(postPrompt, contains('真实性复核强度'));
        expect(recoveryPlan['action'], 'pause_for_repair');
        expect(failureAction['task_status'], TaskRuntimeConstants.statusQueued);
        expect(markdown.renderMarkdown(stepped), contains('模型失败'));
        expect(
          markdown.renderMarkdown(stepped),
          contains('交付状态：missing_output_recoverable'),
        );
        expect(
          markdown.renderMarkdown(stepped),
          contains('Information：待研究 1 项'),
        );
        expect(
          markdown.renderMarkdown(stepped),
          contains('tracking/checkpoint_reviews/rev.json'),
        );
        expect(markdown.renderMarkdown(stepped), contains('风险级别：critical'));
        expect(markdown.renderMarkdown(stepped), contains('动作建议：建议动作'));
      },
    );

    test(
      'recovery pauses for information waiting user signal without reading正文',
      () {
        final recoveryPlan = recovery.recoveryPlan(
          <String, Object?>{
            'id': 'run_info_wait',
            'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
            'status': TaskRuntimeConstants.statusRunning,
            'steps': <Object?>[
              <String, Object?>{
                'information_risk_category': 'checkpoint_user',
                'information_summary': '待研究 1 项，建议先确认是否补研究。',
              },
            ],
          },
          const <Object?>[
            <String, Object?>{
              'id': 'chapter_001',
              'title': '第一章',
              'task_type': 'chapter',
              'status': TaskRuntimeConstants.statusSucceeded,
            },
          ],
        );

        expect(recoveryPlan['action'], 'resume_when_user_confirms');
        expect(recoveryPlan['reason'], 'information_waiting_user');
        expect(
          ValueReaders.stringValue(recoveryPlan['note']),
          contains('待研究 1 项'),
        );
      },
    );

    test('recovery prioritizes shared writing execution budget boundary', () {
      final recoveryPlan = recovery.recoveryPlan(<String, Object?>{
        'id': 'run_budget',
        'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
        'status': TaskRuntimeConstants.statusPaused,
        'stop_reason': 'max_steps',
      }, const <Object?>[]);

      expect(recoveryPlan['action'], 'resume_dispatch');
      expect(recoveryPlan['reason'], 'budget_failed');
    });

    test('recovery pauses for shared collaboration failure signal', () {
      final recoveryPlan = recovery.recoveryPlan(<String, Object?>{
        'id': 'run_collaboration_fail',
        'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
        'status': TaskRuntimeConstants.statusPaused,
        'last_writing_execution_result': <String, Object?>{
          'execution_id': 'task_002',
          'workflow_kind': 'workflow_task',
          'overall_status': WritingExecutionOutcomeStatuses.recoverableFailure,
          'summary': '协作结果：失败 1 项',
          'delivery': const <String, Object?>{},
          'constraints': const <String, Object?>{},
          'information': const <String, Object?>{},
          'collaboration': const <String, Object?>{
            'present': true,
            'failed_collaborator_count': 1,
            'failed_agent_names': <Object?>['审稿员'],
            'summary': '协作结果：失败 1 项',
          },
          'recovery': const <String, Object?>{},
          'next_action': '',
          'blocks_progress': true,
          'retryable': true,
          'requires_user_action': false,
          'schema_version': 1,
          'metadata': const <String, Object?>{},
        },
      }, const <Object?>[]);

      expect(recoveryPlan['action'], 'pause_for_repair');
      expect(
        ValueReaders.stringValue(recoveryPlan['note']),
        contains('协作结果：失败 1 项'),
      );
    });

    test(
      'recovery waits for high-risk collaboration conflict confirmation',
      () {
        final recoveryPlan = recovery.recoveryPlan(<String, Object?>{
          'id': 'run_collaboration_conflict',
          'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
          'status': TaskRuntimeConstants.statusWaitingUser,
          'last_writing_execution_result': <String, Object?>{
            'execution_id': 'task_conflict_001',
            'workflow_kind': 'workflow_task',
            'overall_status':
                WritingExecutionOutcomeStatuses.userActionRequired,
            'summary': '协作冲突：待用户确认 1 项',
            'delivery': const <String, Object?>{},
            'constraints': const <String, Object?>{},
            'information': const <String, Object?>{},
            'collaboration': const <String, Object?>{
              'present': true,
              'total_conflict_count': 1,
              'user_confirmation_conflict_count': 1,
              'conflict_summary': '协作冲突：待用户确认 1 项',
            },
            'recovery': const <String, Object?>{},
            'next_action': 'confirm_collaboration_conflict',
            'blocks_progress': true,
            'retryable': false,
            'requires_user_action': true,
            'schema_version': 1,
            'metadata': const <String, Object?>{},
          },
        }, const <Object?>[]);

        expect(recoveryPlan['action'], 'resume_when_user_confirms');
        expect(
          ValueReaders.stringValue(recoveryPlan['note']),
          contains('待用户确认 1 项'),
        );
      },
    );
  });
}
