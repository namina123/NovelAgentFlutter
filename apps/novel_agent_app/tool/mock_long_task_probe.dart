import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../tools/probe_config_support.dart';
import 'probe_support.dart';

Future<void> main() async {
  // 中文注释: RRP-06 mock probe 只走 production 同源 runtime/service，不联网、不读取真实 provider 配置。
  final repoRoot = resolveLocalProbeRepoRoot();
  final runId = DateTime.now().toIso8601String();
  final workspaceRoot = buildProbeWorkspaceDirectory(
    repoRoot: repoRoot,
    probeName: 'mock_long_task_probe',
    runId: runId,
  );
  await workspaceRoot.create(recursive: true);

  final bundle = AdapterBundle.standard(workingDirectoryPath: repoRoot);
  final scenarios = <JsonMap>[
    await _runWorkflowScenario(
      bundle: bundle,
      workspaceRoot: workspaceRoot,
      scenarioId: 'normal_chapter_success',
      scriptedResults: _chapterDeliveryScript(
        chapterPath: 'chapters/第01章_success.md',
        chapterContent: '# 第01章\n\n正式正文稳定落盘，冲突推进明确。',
      ),
      taskOverrides: const <String, Object?>{
        'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
        'chapter': '第01章',
        'output_paths': <Object?>['chapters/第01章_success.md'],
        'metadata': <String, Object?>{
          'stage': 'draft',
          'sort_order': 1,
          'plan_id': 'mock_probe_plan',
          'workflow_mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
          'runtime_baseline_id': 'chapter_collaboration_autorun',
          'persistent_context_paths': <Object?>[
            'tracking/modes/mock_probe/guidance.md',
            'styles/mock_probe_style.md',
          ],
        },
      },
      expectedReportCategory: ProbeReportCategories.success,
      expectedSignalCategory: 'success',
      expectedOverallStatus: WritingExecutionOutcomeStatuses.success,
      checkpointReviewResponse: _checkpointReviewResponse(
        relativePath: 'tracking/checkpoint_reviews/normal_success.json',
        summary: '正文交付、表达限制复核和 information 信号均通过，可继续推进。',
      ),
    ),
    await _runWorkflowScenario(
      bundle: bundle,
      workspaceRoot: workspaceRoot,
      scenarioId: 'empty_body_recoverable',
      scriptedResults: _chapterDeliveryScript(
        chapterPath: 'chapters/第01章_empty.md',
        chapterContent: '',
      ),
      taskOverrides: const <String, Object?>{
        'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
        'chapter': '第01章',
        'output_paths': <Object?>['chapters/第01章_empty.md'],
        'metadata': <String, Object?>{
          'stage': 'draft',
          'sort_order': 1,
          'plan_id': 'mock_probe_plan',
          'workflow_mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
          'runtime_baseline_id': 'chapter_collaboration_autorun',
          'persistent_context_paths': <Object?>[
            'tracking/modes/mock_probe/guidance.md',
            'styles/mock_probe_style.md',
          ],
        },
      },
      expectedReportCategory: ProbeReportCategories.contentQualityFailure,
      expectedSignalCategory: 'recoverable',
      expectedOverallStatus: WritingExecutionOutcomeStatuses.recoverableFailure,
      checkpointReviewResponse: _checkpointReviewResponse(
        relativePath: 'tracking/checkpoint_reviews/empty_body_recoverable.json',
        summary: '正文缺失，需要先补写后再继续。',
      ),
    ),
    await _runWorkflowScenario(
      bundle: bundle,
      workspaceRoot: workspaceRoot,
      scenarioId: 'title_only_quality_failure',
      scriptedResults: _chapterDeliveryScript(
        chapterPath: 'chapters/第01章_title_only.md',
        chapterContent: '# 第01章',
      ),
      taskOverrides: const <String, Object?>{
        'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
        'chapter': '第01章',
        'output_paths': <Object?>['chapters/第01章_title_only.md'],
        'metadata': <String, Object?>{
          'stage': 'draft',
          'sort_order': 1,
          'plan_id': 'mock_probe_plan',
          'workflow_mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
          'runtime_baseline_id': 'chapter_collaboration_autorun',
          'persistent_context_paths': <Object?>[
            'tracking/modes/mock_probe/guidance.md',
            'styles/mock_probe_style.md',
          ],
        },
      },
      expectedReportCategory: ProbeReportCategories.contentQualityFailure,
      expectedSignalCategory: 'content_quality_failed',
      expectedOverallStatus:
          WritingExecutionOutcomeStatuses.contentQualityIssue,
      checkpointReviewResponse: _checkpointReviewResponse(
        relativePath: 'tracking/checkpoint_reviews/title_only_quality.json',
        summary: '本轮输出只剩标题，需返修为有效正文。',
      ),
    ),
    _runConstraintScenario(),
    await _runWorkflowScenario(
      bundle: bundle,
      workspaceRoot: workspaceRoot,
      scenarioId: 'information_waiting_user',
      scriptedResults: _chapterDeliveryScript(
        chapterPath: 'chapters/第01章_information_wait.md',
        chapterContent: '# 第01章\n\n正文完成，但资料锚点仍待用户确认。',
      ),
      taskOverrides: const <String, Object?>{
        'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
        'chapter': '第01章',
        'output_paths': <Object?>['chapters/第01章_information_wait.md'],
        'metadata': <String, Object?>{
          'stage': 'draft',
          'sort_order': 1,
          'plan_id': 'mock_probe_plan',
          'workflow_mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
          'runtime_baseline_id': 'chapter_collaboration_autorun',
          'persistent_context_paths': <Object?>[
            'tracking/modes/mock_probe/guidance.md',
            'styles/mock_probe_style.md',
          ],
        },
      },
      checkpointReviewResponse: <String, Object?>{
        'ok': true,
        'relative_path': 'tracking/checkpoint_reviews/information_wait.json',
        'changed_paths': const <Object?>[
          'tracking/checkpoint_reviews/information_wait.json',
        ],
        'review': <String, Object?>{
          'summary': '有一项关键信息仍待用户确认。',
          'expression_constraint_review': const <String, Object?>{},
          'information_signal': <String, Object?>{
            'present': true,
            'category': 'checkpoint_user',
            'reason': 'information_waiting_user',
            'summary': '有一项关键信息仍待用户确认。',
            'waiting_user': true,
            'manual_attention_required': false,
            'requires_repair': false,
            'changed_paths': <Object?>['knowledge/项目知识摘要.md'],
          },
        },
      },
      expectedReportCategory: ProbeReportCategories.waitingUser,
      expectedSignalCategory: 'waiting_user',
      expectedOverallStatus: WritingExecutionOutcomeStatuses.userActionRequired,
    ),
    await _runBudgetRecoveryScenario(workspaceRoot),
    await _runSupervisorScenario(workspaceRoot),
    _runTechnicalFailureScenario(),
  ];

  final summary = _summaryForScenarios(scenarios);
  final report = <String, Object?>{
    'probe_id': 'rrp_06_long_task_mock_probe',
    'run_id': runId,
    'repo_root': repoRoot,
    'workspace_root': workspaceRoot.path,
    'started_at': runId,
    'finished_at': DateTime.now().toIso8601String(),
    'summary': summary,
    'scenarios': scenarios,
  };

  final jsonPath =
      '${workspaceRoot.path}${Platform.pathSeparator}mock_long_task_probe_report.json';
  final markdownPath =
      '${workspaceRoot.path}${Platform.pathSeparator}mock_long_task_probe_report.md';
  await File(
    jsonPath,
  ).writeAsString(const JsonEncoder.withIndent('  ').convert(report));
  await File(markdownPath).writeAsString(_renderMarkdown(report));

  stdout.writeln('=== RRP-06 Long Task Mock Probe ===');
  stdout.writeln('workspace: ${workspaceRoot.path}');
  stdout.writeln('report_json: $jsonPath');
  stdout.writeln('report_markdown: $markdownPath');
  stdout.writeln(
    'passed: ${ValueReaders.intValue(summary['passed_scenarios'])}/${ValueReaders.intValue(summary['total_scenarios'])}',
  );
  for (final rawScenario in scenarios) {
    final scenario = ValueReaders.mapValue(rawScenario);
    final prefix = ValueReaders.boolValue(scenario['ok']) ? '[PASS]' : '[FAIL]';
    stdout.writeln(
      '$prefix ${ValueReaders.stringValue(scenario['id'])} '
      '=> ${ValueReaders.stringValue(scenario['report_category'])}',
    );
  }

  if (scenarios.any((scenario) => !ValueReaders.boolValue(scenario['ok']))) {
    exitCode = 1;
  }
}

Future<JsonMap> _runWorkflowScenario({
  required AdapterBundle bundle,
  required Directory workspaceRoot,
  required String scenarioId,
  required List<JsonMap> scriptedResults,
  required JsonMap taskOverrides,
  required String expectedReportCategory,
  required String expectedSignalCategory,
  required String expectedOverallStatus,
  JsonMap checkpointReviewResponse = const <String, Object?>{},
  bool expectOk = true,
}) async {
  final projectRoot = Directory(
    '${workspaceRoot.path}${Platform.pathSeparator}$scenarioId',
  );
  await projectRoot.create(recursive: true);
  final project = ProjectDescriptor(
    id: 'mock_probe_$scenarioId',
    name: 'Mock Probe $scenarioId',
    rootPath: projectRoot.path,
    projectType: 'long_novel',
  );
  final taskRepository = ProjectTaskRepository(
    workspacePort: bundle.projectWorkspacePort,
  );
  final promptTemplateService = ProjectPromptTemplateService(
    workspacePort: bundle.projectWorkspacePort,
  );
  final outputPath = ValueReaders.stringList(
    taskOverrides['output_paths'],
  ).first;
  await _seedWorkflowProject(
    workspacePort: bundle.projectWorkspacePort,
    project: project,
    outputPath: outputPath,
  );
  await taskRepository.saveTasks(project, <JsonMap>[
    _buildTask(outputPath: outputPath, overrides: taskOverrides),
  ]);
  final workflowRuntimeService = _buildRuntimeService(
    bundle: bundle,
    taskRepository: taskRepository,
    promptTemplateService: promptTemplateService,
    gateway: _RecordingWorkflowGateway(scriptedResults: scriptedResults),
    checkpointReviewService: checkpointReviewResponse.isEmpty
        ? null
        : _FakeProjectLongTaskCheckpointReviewService(
            response: checkpointReviewResponse,
          ),
  );

  final result = await workflowRuntimeService.runWorkflowTaskOnce(
    project,
    _mockSettings(),
    const <String, Object?>{'id': 'task_001'},
  );
  final writingExecutionResult = ValueReaders.mapValue(
    result['writing_execution_result'],
  );
  final signal = const LongTaskWritingExecutionSignalService()
      .signalFromPayload(result: result);
  final reportCategory = _reportCategoryFromSharedState(
    writingExecutionResult,
    signal,
    stopReason: ValueReaders.stringValue(result['stop_reason']),
  );
  final actualOk = ValueReaders.boolValue(result['ok']);
  final actualOverallStatus = ValueReaders.stringValue(
    writingExecutionResult['overall_status'],
  );
  final actualSignalCategory = ValueReaders.stringValue(signal['category']);
  final scenarioOk =
      actualOk == expectOk &&
      reportCategory == expectedReportCategory &&
      actualSignalCategory == expectedSignalCategory &&
      actualOverallStatus == expectedOverallStatus;
  return <String, Object?>{
    'id': scenarioId,
    'layer': 'workflow_runtime',
    'ok': scenarioOk,
    'actual_ok': actualOk,
    'expected_ok': expectOk,
    'report_category': reportCategory,
    'expected_report_category': expectedReportCategory,
    'signal_category': actualSignalCategory,
    'expected_signal_category': expectedSignalCategory,
    'overall_status': actualOverallStatus,
    'expected_overall_status': expectedOverallStatus,
    'summary': ValueReaders.stringValue(
      writingExecutionResult['summary'],
      ValueReaders.stringValue(result['error']),
    ),
    'task_status_after': await _taskStatusAfter(taskRepository, project),
    'output_paths': ValueReaders.stringList(result['output_paths']),
    'changed_paths': ValueReaders.stringList(result['changed_paths']),
    'checkpoint_review_path': ValueReaders.stringValue(
      ValueReaders.mapValue(result['checkpoint_review'])['relative_path'],
    ),
    'next_action': ValueReaders.stringValue(
      writingExecutionResult['next_action'],
    ),
    'delivery_state': ValueReaders.stringValue(
      result['chapter_delivery_state'],
    ),
    'information_risk_category': ValueReaders.stringValue(
      ValueReaders.mapValue(
        writingExecutionResult['information'],
      )['risk_category'],
    ),
  };
}

JsonMap _runConstraintScenario() {
  final profile = const ChapterLengthProfile(
    enabled: true,
    targetLength: 2200,
    preferredMin: 1800,
    preferredMax: 2600,
    stage: 'draft',
  );
  final evaluation = ChapterLengthEvaluation(
    profile: profile,
    policy: const ChapterLengthDistributionPolicy(),
    currentRecord: const ChapterLengthRecord(
      length: 800,
      sortOrder: 1,
      taskId: 'constraint_task',
      title: '严重字数偏离样例',
      relativePath: 'chapters/ch01.md',
    ),
    level: 'severely_off',
    recommendedAction: 'review_or_repair',
    notes: const <String>['本章字数偏离明显，建议进入 review / repair。'],
    rollingAverageLength: 2100,
    previousLength: 2300,
    adjacentDelta: 1500,
    targetDeviation: -1400,
    targetDeviationRatio: -0.63,
    adjacentDeltaRatio: 0.65,
    historySamplesUsed: 3,
  );
  final result = WritingExecutionResultNormalizerService().normalize(
    executionId: 'constraint_probe',
    workflowKind: 'long_task_mock_probe',
    constraintBridgeResult: WritingExecutionConstraintBridgeResult(
      chapterLengthMetadata: <String, Object?>{
        'chapter_length_profile': profile.toJson(),
      },
      runtimeReport: const <String, Object?>{
        'chapter_length': <String, Object?>{'source': 'binding'},
      },
    ),
    chapterLengthEvaluation: evaluation,
  );
  final signal = const LongTaskWritingExecutionSignalService()
      .signalFromWritingExecutionResult(result);
  final reportCategory = _reportCategoryFromSharedState(
    result.toJson(),
    signal,
  );
  final scenarioOk =
      reportCategory == ProbeReportCategories.contentQualityFailure &&
      ValueReaders.stringValue(signal['category']) == 'recoverable' &&
      result.overallStatus ==
          WritingExecutionOutcomeStatuses.contentQualityIssue;
  return <String, Object?>{
    'id': 'severe_word_count_constraint',
    'layer': 'core_constraint_contract',
    'ok': scenarioOk,
    'report_category': reportCategory,
    'expected_report_category': ProbeReportCategories.contentQualityFailure,
    'signal_category': ValueReaders.stringValue(signal['category']),
    'expected_signal_category': 'recoverable',
    'overall_status': result.overallStatus,
    'expected_overall_status':
        WritingExecutionOutcomeStatuses.contentQualityIssue,
    'summary': result.summary,
    'next_action': result.nextAction,
    'hard_gate_reasons': result.constraints.hardGateReasons,
  };
}

Future<JsonMap> _runBudgetRecoveryScenario(Directory workspaceRoot) async {
  final record = <String, Object?>{
    'id': 'budget_probe',
    'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
    'status': TaskRuntimeConstants.statusPaused,
    'stop_reason': 'max_steps',
    'stop_note': '已达到本批最大步数。',
  };
  final recoveryPlan = LongTaskRecoveryService().recoveryPlan(
    record,
    const <Object?>[],
  );
  final scheduler = LongTaskSchedulerTickPlanService(
    modeService: LongTaskModeService(),
    recoveryService: LongTaskRecoveryService(),
    nextBatchPlanService: LongTaskNextBatchPlanService(
      modeService: LongTaskModeService(),
      profileService: LongTaskControllerProfileService(
        modeService: LongTaskModeService(),
        strategyService: LongTaskModeStrategyService(
          modeService: LongTaskModeService(),
        ),
      ),
      unattendedStrategyService: LongTaskUnattendedStrategyService(
        modeService: LongTaskModeService(),
        strategyService: LongTaskModeStrategyService(
          modeService: LongTaskModeService(),
        ),
        profileService: LongTaskControllerProfileService(
          modeService: LongTaskModeService(),
          strategyService: LongTaskModeStrategyService(
            modeService: LongTaskModeService(),
          ),
        ),
      ),
      taskSummaryService: LongTaskTaskSummaryService(),
      taskSelectionService: TaskSelectionService(
        taskDefinitionService: TaskDefinitionService(),
      ),
    ),
    runCenterContractService: LongTaskRunCenterContractService(
      nextBatchPlanService: LongTaskNextBatchPlanService(
        modeService: LongTaskModeService(),
        profileService: LongTaskControllerProfileService(
          modeService: LongTaskModeService(),
          strategyService: LongTaskModeStrategyService(
            modeService: LongTaskModeService(),
          ),
        ),
        unattendedStrategyService: LongTaskUnattendedStrategyService(
          modeService: LongTaskModeService(),
          strategyService: LongTaskModeStrategyService(
            modeService: LongTaskModeService(),
          ),
          profileService: LongTaskControllerProfileService(
            modeService: LongTaskModeService(),
            strategyService: LongTaskModeStrategyService(
              modeService: LongTaskModeService(),
            ),
          ),
        ),
        taskSummaryService: LongTaskTaskSummaryService(),
        taskSelectionService: TaskSelectionService(
          taskDefinitionService: TaskDefinitionService(),
        ),
      ),
      taskSummaryService: LongTaskTaskSummaryService(),
    ),
  );
  final schedulerPlan = scheduler.schedulerTickPlan(record, const <Object?>[]);
  final scenarioOk =
      ValueReaders.stringValue(recoveryPlan['action']) == 'resume_dispatch' &&
      ValueReaders.stringValue(schedulerPlan['action']) == 'pause';
  return <String, Object?>{
    'id': 'supervisor_budget_recovery',
    'layer': 'recovery_scheduler',
    'ok': scenarioOk,
    'report_category': ProbeReportCategories.budgetFailure,
    'expected_report_category': ProbeReportCategories.budgetFailure,
    'signal_category': 'budget_failed',
    'expected_signal_category': 'budget_failed',
    'overall_status': 'budget_boundary',
    'expected_overall_status': 'budget_boundary',
    'summary': ValueReaders.stringValue(recoveryPlan['note']),
    'recovery_action': ValueReaders.stringValue(recoveryPlan['action']),
    'scheduler_action': ValueReaders.stringValue(schedulerPlan['action']),
    'workspace_root': workspaceRoot.path,
  };
}

Future<JsonMap> _runSupervisorScenario(Directory workspaceRoot) async {
  final registryRoot = Directory(
    '${workspaceRoot.path}${Platform.pathSeparator}supervisor_registry',
  );
  await registryRoot.create(recursive: true);
  final registry = LocalLongTaskRunRegistry(
    settingsRootPath: registryRoot.path,
  );
  final scheduler = LongTaskHeartbeatScheduler(
    runRegistry: registry,
    runtimeBaselineCatalogService: const RuntimeBaselineCatalogService(),
  );
  final watchdog = LongTaskWatchdog(
    runRegistry: registry,
    heartbeatScheduler: scheduler,
  );
  final supervisor = LongTaskSupervisor(
    runRegistry: registry,
    watchdogDispatchPort: watchdog,
  );
  final run = const RunInstanceFactoryService().createLongTaskInstance(
    runId: 'supervisor_probe_run',
    project: ProjectDescriptor(
      id: 'supervisor_probe_project',
      name: 'Supervisor Probe',
      rootPath: registryRoot.path,
      projectType: 'long_novel',
      storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
    ),
    runtimeBaseline: const RuntimeBaselineCatalogService().byId(
      'continuous_autonomous',
    )!,
    modeId: TaskRuntimeConstants.modeHumanOutlineAiDraft,
    workflowStrategyId: 'resumable_long_task',
    initialStatus: LongTaskRunStatus.running,
    now: DateTime.parse('2026-06-05T12:00:00.000Z'),
  );
  await supervisor.trackRun(run);
  final updated = await supervisor.applyWritingExecutionResult(
    run.id,
    <String, Object?>{
      'execution_id': 'supervisor_probe_result',
      'workflow_kind': 'long_task_mock_probe',
      'overall_status': WritingExecutionOutcomeStatuses.contentQualityIssue,
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
  );
  final signal = ValueReaders.mapValue(
    ValueReaders.mapValue(updated?.metadata)['writing_execution_signal'],
  );
  final scenarioOk =
      updated != null &&
      updated.status == LongTaskRunStatus.failedManualAttention &&
      ValueReaders.stringValue(signal['category']) == 'content_quality_failed';
  return <String, Object?>{
    'id': 'supervisor_shared_state_consumption',
    'layer': 'runtime_supervisor',
    'ok': scenarioOk,
    'report_category': ProbeReportCategories.contentQualityFailure,
    'expected_report_category': ProbeReportCategories.contentQualityFailure,
    'signal_category': ValueReaders.stringValue(signal['category']),
    'expected_signal_category': 'content_quality_failed',
    'overall_status': WritingExecutionOutcomeStatuses.contentQualityIssue,
    'expected_overall_status':
        WritingExecutionOutcomeStatuses.contentQualityIssue,
    'summary': updated?.note ?? '',
    'run_status': updated?.status.id ?? '',
  };
}

JsonMap _runTechnicalFailureScenario() {
  final result = WritingExecutionResultNormalizerService().normalize(
    executionId: 'technical_probe',
    workflowKind: 'long_task_mock_probe',
    recoveryPlan: const <String, Object?>{
      'action': 'pause_for_failure',
      'reason': 'failed_task',
      'note': 'mock transport failed',
    },
    transportFailed: true,
  );
  final signal = const LongTaskWritingExecutionSignalService()
      .signalFromWritingExecutionResult(result);
  final reportCategory = _reportCategoryFromSharedState(
    result.toJson(),
    signal,
  );
  final scenarioOk =
      reportCategory == ProbeReportCategories.technicalFailure &&
      ValueReaders.stringValue(signal['category']) == 'technical_failed' &&
      result.overallStatus == WritingExecutionOutcomeStatuses.technicalFailure;
  return <String, Object?>{
    'id': 'technical_failure_classification',
    'layer': 'core_recovery_contract',
    'ok': scenarioOk,
    'report_category': reportCategory,
    'expected_report_category': ProbeReportCategories.technicalFailure,
    'signal_category': ValueReaders.stringValue(signal['category']),
    'expected_signal_category': 'technical_failed',
    'overall_status': result.overallStatus,
    'expected_overall_status': WritingExecutionOutcomeStatuses.technicalFailure,
    'summary': result.summary,
    'next_action': result.nextAction,
  };
}

ProjectWorkflowRuntimeService _buildRuntimeService({
  required AdapterBundle bundle,
  required ProjectTaskRepository taskRepository,
  required ProjectPromptTemplateService promptTemplateService,
  required LlmGateway gateway,
  ProjectDraftExecutionConstraintRuntimeService?
  draftExecutionConstraintRuntimeService,
  ProjectLongTaskCheckpointReviewService? checkpointReviewService,
}) {
  return ProjectWorkflowRuntimeService(
    taskRepository: taskRepository,
    promptTemplateService: promptTemplateService,
    checkpointReviewService: checkpointReviewService,
    draftExecutionConstraintRuntimeService:
        draftExecutionConstraintRuntimeService,
    generateDraftUseCaseFactory: (_, _) => GenerateDraftUseCase(
      projectWorkspacePort: bundle.projectWorkspacePort,
      llmGateway: gateway,
      toolExecutionPort: bundle.projectToolExecutionPort,
      contextAssemblerService: ContextAssemblerService(
        budgetService: ContextBudgetService(),
        staticSectionService: ContextStaticSectionService(
          projectPromptContract: ProjectPromptContract(),
        ),
        projectFileSectionService: ContextProjectFileSectionService(),
      ),
      projectPromptContract: ProjectPromptContract(),
      hostPlatform: HostPlatform.windows,
      loadAvailableAgents: (project) =>
          bundle.agentPackageCatalog.loadAgentPackages(project),
      loadAvailableAgentGroups: (project) =>
          bundle.agentGroupCatalog.loadAgentGroups(project),
    ),
  );
}

Future<void> _seedWorkflowProject({
  required ProjectWorkspacePort workspacePort,
  required ProjectDescriptor project,
  required String outputPath,
}) async {
  await workspacePort.writeTextFile(
    project.rootPath,
    'specs/project_spec.md',
    '# 项目规格\n\n测试长任务 mock probe 的共享合同链路。\n',
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
    'tracking/modes/mock_probe/guidance.md',
    '# 模式摘要\n\n保持长期约束，不要跳过正式章节交付。\n',
  );
  await workspacePort.writeTextFile(
    project.rootPath,
    'styles/mock_probe_style.md',
    '# 风格\n\n干净利落，商业长篇口吻。\n',
  );
  final parent = File(
    '${project.rootPath}${Platform.pathSeparator}${outputPath.replaceAll('/', Platform.pathSeparator)}',
  ).parent;
  await parent.create(recursive: true);
}

JsonMap _buildTask({
  required String outputPath,
  JsonMap overrides = const <String, Object?>{},
}) {
  final metadata = ValueReaders.deepCopyMap(
    ValueReaders.mapValue(overrides['metadata']),
  );
  final chapter = ValueReaders.stringValue(overrides['chapter'], '第01章');
  final title = ValueReaders.stringValue(
    overrides['title'],
    chapter.trim().isEmpty ? 'Mock Probe 第01章' : chapter,
  );
  return <String, Object?>{
    'schema_version': 1,
    'id': 'task_001',
    'title': title,
    'task_type': 'chapter',
    'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
    'status': TaskRuntimeConstants.statusQueued,
    'chapter': chapter,
    'goal': '写出正式章节正文，并完成共享交付合同。',
    'brief': 'RRP-06 mock probe',
    'depends_on': const <Object?>[],
    'source_paths': const <Object?>[
      'specs/project_spec.md',
      'outline/总纲.md',
      'chapter_outlines/章节任务清单.md',
      'tracking/modes/mock_probe/guidance.md',
      'styles/mock_probe_style.md',
    ],
    'output_paths': <Object?>[outputPath],
    'metadata': <String, Object?>{
      'plan_id': 'mock_probe_plan',
      'workflow_mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
      'sort_order': 1,
      'stage': 'draft',
      'generated_by': 'MockLongTaskProbe',
      'runtime_baseline_id': 'chapter_collaboration_autorun',
      'persistent_context_paths': const <Object?>[
        'tracking/modes/mock_probe/guidance.md',
        'styles/mock_probe_style.md',
      ],
      ...metadata,
    },
    'tool_hint': '先读取长期约束，再完成正式章节交付。',
    'created_at': '2026-06-05T00:00:00Z',
    'updated_at': '2026-06-05T00:00:00Z',
    'history': const <Object?>[
      <String, Object?>{
        'status': TaskRuntimeConstants.statusQueued,
        'note': 'created',
        'created_at': '2026-06-05T00:00:00Z',
      },
    ],
    'relative_path': 'tasks/task_001.json',
    ...ValueReaders.deepCopyMap(overrides)..remove('metadata'),
  };
}

Future<String> _taskStatusAfter(
  ProjectTaskRepository taskRepository,
  ProjectDescriptor project,
) async {
  final task = await taskRepository.loadTask(project, const <String, Object?>{
    'id': 'task_001',
  });
  return ValueReaders.stringValue(task['status']);
}

List<JsonMap> _chapterDeliveryScript({
  required String chapterPath,
  required String chapterContent,
}) {
  return <JsonMap>[
    <String, Object?>{
      'ok': true,
      'content': '',
      'tool_calls': <Object?>[
        <String, Object?>{
          'id': 'call_delivery_1',
          'name': 'submit_chapter_delivery',
          'arguments': <String, Object?>{
            'chapter_path': chapterPath,
            'chapter_content': chapterContent,
            'title': '第01章',
            'submission': const <String, Object?>{
              'submission_id': 'mock-delivery-1',
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
  ];
}

JsonMap _checkpointReviewResponse({
  required String relativePath,
  required String summary,
  JsonMap informationSignal = const <String, Object?>{
    'present': false,
    'category': 'accept',
    'summary': '当前没有新的 information 风险信号。',
    'reason': '',
    'waiting_user': false,
    'manual_attention_required': false,
    'requires_repair': false,
    'changed_paths': <Object?>[],
  },
  JsonMap expressionConstraintReview = const <String, Object?>{
    'authenticity_pass_level': 'aggressive',
    'review_focuses': <Object?>['检查叙述是否自然，不要回落到模板化解释腔。'],
    'continuity_watch_items': <Object?>['确认本章推进没有破坏已知因果链。'],
    'mini_recheck_items': <Object?>['确认落盘正文不是标题-only 或空正文。'],
    'voice_protection_notes': <Object?>['保留人物说话习惯，不把语气抹平。'],
  },
}) {
  return <String, Object?>{
    'ok': true,
    'relative_path': relativePath,
    'changed_paths': <Object?>[relativePath],
    'review': <String, Object?>{
      'summary': summary,
      'expression_constraint_review': ValueReaders.deepCopyMap(
        expressionConstraintReview,
      ),
      'information_signal': ValueReaders.deepCopyMap(informationSignal),
    },
  };
}

String _reportCategoryFromSharedState(
  JsonMap writingExecutionResult,
  JsonMap signal, {
  String stopReason = '',
}) {
  if (stopReason == 'max_steps' || stopReason == 'max_seconds') {
    return ProbeReportCategories.budgetFailure;
  }
  final signalCategory = ValueReaders.stringValue(signal['category']);
  switch (signalCategory) {
    case 'success':
      return ProbeReportCategories.success;
    case 'waiting_user':
      return ProbeReportCategories.waitingUser;
    case 'technical_failed':
      return ProbeReportCategories.technicalFailure;
    case 'budget_failed':
      return ProbeReportCategories.budgetFailure;
  }
  final overallStatus = ValueReaders.stringValue(
    writingExecutionResult['overall_status'],
  );
  if (overallStatus == WritingExecutionOutcomeStatuses.technicalFailure) {
    return ProbeReportCategories.technicalFailure;
  }
  if (overallStatus == WritingExecutionOutcomeStatuses.userActionRequired) {
    return ProbeReportCategories.waitingUser;
  }
  if (ValueReaders.boolValue(
    ValueReaders.mapValue(
      writingExecutionResult['information'],
    )['requires_repair'],
  )) {
    return ProbeReportCategories.informationQualityFailure;
  }
  return ProbeReportCategories.contentQualityFailure;
}

JsonMap _summaryForScenarios(List<JsonMap> scenarios) {
  final categoryCounts = <String, int>{};
  var passed = 0;
  for (final scenario in scenarios) {
    if (ValueReaders.boolValue(scenario['ok'])) {
      passed += 1;
    }
    final category = ValueReaders.stringValue(scenario['report_category']);
    categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
  }
  return <String, Object?>{
    'total_scenarios': scenarios.length,
    'passed_scenarios': passed,
    'failed_scenarios': scenarios.length - passed,
    'category_counts': categoryCounts,
  };
}

String _renderMarkdown(JsonMap report) {
  final lines = <String>[
    '# RRP-06 长任务 Mock Probe 报告',
    '',
    '- run_id: ${ValueReaders.stringValue(report['run_id'])}',
    '- workspace_root: ${ValueReaders.stringValue(report['workspace_root'])}',
    '- total_scenarios: ${ValueReaders.intValue(ValueReaders.mapValue(report['summary'])['total_scenarios'])}',
    '- passed_scenarios: ${ValueReaders.intValue(ValueReaders.mapValue(report['summary'])['passed_scenarios'])}',
    '- failed_scenarios: ${ValueReaders.intValue(ValueReaders.mapValue(report['summary'])['failed_scenarios'])}',
    '',
    '## Scenarios',
  ];
  for (final rawScenario in ValueReaders.mapList(report['scenarios'])) {
    final scenario = ValueReaders.mapValue(rawScenario);
    lines.add('');
    lines.add(
      '- ${ValueReaders.boolValue(scenario['ok']) ? 'PASS' : 'FAIL'}'
      ' ${ValueReaders.stringValue(scenario['id'])}'
      ' | layer=${ValueReaders.stringValue(scenario['layer'])}'
      ' | report=${ValueReaders.stringValue(scenario['report_category'])}'
      ' | signal=${ValueReaders.stringValue(scenario['signal_category'])}',
    );
    lines.add('  summary: ${ValueReaders.stringValue(scenario['summary'])}');
    final nextAction = ValueReaders.stringValue(
      scenario['next_action'],
      ValueReaders.stringValue(scenario['recovery_action']),
    );
    if (nextAction.isNotEmpty) {
      lines.add('  next_action: $nextAction');
    }
  }
  return lines.join('\n');
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
  return AppSettings(
    defaultProviderId: 'mock-probe-provider',
    defaultAgentId: '',
    defaultModelId: 'mock-model',
    defaultProjectPath: '',
    autoSaveDrafts: false,
    providers: <ProviderEndpointSettings>[provider],
  );
}

class _RecordingWorkflowGateway extends LlmGateway {
  _RecordingWorkflowGateway({required List<JsonMap> scriptedResults})
    : _scriptedResults = List<JsonMap>.from(scriptedResults);

  final List<JsonMap> _scriptedResults;

  @override
  Future<JsonMap> requestChat({
    required ChatRequest request,
    DraftGenerationCancellationToken? cancellationToken,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) async {
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

class _FakeProjectLongTaskCheckpointReviewService
    extends ProjectLongTaskCheckpointReviewService {
  _FakeProjectLongTaskCheckpointReviewService({required this.response})
    : super(
        taskRepository: ProjectTaskRepository(
          workspacePort: LocalProjectWorkspacePort(),
        ),
      );

  final JsonMap response;

  @override
  Future<JsonMap> saveReview({
    required ProjectDescriptor project,
    required JsonMap task,
    required JsonMap result,
    required List<JsonMap> memorySections,
    JsonMap execution = const <String, Object?>{},
  }) async {
    return ValueReaders.deepCopyMap(response);
  }
}
