import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../tools/probe_config_support.dart';
import 'probe_support.dart';

const _suiteProbeId = 'ltsr_20_mainline_mock_regression_suite';
const _suiteProbeName = 'mock_long_task_stability_regression_suite';
final LongTaskRunCenterContractService _suiteRunCenterContractService =
    _buildSuiteRunCenterContractService();

Future<JsonMap> runLongTaskStabilityMockRegressionSuite({
  String? repoRootOverride,
  String? runIdOverride,
}) async {
  final repoRoot = repoRootOverride ?? resolveLocalProbeRepoRoot();
  final runId = runIdOverride ?? DateTime.now().toIso8601String();
  final workspaceRoot = buildProbeWorkspaceDirectory(
    repoRoot: repoRoot,
    probeName: _suiteProbeName,
    runId: runId,
  );
  await workspaceRoot.create(recursive: true);

  final scenarios = <JsonMap>[
    await _runOrdinaryProjectSelfReviewScenario(workspaceRoot),
    await _runReviewerDispatchScenario(workspaceRoot),
    await _runLongTaskProactiveReviewScenario(workspaceRoot),
    _runDeliveryFailureScenario(),
    _runRepairRequiredScenario(),
    _runWaitingUserScenario(),
    _runManualAttentionScenario(),
    _runNaturalCompletionScenario(),
  ];

  final summary = _buildSuiteSummary(scenarios);
  final report = <String, Object?>{
    'probe_id': _suiteProbeId,
    'run_id': runId,
    'repo_root': repoRoot,
    'workspace_root': workspaceRoot.path,
    'started_at': runId,
    'finished_at': DateTime.now().toIso8601String(),
    'summary': summary,
    'scenarios': scenarios,
  };

  final jsonPath =
      '${workspaceRoot.path}${Platform.pathSeparator}${_suiteProbeName}_report.json';
  final markdownPath =
      '${workspaceRoot.path}${Platform.pathSeparator}${_suiteProbeName}_report.md';
  await File(
    jsonPath,
  ).writeAsString(const JsonEncoder.withIndent('  ').convert(report));
  await File(markdownPath).writeAsString(_renderMarkdownReport(report));

  return <String, Object?>{
    ...report,
    'report_json_path': jsonPath,
    'report_markdown_path': markdownPath,
  };
}

Future<JsonMap> _runOrdinaryProjectSelfReviewScenario(
  Directory workspaceRoot,
) async {
  final harness = await _WorkflowRuntimeHarness.create(
    workspaceRoot: workspaceRoot,
    scenarioId: 'ordinary_project_self_review',
  );
  await harness.taskRepository.saveTask(
    harness.project,
    _buildReviewTask(
      id: 'review_task_self_001',
      title: '语义审稿：第01章',
      markdownPath: 'reviews/general/ch01_self.md',
      jsonPath: 'reviews/general/ch01_self.json',
    ),
  );
  final gateway = _RecordingWorkflowGateway(
    scriptedResults: <JsonMap>[
      <String, Object?>{
        'ok': true,
        'content': '',
        'tool_calls': <Object?>[
          <String, Object?>{
            'id': 'self_submit_1',
            'name': 'submit_semantic_review',
            'arguments': <String, Object?>{
              'review_id': 'self-review-1',
              'source': <String, Object?>{
                'source_type': NarrativeSourceTypes.writer,
                'source_id': 'writer',
              },
              'recommended_disposition': 'accept_with_note',
              'summary': '主写自检后建议补一处承接。',
              'findings': <Object?>[
                <String, Object?>{
                  'finding_id': 'self-finding-1',
                  'severity': 'low',
                  'summary': '章节转场还能更顺。',
                  'suggested_action': '补一处动作承接句。',
                },
              ],
            },
          },
        ],
        'message': const <String, Object?>{'role': 'assistant', 'content': ''},
      },
      <String, Object?>{
        'ok': true,
        'content': '已完成自检审稿，建议补一处承接。',
        'tool_calls': const <Object?>[],
        'message': const <String, Object?>{
          'role': 'assistant',
          'content': '已完成自检审稿，建议补一处承接。',
        },
      },
    ],
  );
  final workflowService = harness.buildRuntimeService(
    gateway: gateway,
    loadAvailableAgents: (_) async => <JsonMap>[
      <String, Object?>{'id': 'writer', 'name': '正文智能体', 'role': '负责主写'},
    ],
    loadAvailableAgentGroups: (_) async => <JsonMap>[
      <String, Object?>{
        'id': 'solo_writer_room',
        'name': '单人正文组',
        'agents': <String>['writer'],
        'primary_agent_id': 'writer',
      },
    ],
    loadProjectAgentGroupSelections: (_) async =>
        const <ProjectAgentGroupSelection>[
          ProjectAgentGroupSelection(
            groupId: 'solo_writer_room',
            displayName: '单人正文组',
            selectedByDefault: true,
          ),
        ],
  );

  final result = await workflowService.runWorkflowTaskOnce(
    harness.project,
    _mockSettings(),
    const <String, Object?>{'id': 'review_task_self_001'},
    agent: const <String, Object?>{
      'id': 'writer',
      'name': '正文智能体',
      'role': '负责主写',
    },
  );
  final execution = ValueReaders.mapValue(result['execution']);
  final reviewerDispatch = ValueReaders.mapValue(
    execution['reviewer_dispatch'],
  );
  final response = ValueReaders.mapValue(result['response']);
  final toolCalls = ValueReaders.objectList(
    response['tool_calls'],
  ).map(ValueReaders.mapValue).toList(growable: false);
  final scenarioOk =
      ValueReaders.boolValue(result['ok']) &&
      ValueReaders.stringValue(reviewerDispatch['selection_mode']) ==
          ReviewerSelectionModes.primaryWriterSelfReview &&
      ValueReaders.stringValue(reviewerDispatch['review_execution_mode']) ==
          'self_review' &&
      toolCalls.any(
        (tool) =>
            ValueReaders.stringValue(tool['name']) == 'submit_semantic_review',
      );
  return <String, Object?>{
    'id': 'ordinary_project_self_review',
    'layer': 'workflow_review_runtime',
    'ok': scenarioOk,
    'covered_requirements': const <String>['ordinary_project_self_review'],
    'production_contracts': const <String>[
      'execution.reviewer_dispatch',
      'response.tool_calls',
      'workflow review runtime',
    ],
    'observed_category': 'self_review',
    'selection_mode': ValueReaders.stringValue(
      reviewerDispatch['selection_mode'],
    ),
    'review_execution_mode': ValueReaders.stringValue(
      reviewerDispatch['review_execution_mode'],
    ),
    'summary': '普通项目 review 任务在缺少 reviewer-like child 时稳定回退为主写自审。',
  };
}

Future<JsonMap> _runReviewerDispatchScenario(Directory workspaceRoot) async {
  final harness = await _WorkflowRuntimeHarness.create(
    workspaceRoot: workspaceRoot,
    scenarioId: 'reviewer_dispatch',
  );
  await harness.taskRepository.saveTask(
    harness.project,
    _buildReviewTask(
      id: 'review_task_delegate_001',
      title: '语义审稿：第01章',
      markdownPath: 'reviews/general/ch01_delegate.md',
      jsonPath: 'reviews/general/ch01_delegate.json',
    ),
  );
  final gateway = _RecordingWorkflowGateway(
    scriptedResults: <JsonMap>[
      <String, Object?>{
        'ok': true,
        'content': '',
        'tool_calls': <Object?>[
          <String, Object?>{
            'id': 'reviewer_submit_1',
            'name': 'submit_semantic_review',
            'arguments': <String, Object?>{
              'review_id': 'reviewer-review-1',
              'source': <String, Object?>{
                'source_type': NarrativeSourceTypes.reviewer,
                'source_id': 'reviewer',
              },
              'recommended_disposition': 'accept_with_note',
              'summary': '审稿员建议强化第一段冲突。',
              'findings': <Object?>[
                <String, Object?>{
                  'finding_id': 'reviewer-finding-1',
                  'severity': 'medium',
                  'summary': '开场冲突还能更快落地。',
                  'suggested_action': '第一段前置阻力再明确一点。',
                },
              ],
            },
          },
        ],
        'message': const <String, Object?>{'role': 'assistant', 'content': ''},
      },
      <String, Object?>{
        'ok': true,
        'content': '已完成审稿，建议强化第一段冲突。',
        'tool_calls': const <Object?>[],
        'message': const <String, Object?>{
          'role': 'assistant',
          'content': '已完成审稿，建议强化第一段冲突。',
        },
      },
    ],
  );
  final workflowService = harness.buildRuntimeService(
    gateway: gateway,
    loadAvailableAgents: (_) async => <JsonMap>[
      <String, Object?>{'id': 'writer', 'name': '正文智能体', 'role': '负责主写'},
      <String, Object?>{
        'id': 'reviewer',
        'name': '审稿智能体',
        'role': '负责审稿',
        'model_id': 'reviewer-child-model',
        'tool_policy': const <String, Object?>{
          'allowed_tools': <String>[
            'read_project_file',
            'list_project_files',
            'submit_semantic_review',
          ],
        },
      },
    ],
    loadAvailableAgentGroups: (_) async => <JsonMap>[
      <String, Object?>{
        'id': 'story_room',
        'name': '正文协作组',
        'agents': <String>['writer', 'reviewer'],
        'primary_agent_id': 'writer',
      },
    ],
    loadProjectAgentGroupSelections: (_) async =>
        const <ProjectAgentGroupSelection>[
          ProjectAgentGroupSelection(
            groupId: 'story_room',
            displayName: '正文协作组',
            selectedByDefault: true,
          ),
        ],
  );

  final result = await workflowService.runWorkflowTaskOnce(
    harness.project,
    _mockSettings(),
    const <String, Object?>{'id': 'review_task_delegate_001'},
    agent: const <String, Object?>{
      'id': 'writer',
      'name': '正文智能体',
      'role': '负责主写',
    },
  );
  final execution = ValueReaders.mapValue(result['execution']);
  final reviewerDispatch = ValueReaders.mapValue(
    execution['reviewer_dispatch'],
  );
  final response = ValueReaders.mapValue(result['response']);
  final toolCalls = ValueReaders.objectList(
    response['tool_calls'],
  ).map(ValueReaders.mapValue).toList(growable: false);
  final scenarioOk =
      ValueReaders.boolValue(result['ok']) &&
      ValueReaders.stringValue(reviewerDispatch['selection_mode']) ==
          ReviewerSelectionModes.delegatedReviewer &&
      ValueReaders.boolValue(reviewerDispatch['should_delegate']) &&
      gateway.requests.every(
        (request) => request.modelId == 'reviewer-child-model',
      ) &&
      toolCalls.length == 1 &&
      ValueReaders.stringValue(toolCalls.single['name']) == 'call_sub_agent';
  return <String, Object?>{
    'id': 'reviewer_dispatch',
    'layer': 'workflow_review_runtime',
    'ok': scenarioOk,
    'covered_requirements': const <String>['reviewer_dispatch'],
    'production_contracts': const <String>[
      'execution.reviewer_dispatch',
      'review child model policy',
      'response.tool_calls',
    ],
    'observed_category': 'delegated_reviewer',
    'selection_mode': ValueReaders.stringValue(
      reviewerDispatch['selection_mode'],
    ),
    'delegated_agent_id': ValueReaders.stringValue(
      reviewerDispatch['agent_id'],
    ),
    'request_models': gateway.requests
        .map((request) => request.modelId)
        .toList(growable: false),
    'summary': 'review 任务会优先委派 reviewer child，而不是继续隐式走主写自审。',
  };
}

Future<JsonMap> _runLongTaskProactiveReviewScenario(
  Directory workspaceRoot,
) async {
  final harness = await _WorkflowRuntimeHarness.create(
    workspaceRoot: workspaceRoot,
    scenarioId: 'long_task_proactive_review',
  );
  await harness.taskRepository.saveTask(
    harness.project,
    _buildLongTaskChapterTask(
      id: 'task_001',
      title: '样章：第01章',
      chapter: '第01章',
      outputPath: 'chapters/第01章_seed_to_full.md',
      sortOrder: 1,
      stage: 'sample',
    ),
  );
  await harness.taskRepository.saveTask(
    harness.project,
    _buildLongTaskChapterTask(
      id: 'task_002',
      title: '正文：第02章',
      chapter: '第02章',
      outputPath: 'chapters/第02章_seed_to_full.md',
      sortOrder: 2,
      stage: 'draft',
      dependsOn: const <String>['task_001'],
    ),
  );
  final gateway = _RecordingWorkflowGateway(
    scriptedResults: <JsonMap>[
      <String, Object?>{
        'ok': true,
        'content': '',
        'tool_calls': <Object?>[
          <String, Object?>{
            'id': 'call_delivery_auto_followup',
            'name': 'submit_chapter_delivery',
            'arguments': <String, Object?>{
              'chapter_path': 'chapters/第01章_seed_to_full.md',
              'chapter_content': '# 第01章\n\n正式正文。',
              'submission': <String, Object?>{
                'submission_id': 'delivery-auto-followup',
                'title': '第01章',
                'summary': '完成章节交付',
              },
            },
          },
        ],
        'message': const <String, Object?>{'role': 'assistant', 'content': ''},
      },
      <String, Object?>{
        'ok': true,
        'content': '章节交付已完成。',
        'tool_calls': const <Object?>[],
        'message': const <String, Object?>{
          'role': 'assistant',
          'content': '章节交付已完成。',
        },
      },
    ],
  );
  final workflowService = harness.buildRuntimeService(
    gateway: gateway,
    checkpointReviewService: _FakeProjectLongTaskCheckpointReviewService(
      persistentTaskRepository: harness.taskRepository,
      response: <String, Object?>{
        'ok': true,
        'relative_path':
            'tracking/checkpoint_reviews/auto_followup_medium.json',
        'changed_paths': <Object?>[
          'tracking/checkpoint_reviews/auto_followup_medium.json',
        ],
        'review': <String, Object?>{
          'id': 'checkpoint_review_auto_followup_medium',
          'task': <String, Object?>{
            'id': 'task_001',
            'title': '样章：第01章',
            'task_type': 'chapter',
            'relative_path': 'tasks/task_001.json',
          },
          'task_type': 'chapter',
          'stage': 'sample',
          'summary': '当前节点建议先过一轮补充审视，再决定是否继续推进。',
          'result_ok': true,
          'severity': 'medium',
          'severity_label': '中',
          'severity_reasons': <Object?>['样章阶段建议补一轮审稿。'],
          'output_paths': <Object?>['chapters/第01章_seed_to_full.md'],
          'changed_paths': <Object?>['chapters/第01章_seed_to_full.md'],
          'confirmation_focus': <Object?>['样章入口是否成立。'],
          'drift_watch_items': <Object?>['检查文风是否漂移。'],
          'persistent_context_paths': <Object?>[
            'tracking/modes/seed_autopilot_novel/guidance.md',
          ],
          'continuation_disposition': 'blocked_wait_user',
          'disposition': <String, Object?>{
            'disposition': 'blocked_wait_user',
            'reason': 'medium_risk_needs_review',
            'create_followup_review_tasks': true,
            'request_revision_followup': false,
          },
          'information_signal': const <String, Object?>{
            'present': false,
            'category': 'accept',
          },
          'collaboration_signal': const <String, Object?>{
            'present': false,
            'category': 'accept',
          },
          'expression_constraint_signal': const <String, Object?>{
            'present': false,
            'category': 'suggest_strengthen',
          },
        },
      },
    ),
  );

  final result = await workflowService.runWorkflowTaskOnce(
    harness.project,
    _mockSettings(),
    const <String, Object?>{'id': 'task_001'},
  );
  final sourceTask = await harness.taskRepository.loadTask(
    harness.project,
    const <String, Object?>{'id': 'task_001'},
  );
  final downstreamTask = await harness.taskRepository.loadTask(
    harness.project,
    const <String, Object?>{'id': 'task_002'},
  );
  final reviewTasks = (await harness.taskRepository.listTasks(harness.project))
      .where(
        (task) =>
            ValueReaders.stringValue(task['task_type']) == 'review' &&
            ValueReaders.stringValue(
                  ValueReaders.mapValue(task['metadata'])['origin'],
                ) ==
                'checkpoint_review_suggestion',
      )
      .toList(growable: false);
  final reviewTaskIds = reviewTasks
      .map((task) => ValueReaders.stringValue(task['id']))
      .toList(growable: false);
  final nextRunnable =
      TaskSelectionService(
        taskDefinitionService: TaskDefinitionService(),
      ).nextRunnableTaskFromTasks(
        await harness.taskRepository.listTasks(harness.project),
      );
  final checkpointFollowup = ValueReaders.mapValue(
    result['checkpoint_followup'],
  );
  final sourceFollowupTaskIds = ValueReaders.stringList(
    sourceTask['checkpoint_followup_task_ids'],
  );
  final followupTaskIds = ValueReaders.stringList(
    checkpointFollowup['review_task_ids'],
  );
  final scenarioOk =
      ValueReaders.boolValue(result['ok']) &&
      ValueReaders.boolValue(checkpointFollowup['auto_scheduled']) &&
      ValueReaders.stringValue(sourceTask['status']) ==
          TaskRuntimeConstants.statusSucceeded &&
      reviewTasks.isNotEmpty &&
      followupTaskIds.isNotEmpty &&
      followupTaskIds.length == reviewTaskIds.length &&
      followupTaskIds.every(reviewTaskIds.contains) &&
      sourceFollowupTaskIds.length == reviewTaskIds.length &&
      sourceFollowupTaskIds.every(reviewTaskIds.contains) &&
      ValueReaders.stringValue(nextRunnable['task_type']) == 'review';
  return <String, Object?>{
    'id': 'long_task_proactive_review',
    'layer': 'workflow_long_task_runtime',
    'ok': scenarioOk,
    'covered_requirements': const <String>['long_task_proactive_review'],
    'production_contracts': const <String>[
      'checkpoint_followup',
      'checkpoint review record',
      'review task dependency rewiring',
    ],
    'observed_category': 'auto_followup_review_gate',
    'auto_scheduled': ValueReaders.boolValue(
      checkpointFollowup['auto_scheduled'],
    ),
    'review_task_ids': reviewTaskIds,
    'followup_task_ids': followupTaskIds,
    'source_followup_task_ids': sourceFollowupTaskIds,
    'next_runnable_task_type': ValueReaders.stringValue(
      nextRunnable['task_type'],
    ),
    'summary':
        '长任务 checkpoint 会主动插入 follow-up review gate，并把下游任务正式改挂到 review 门后。',
  };
}

JsonMap _runDeliveryFailureScenario() {
  final result = WritingExecutionResultNormalizerService().normalize(
    executionId: 'suite_delivery_failure',
    workflowKind: 'long_task_stability_suite',
    deliveryState: ChapterDeliveryStateResult(
      deliveryId: 'delivery_failure_001',
      state: ChapterDeliveryStateStatuses.pathMismatchRecoverable,
      recommendedAction: 'repair_and_retry',
      suggestedOutcomeStatus: DomainToolOutcomeStatuses.rejected,
      reason: 'chapter_path_mismatch',
      summary: '章节路径未落到 canonical chapter file，需要先修复交付路径。',
      blocksProgress: true,
      chapterBodyDelivered: true,
      submissionAccepted: false,
      retryable: true,
      deliveryFailure: const ChapterDeliveryFailure(
        category: ChapterDeliveryFailureCategories.pathMismatch,
        reason: 'chapter_path_mismatch',
        summary: '章节路径重复前缀导致交付失败。',
        deliveryState: ChapterDeliveryStateStatuses.pathMismatchRecoverable,
        chapterPath: 'chapters/第04章_第04章.md',
        resolvedChapterPath: 'chapters/第04章.md',
        retryable: true,
        chapterBodyDelivered: true,
        submissionAccepted: false,
      ),
      metadata: const <String, Object?>{
        'chapter_path': 'chapters/第04章_第04章.md',
        'resolved_chapter_path': 'chapters/第04章.md',
      },
    ),
  );
  final stopOutcome = const LongTaskStopOutcomeResolverService()
      .fromWritingExecutionResult(result);
  final runCenterContract = _buildSuiteRunCenterContract(
    status: TaskRuntimeConstants.statusPaused,
    stopReason: stopOutcome.reason,
    stopNote: result.summary,
    stopOutcome: stopOutcome,
  );
  final stopDiagnosis = ValueReaders.mapValue(
    runCenterContract['stop_diagnosis'],
  );
  final reportCategory = classifyDraftProbeReportCategory(
    ok: false,
    validation: <String, Object?>{
      'run_center_contract': runCenterContract,
      'summary': result.summary,
    },
  );
  final scenarioOk =
      stopOutcome.category == LongTaskStopOutcomeCategories.deliveryFailure &&
      ValueReaders.stringValue(stopDiagnosis['category']) ==
          LongTaskStopOutcomeCategories.deliveryFailure &&
      reportCategory == ProbeReportCategories.contentQualityFailure;
  return <String, Object?>{
    'id': 'delivery_failure',
    'layer': 'shared_writing_contract',
    'ok': scenarioOk,
    'covered_requirements': const <String>['delivery_failure'],
    'production_contracts': const <String>[
      'writing_execution_result',
      'long_task_stop_outcome',
      'run_center_contract.stop_diagnosis',
    ],
    'observed_category': ValueReaders.stringValue(stopDiagnosis['category']),
    'probe_report_category': reportCategory,
    'run_center_contract': runCenterContract,
    'stop_diagnosis': stopDiagnosis,
    'summary': result.summary,
  };
}

JsonMap _runRepairRequiredScenario() {
  final review = ReviewContract(
    reviewId: 'review_repair_001',
    reviewType: 'checkpoint',
    reviewer: const ReviewReviewerRef(
      reviewerId: 'reviewer_alpha',
      reviewerRole: 'reviewer',
      label: '审稿员 Alpha',
    ),
    basis: const ReviewBasis(
      basisType: 'chapter_delivery',
      sourcePaths: <String>[
        'tracking/checkpoint_reviews/review_repair_001.json',
      ],
      targetPaths: <String>['chapters/第01章.md'],
      summary: '当前章节需要返修。',
    ),
    riskLevel: ReviewRiskLevels.high,
    recommendedDisposition: ReviewRecommendedDispositions.repair,
    findings: const <ReviewFindingContract>[
      ReviewFindingContract(
        findingId: 'repair-finding-1',
        severity: ReviewFindingSeverities.high,
        summary: '本章主冲突未形成有效闭环。',
        suggestedAction: '补齐主冲突与因果承接。',
        evidencePaths: <String>['chapters/第01章.md'],
      ),
    ],
    repairBrief: '先补齐主冲突和因果链，再恢复主链。',
    summary: '需要先返修后继续。',
    evidencePaths: const <String>['chapters/第01章.md'],
    createdAt: '2026-06-07T00:00:00Z',
    schemaVersion: '1',
  );
  final handoff = const ReviewRepairHandoffService().handoffFromReview(review);
  final repairTask = const ReviewRepairHandoffService().buildRepairTask(
    handoff.repairRequest!,
  );
  final recoveryState = LongTaskRecoveryState(
    present: true,
    state: LongTaskRecoveryStates.repairRequired,
    runStatus: LongTaskRunStatus.waitingGate.id,
    recommendedAction: 'repair_before_continue',
    reason: 'review_requests_blocking_repair',
    note: review.summary,
    blocksProgress: true,
    requiresRepair: true,
  );
  final runCenterContract = _buildSuiteRunCenterContract(
    status: TaskRuntimeConstants.statusPaused,
    stopReason: recoveryState.reason,
    stopNote: review.summary,
    recoveryState: recoveryState,
  );
  final stopDiagnosis = ValueReaders.mapValue(
    runCenterContract['stop_diagnosis'],
  );
  final reportCategory = classifyDraftProbeReportCategory(
    ok: false,
    validation: <String, Object?>{
      'run_center_contract': runCenterContract,
      'summary': review.summary,
    },
  );
  final scenarioOk =
      handoff.action == RepairHandoffActions.createBlockingRepair &&
      handoff.blocksMainFlow &&
      handoff.requiresRepairTask &&
      repairTask.blocksMainFlow &&
      ValueReaders.stringValue(stopDiagnosis['category']) ==
          LongTaskStopOutcomeCategories.constraintGatePause &&
      reportCategory == ProbeReportCategories.contentQualityFailure;
  return <String, Object?>{
    'id': 'repair_required',
    'layer': 'review_repair_lane',
    'ok': scenarioOk,
    'covered_requirements': const <String>['repair_required'],
    'production_contracts': const <String>[
      'review_contract',
      'review_repair_handoff',
      'repair_task',
      'run_center_contract.stop_diagnosis',
    ],
    'observed_category': ValueReaders.stringValue(stopDiagnosis['category']),
    'probe_report_category': reportCategory,
    'repair_action': handoff.action,
    'repair_task_id': repairTask.taskId,
    'run_center_contract': runCenterContract,
    'stop_diagnosis': stopDiagnosis,
    'summary': review.summary,
  };
}

JsonMap _runWaitingUserScenario() {
  final result = WritingExecutionResultNormalizerService().normalize(
    executionId: 'suite_waiting_user',
    workflowKind: 'long_task_stability_suite',
    informationSignal: const <String, Object?>{
      'category': 'checkpoint_user',
      'reason': 'information_waiting_user',
      'summary': '关键资料仍待用户确认。',
      'waiting_user': true,
      'changed_paths': <Object?>[
        '.novel_agent/information/research_requests/request_1.json',
      ],
    },
    recoveryPlan: const <String, Object?>{
      'action': 'resume_when_user_confirms',
      'reason': 'information_waiting_user',
      'note': '确认资料边界后再继续。',
      'safe_after_crash': true,
    },
  );
  final stopOutcome = const LongTaskStopOutcomeResolverService()
      .fromWritingExecutionResult(result);
  final runCenterContract = _buildSuiteRunCenterContract(
    status: TaskRuntimeConstants.statusPaused,
    stopReason: stopOutcome.reason,
    stopNote: result.summary,
    stopOutcome: stopOutcome,
  );
  final stopDiagnosis = ValueReaders.mapValue(
    runCenterContract['stop_diagnosis'],
  );
  final reportCategory = classifyDraftProbeReportCategory(
    ok: false,
    validation: <String, Object?>{
      'run_center_contract': runCenterContract,
      'summary': result.summary,
    },
  );
  final scenarioOk =
      result.requiresUserAction &&
      ValueReaders.stringValue(stopDiagnosis['category']) ==
          LongTaskStopOutcomeCategories.waitingUser &&
      reportCategory == ProbeReportCategories.waitingUser;
  return <String, Object?>{
    'id': 'waiting_user',
    'layer': 'shared_writing_contract',
    'ok': scenarioOk,
    'covered_requirements': const <String>['waiting_user'],
    'production_contracts': const <String>[
      'writing_execution_result',
      'long_task_stop_outcome',
      'run_center_contract.stop_diagnosis',
    ],
    'observed_category': ValueReaders.stringValue(stopDiagnosis['category']),
    'probe_report_category': reportCategory,
    'run_center_contract': runCenterContract,
    'stop_diagnosis': stopDiagnosis,
    'summary': result.summary,
  };
}

JsonMap _runManualAttentionScenario() {
  final recoveryState = LongTaskRecoveryState(
    present: true,
    state: LongTaskRecoveryStates.manualAttention,
    runStatus: LongTaskRunStatus.failedManualAttention.id,
    recommendedAction: 'pause_for_manual_attention',
    reason: 'information_manual_attention',
    note: '高风险资料冲突需要人工处理。',
    blocksProgress: true,
    manualAttentionRequired: true,
  );
  final runCenterContract = _buildSuiteRunCenterContract(
    status: TaskRuntimeConstants.statusPaused,
    stopReason: recoveryState.reason,
    stopNote: recoveryState.note,
    recoveryState: recoveryState,
  );
  final stopDiagnosis = ValueReaders.mapValue(
    runCenterContract['stop_diagnosis'],
  );
  final reportCategory = classifyDraftProbeReportCategory(
    ok: false,
    validation: <String, Object?>{
      'run_center_contract': runCenterContract,
      'summary': recoveryState.note,
    },
  );
  final scenarioOk =
      ValueReaders.stringValue(stopDiagnosis['category']) ==
          LongTaskStopOutcomeCategories.manualAttention &&
      reportCategory == ProbeReportCategories.informationQualityFailure;
  return <String, Object?>{
    'id': 'manual_attention',
    'layer': 'shared_writing_contract',
    'ok': scenarioOk,
    'covered_requirements': const <String>['manual_attention'],
    'production_contracts': const <String>[
      'long_task_recovery_state',
      'run_center_contract.stop_diagnosis',
    ],
    'observed_category': ValueReaders.stringValue(stopDiagnosis['category']),
    'probe_report_category': reportCategory,
    'run_center_contract': runCenterContract,
    'stop_diagnosis': stopDiagnosis,
    'summary': recoveryState.note,
  };
}

JsonMap _runNaturalCompletionScenario() {
  final result = WritingExecutionResultNormalizerService().normalize(
    executionId: 'suite_natural_completion',
    workflowKind: 'long_task_stability_suite',
    deliveryState: ChapterDeliveryStateResult(
      deliveryId: 'delivery_success_001',
      state: ChapterDeliveryStateStatuses.delivered,
      recommendedAction: 'accept',
      suggestedOutcomeStatus: DomainToolOutcomeStatuses.accepted,
      reason: 'accepted',
      summary: '章节正文已经稳定交付。',
      blocksProgress: false,
      chapterBodyDelivered: true,
      submissionAccepted: true,
      retryable: false,
      metadata: const <String, Object?>{
        'chapter_path': 'chapters/第01章.md',
        'resolved_chapter_path': 'chapters/第01章.md',
      },
    ),
  );
  final stopOutcome = const LongTaskStopOutcomeResolverService()
      .fromWritingExecutionResult(result);
  final runCenterContract = _buildSuiteRunCenterContract(
    status: TaskRuntimeConstants.statusSucceeded,
    stopReason: stopOutcome.reason,
    stopNote: result.summary,
    stopOutcome: stopOutcome,
  );
  final stopDiagnosis = ValueReaders.mapValue(
    runCenterContract['stop_diagnosis'],
  );
  final reportCategory = classifyDraftProbeReportCategory(
    ok: true,
    validation: <String, Object?>{
      'run_center_contract': runCenterContract,
      'summary': result.summary,
    },
  );
  final scenarioOk =
      result.overallStatus == WritingExecutionOutcomeStatuses.success &&
      ValueReaders.stringValue(stopDiagnosis['category']) ==
          LongTaskStopOutcomeCategories.completedNaturally &&
      reportCategory == ProbeReportCategories.success;
  return <String, Object?>{
    'id': 'natural_completion',
    'layer': 'shared_writing_contract',
    'ok': scenarioOk,
    'covered_requirements': const <String>['natural_completion'],
    'production_contracts': const <String>[
      'writing_execution_result',
      'long_task_stop_outcome',
      'run_center_contract.stop_diagnosis',
    ],
    'observed_category': ValueReaders.stringValue(stopDiagnosis['category']),
    'probe_report_category': reportCategory,
    'run_center_contract': runCenterContract,
    'stop_diagnosis': stopDiagnosis,
    'summary': result.summary,
  };
}

LongTaskRunCenterContractService _buildSuiteRunCenterContractService() {
  final modeService = LongTaskModeService();
  final strategyService = LongTaskModeStrategyService(modeService: modeService);
  final profileService = LongTaskControllerProfileService(
    modeService: modeService,
    strategyService: strategyService,
  );
  final taskSummaryService = LongTaskTaskSummaryService();
  final nextBatchPlanService = LongTaskNextBatchPlanService(
    modeService: modeService,
    profileService: profileService,
    unattendedStrategyService: LongTaskUnattendedStrategyService(
      modeService: modeService,
      strategyService: strategyService,
      profileService: profileService,
    ),
    taskSummaryService: taskSummaryService,
    taskSelectionService: TaskSelectionService(
      taskDefinitionService: TaskDefinitionService(),
    ),
  );
  return LongTaskRunCenterContractService(
    nextBatchPlanService: nextBatchPlanService,
    taskSummaryService: taskSummaryService,
  );
}

JsonMap _buildSuiteRunCenterContract({
  required String status,
  String stopReason = '',
  String stopNote = '',
  LongTaskStopOutcome stopOutcome = const LongTaskStopOutcome(),
  LongTaskRecoveryState recoveryState = const LongTaskRecoveryState(),
}) {
  return _suiteRunCenterContractService.runCenterContract(<String, Object?>{
    'id': 'ltsr20_suite_probe_run',
    'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
    'status': status,
    'stop_reason': stopReason,
    'stop_note': stopNote,
    'stop_outcome': stopOutcome.toJson(),
    'last_recovery_state': recoveryState.toJson(),
  }, const <Object?>[]);
}

JsonMap _buildSuiteSummary(List<JsonMap> scenarios) {
  final requirementCoverage = <String, JsonMap>{};
  var passed = 0;
  for (final scenario in scenarios) {
    if (ValueReaders.boolValue(scenario['ok'])) {
      passed += 1;
    }
    final scenarioId = ValueReaders.stringValue(scenario['id']);
    final coveredRequirements = ValueReaders.stringList(
      scenario['covered_requirements'],
    );
    for (final requirement in coveredRequirements) {
      final existing = ValueReaders.mapValue(requirementCoverage[requirement]);
      final scenarioIds = <String>[
        ...ValueReaders.stringList(existing['scenario_ids']),
        if (!ValueReaders.stringList(
          existing['scenario_ids'],
        ).contains(scenarioId))
          scenarioId,
      ];
      requirementCoverage[requirement] = <String, Object?>{
        'requirement': requirement,
        'scenario_ids': scenarioIds,
        'ok':
            ValueReaders.boolValue(existing['ok']) ||
            ValueReaders.boolValue(scenario['ok']),
      };
    }
  }
  final coverageList = requirementCoverage.values.toList(growable: false)
    ..sort(
      (left, right) => ValueReaders.stringValue(
        left['requirement'],
      ).compareTo(ValueReaders.stringValue(right['requirement'])),
    );
  return <String, Object?>{
    'total_scenarios': scenarios.length,
    'passed_scenarios': passed,
    'failed_scenarios': scenarios.length - passed,
    'required_coverage': coverageList,
    'all_required_coverage_passed': coverageList.every(
      (item) => ValueReaders.boolValue(item['ok']),
    ),
  };
}

String _renderMarkdownReport(JsonMap report) {
  final summary = ValueReaders.mapValue(report['summary']);
  final lines = <String>[
    '# LTSR-20 Mainline Mock Regression Suite',
    '',
    '- run_id: ${ValueReaders.stringValue(report['run_id'])}',
    '- workspace_root: ${ValueReaders.stringValue(report['workspace_root'])}',
    '- total_scenarios: ${ValueReaders.intValue(summary['total_scenarios'])}',
    '- passed_scenarios: ${ValueReaders.intValue(summary['passed_scenarios'])}',
    '- failed_scenarios: ${ValueReaders.intValue(summary['failed_scenarios'])}',
    '- all_required_coverage_passed: ${ValueReaders.boolValue(summary['all_required_coverage_passed'])}',
    '',
    '## Required Coverage',
  ];
  for (final rawCoverage in ValueReaders.mapList(
    summary['required_coverage'],
  )) {
    final coverage = ValueReaders.mapValue(rawCoverage);
    lines.add(
      '- ${ValueReaders.boolValue(coverage['ok']) ? 'PASS' : 'FAIL'} ${ValueReaders.stringValue(coverage['requirement'])}'
      ' | scenarios=${ValueReaders.stringList(coverage['scenario_ids']).join(', ')}',
    );
  }
  lines.add('');
  lines.add('## Scenarios');
  for (final rawScenario in ValueReaders.mapList(report['scenarios'])) {
    final scenario = ValueReaders.mapValue(rawScenario);
    lines.add('');
    lines.add(
      '- ${ValueReaders.boolValue(scenario['ok']) ? 'PASS' : 'FAIL'} ${ValueReaders.stringValue(scenario['id'])}'
      ' | layer=${ValueReaders.stringValue(scenario['layer'])}'
      ' | observed=${ValueReaders.stringValue(scenario['observed_category'])}',
    );
    lines.add('  summary: ${ValueReaders.stringValue(scenario['summary'])}');
  }
  return lines.join('\n');
}

JsonMap _buildReviewTask({
  required String id,
  required String title,
  required String markdownPath,
  required String jsonPath,
}) {
  return <String, Object?>{
    'id': id,
    'title': title,
    'task_type': 'review',
    'mode': TaskRuntimeConstants.modeSingleChapterAtomic,
    'status': TaskRuntimeConstants.statusQueued,
    'chapter': '第01章',
    'source_paths': <Object?>['chapters/第01章_seed_to_full.md'],
    'output_paths': <Object?>[markdownPath, jsonPath],
    'metadata': const <String, Object?>{
      'review_type': 'general',
      'stage': 'review',
    },
    'relative_path': 'tasks/$id.json',
  };
}

JsonMap _buildLongTaskChapterTask({
  required String id,
  required String title,
  required String chapter,
  required String outputPath,
  required int sortOrder,
  required String stage,
  List<String> dependsOn = const <String>[],
}) {
  return <String, Object?>{
    'schema_version': 1,
    'id': id,
    'title': title,
    'task_type': 'chapter',
    'mode': TaskRuntimeConstants.modeSeedToFullNovel,
    'status': TaskRuntimeConstants.statusQueued,
    'chapter': chapter,
    'goal': '按已确认规格、总纲和章纲生成本章正式正文。',
    'brief': 'LTSR-20 mock suite',
    'depends_on': dependsOn,
    'source_paths': const <Object?>[
      'specs/project_spec.md',
      'outline/总纲.md',
      'chapter_outlines/章节任务清单.md',
      'tracking/modes/seed_autopilot_novel/guidance.md',
      'styles/seed_autopilot_style.md',
    ],
    'output_paths': <Object?>[outputPath],
    'metadata': <String, Object?>{
      'plan_id': 'ltsr20_suite_plan',
      'workflow_mode': TaskRuntimeConstants.modeSeedToFullNovel,
      'sort_order': sortOrder,
      'stage': stage,
      'generated_by': 'LongTaskStabilityMockRegressionSuite',
      'persistent_context_paths': const <Object?>[
        'tracking/modes/seed_autopilot_novel/guidance.md',
        'styles/seed_autopilot_style.md',
      ],
    },
    'tool_hint': '先读取长期约束，再完成正式章节交付。',
    'created_at': '2026-06-07T00:00:00Z',
    'updated_at': '2026-06-07T00:00:00Z',
    'history': const <Object?>[
      <String, Object?>{
        'status': TaskRuntimeConstants.statusQueued,
        'note': 'created',
        'created_at': '2026-06-07T00:00:00Z',
      },
    ],
    'relative_path': 'tasks/$id.json',
  };
}

AppSettings _mockSettings() {
  const provider = ProviderEndpointSettings(
    id: 'mock-probe-provider',
    title: 'Mock Probe Provider',
    protocol: 'openai',
    baseUrl: 'https://example.invalid',
    apiKey: 'mock-key',
    modelId: 'mock-model',
    description: 'offline mock probe provider',
  );
  return const AppSettings(
    defaultProviderId: 'mock-probe-provider',
    defaultAgentId: '',
    defaultModelId: 'mock-model',
    defaultProjectPath: '',
    autoSaveDrafts: false,
    providers: <ProviderEndpointSettings>[provider],
  );
}

class _WorkflowRuntimeHarness {
  _WorkflowRuntimeHarness({
    required this.project,
    required this.workspacePort,
    required this.taskRepository,
    required this.promptTemplateService,
  });

  final ProjectDescriptor project;
  final LocalProjectWorkspacePort workspacePort;
  final ProjectTaskRepository taskRepository;
  final ProjectPromptTemplateService promptTemplateService;

  static Future<_WorkflowRuntimeHarness> create({
    required Directory workspaceRoot,
    required String scenarioId,
  }) async {
    final projectRoot = Directory(
      '${workspaceRoot.path}${Platform.pathSeparator}$scenarioId',
    );
    await projectRoot.create(recursive: true);
    final workspacePort = LocalProjectWorkspacePort();
    final taskRepository = ProjectTaskRepository(workspacePort: workspacePort);
    final promptTemplateService = ProjectPromptTemplateService(
      workspacePort: workspacePort,
    );
    final project = ProjectDescriptor(
      id: 'ltsr20_$scenarioId',
      name: 'LTSR20 $scenarioId',
      rootPath: projectRoot.path,
      projectType: 'long_novel',
    );
    await _seedProject(workspacePort: workspacePort, project: project);
    return _WorkflowRuntimeHarness(
      project: project,
      workspacePort: workspacePort,
      taskRepository: taskRepository,
      promptTemplateService: promptTemplateService,
    );
  }

  ProjectWorkflowRuntimeService buildRuntimeService({
    required LlmGateway gateway,
    Future<List<JsonMap>> Function(ProjectDescriptor project)?
    loadAvailableAgents,
    Future<List<JsonMap>> Function(ProjectDescriptor project)?
    loadAvailableAgentGroups,
    Future<List<ProjectAgentGroupSelection>> Function(
      ProjectDescriptor project,
    )?
    loadProjectAgentGroupSelections,
    ProjectLongTaskCheckpointReviewService? checkpointReviewService,
  }) {
    return ProjectWorkflowRuntimeService(
      taskRepository: taskRepository,
      promptTemplateService: promptTemplateService,
      loadProjectAgentGroupSelections: loadProjectAgentGroupSelections,
      loadAvailableAgents: loadAvailableAgents,
      loadAvailableAgentGroups: loadAvailableAgentGroups,
      checkpointReviewService: checkpointReviewService,
      hostAwareGenerateDraftUseCaseFactory:
          (
            _,
            _, {
            hostInformationPermissionContext,
            hostToolPermissionContext,
          }) => GenerateDraftUseCase(
            projectWorkspacePort: workspacePort,
            llmGateway: gateway,
            toolExecutionPort: _WorkflowToolExecutionPort(
              workspacePort: workspacePort,
            ),
            contextAssemblerService: ContextAssemblerService(
              budgetService: ContextBudgetService(),
              staticSectionService: ContextStaticSectionService(
                projectPromptContract: ProjectPromptContract(),
              ),
              projectFileSectionService: ContextProjectFileSectionService(),
            ),
            projectPromptContract: ProjectPromptContract(),
            hostPlatform: HostPlatform.windows,
            loadAvailableAgents: loadAvailableAgents,
            loadAvailableAgentGroups: loadAvailableAgentGroups,
          ),
      generateDraftUseCaseFactory: (_, _) => GenerateDraftUseCase(
        projectWorkspacePort: workspacePort,
        llmGateway: gateway,
        toolExecutionPort: _WorkflowToolExecutionPort(
          workspacePort: workspacePort,
        ),
        contextAssemblerService: ContextAssemblerService(
          budgetService: ContextBudgetService(),
          staticSectionService: ContextStaticSectionService(
            projectPromptContract: ProjectPromptContract(),
          ),
          projectFileSectionService: ContextProjectFileSectionService(),
        ),
        projectPromptContract: ProjectPromptContract(),
        hostPlatform: HostPlatform.windows,
        loadAvailableAgents: loadAvailableAgents,
        loadAvailableAgentGroups: loadAvailableAgentGroups,
      ),
    );
  }
}

Future<void> _seedProject({
  required LocalProjectWorkspacePort workspacePort,
  required ProjectDescriptor project,
}) async {
  await workspacePort.writeTextFile(
    project.rootPath,
    'specs/project_spec.md',
    '# 项目规格\n\n测试 LTSR-20 主链 mock regression suite。\n',
  );
  await workspacePort.writeTextFile(
    project.rootPath,
    'outline/总纲.md',
    '# 总纲\n\n第一章需要完成一次明确冲突推进。\n',
  );
  await workspacePort.writeTextFile(
    project.rootPath,
    'chapter_outlines/章节任务清单.md',
    '# 章节任务\n\n- 第01章：完成开局冲突与悬念。\n',
  );
  await workspacePort.writeTextFile(
    project.rootPath,
    'tracking/modes/seed_autopilot_novel/guidance.md',
    '# 模式摘要\n\n保持长期约束，不要跳过正式章节交付。\n',
  );
  await workspacePort.writeTextFile(
    project.rootPath,
    'styles/seed_autopilot_style.md',
    '# 风格\n\n干净利落，商业长篇口吻。\n',
  );
  await workspacePort.writeTextFile(
    project.rootPath,
    'chapters/第01章_seed_to_full.md',
    '# 第01章\n\n旧稿正文，用于 review/mock runtime 场景。\n',
  );
}

class _RecordingWorkflowGateway extends LlmGateway {
  _RecordingWorkflowGateway({required List<JsonMap> scriptedResults})
    : _scriptedResults = List<JsonMap>.from(scriptedResults);

  final List<JsonMap> _scriptedResults;
  final List<_RecordedWorkflowRequest> requests = <_RecordedWorkflowRequest>[];

  @override
  Future<JsonMap> requestChat({
    required ChatRequest request,
    DraftGenerationCancellationToken? cancellationToken,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) async {
    requests.add(
      _RecordedWorkflowRequest(
        modelId: request.modelId,
        toolNames: request.tools
            .map(
              (schema) => ValueReaders.stringValue(
                ValueReaders.mapValue(schema['function'])['name'],
              ),
            )
            .where((name) => name.trim().isNotEmpty)
            .toList(growable: false),
      ),
    );
    if (_scriptedResults.isEmpty) {
      return const <String, Object?>{
        'ok': true,
        'content': '',
        'tool_calls': <Object?>[],
        'message': <String, Object?>{'role': 'assistant', 'content': ''},
      };
    }
    return _scriptedResults.removeAt(0);
  }
}

class _RecordedWorkflowRequest {
  const _RecordedWorkflowRequest({
    required this.modelId,
    required this.toolNames,
  });

  final String modelId;
  final List<String> toolNames;
}

class _WorkflowToolExecutionPort implements ToolExecutionPort {
  _WorkflowToolExecutionPort({required LocalProjectWorkspacePort workspacePort})
    : _workspacePort = workspacePort;

  final LocalProjectWorkspacePort _workspacePort;

  @override
  Future<JsonMap> execute({
    required ProjectDescriptor project,
    required JsonMap toolCall,
  }) async {
    final name = ValueReaders.stringValue(toolCall['name']);
    final arguments = ValueReaders.mapValue(toolCall['arguments']);
    if (name == 'submit_chapter_delivery') {
      final chapterPath = ValueReaders.stringValue(arguments['chapter_path']);
      final chapterContent = ValueReaders.stringValue(
        arguments['chapter_content'],
      );
      await _workspacePort.writeTextFile(
        project.rootPath,
        chapterPath,
        chapterContent,
      );
      return <String, Object?>{
        'ok': true,
        'display_text': '已提交章节交付。',
        'changed_paths': <Object?>[
          chapterPath,
          '.novel_agent/continuity/deliveries/delivery-test-1.json',
        ],
        'interaction_type': 'domain_tool',
        'tool_layer': 'domain',
        'domain_tool_name': 'submit_chapter_delivery',
        'domain_outcome_status': 'accepted',
        'domain_outcome': <String, Object?>{
          'outcome_status': 'accepted',
          'outcome_payload': <String, Object?>{
            'delivery_id': 'delivery-test-1',
            'chapter_path': chapterPath,
            'delivery_state': 'delivered',
            'chapter_body_state': 'delivered',
            'sidecar_state': 'accepted',
            'state_result': <String, Object?>{
              'state': 'delivered',
              'chapter_body_delivered': true,
              'submission_accepted': true,
            },
          },
        },
      };
    }
    if (name == 'submit_semantic_review') {
      final review = NarrativeSemanticReview.fromJson(arguments);
      return <String, Object?>{
        'ok': true,
        'domain_tool_name': 'submit_semantic_review',
        'domain_outcome': <String, Object?>{
          'outcome_payload': <String, Object?>{
            'review': review.toJson(),
            'review_advances_workflow': false,
            'finding_count': review.findings.length,
            'blocking_finding_count': review.findings
                .where(
                  (finding) =>
                      finding.severity == SemanticReviewSeverity.blocking,
                )
                .length,
          },
          'metadata': <String, Object?>{
            'recommended_disposition': review.recommendedDisposition.id,
          },
        },
        'changed_paths': const <Object?>[],
      };
    }
    if (name == 'call_sub_agent') {
      return <String, Object?>{
        'ok': true,
        'agent_id': ValueReaders.stringValue(arguments['agent_id']),
        'agent_name': '审稿员',
        'task': ValueReaders.stringValue(arguments['task']),
        'summary': '子智能体已返回结果。',
        'result_markdown': '建议强化第一章冲突入口。',
        'changed_paths': const <Object?>[],
      };
    }
    if (name == 'present_user_options') {
      return <String, Object?>{
        'ok': true,
        'waiting_for_user_choice': true,
        'question': ValueReaders.stringValue(arguments['question']),
        'options': ValueReaders.objectList(arguments['options']),
        'changed_paths': const <Object?>[],
      };
    }
    if (name == 'load_agent_skill') {
      return <String, Object?>{
        'ok': true,
        'changed_paths': const <Object?>[],
        'display_text': '已加载技能。',
      };
    }
    throw UnimplementedError('Unexpected tool call: $name');
  }
}

class _FakeProjectLongTaskCheckpointReviewService
    extends ProjectLongTaskCheckpointReviewService {
  _FakeProjectLongTaskCheckpointReviewService({
    required this.response,
    this.persistentTaskRepository,
  }) : super(
         taskRepository: ProjectTaskRepository(
           workspacePort: LocalProjectWorkspacePort(),
         ),
       );

  final JsonMap response;
  final ProjectTaskRepository? persistentTaskRepository;

  @override
  Future<JsonMap> saveReview({
    required ProjectDescriptor project,
    required JsonMap task,
    required JsonMap result,
    required List<JsonMap> memorySections,
    JsonMap execution = const <String, Object?>{},
  }) async {
    final saved = ValueReaders.deepCopyMap(response);
    final repository = persistentTaskRepository;
    if (repository != null) {
      final relativePath = ValueReaders.stringValue(
        saved['relative_path'],
      ).trim();
      final review = ValueReaders.mapValue(saved['review']);
      if (relativePath.isNotEmpty && review.isNotEmpty) {
        await repository.saveRecord(project, relativePath, review);
      }
    }
    return saved;
  }
}
