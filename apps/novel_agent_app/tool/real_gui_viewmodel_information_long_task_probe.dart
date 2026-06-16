import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import 'package:novel_agent_app/features/long_task_station/application/models/long_task_station_snapshot.dart';
import 'package:novel_agent_app/features/long_task_station/application/services/long_task_station_view_data_service.dart';
import 'package:novel_agent_app/features/workbench/application/services/workspace_information_projection_service.dart';
import 'probe_support.dart';
import '../../../tools/probe_config_support.dart';

const String _probeModelId = 'deepseek-v4-pro';

Future<void> main(List<String> arguments) async {
  await ensureLocalRealProbeOptIn(
    probeName: 'real_gui_viewmodel_information_long_task_probe',
  );
  final runtimeOptions = _ProbeRuntimeOptions.fromArguments(arguments);
  final repoRoot = resolveLocalProbeRepoRoot();
  final bundle = AdapterBundle.standard(workingDirectoryPath: repoRoot);
  final localSettings = await bundle.settingsRepository.load();
  final apiConfig = await loadProbeApiConfig(
    probeName: 'real_gui_viewmodel_information_long_task_probe',
    repoRootOverride: repoRoot,
  );
  final provider = ProviderEndpointSettings(
    id: 'real_gui_viewmodel_information_long_task_probe',
    title: 'Real GUI ViewModel Information Long Task Probe',
    protocol: 'openai_compatible',
    baseUrl: apiConfig.baseUrl,
    apiKey: apiConfig.apiKey,
    modelId: _probeModelId,
    description:
        'Real provider probe for GUI/viewmodel information evidence and long task stability.',
    isDefault: true,
  );
  final settings = AppSettings(
    defaultProviderId: provider.id,
    defaultAgentId: 'default_generalist',
    defaultModelId: provider.modelId,
    defaultProjectPath: '',
    autoSaveDrafts: false,
    providers: <ProviderEndpointSettings>[provider],
    permissionSettings: const <String, Object?>{
      'information_permission_mode': 'open',
      'allow_network': true,
      'allow_import_collection': true,
      'information_confirmation_mode': 'automatic',
    },
    networkSettings: localSettings.networkSettings.isEmpty
        ? const <String, Object?>{'proxy_mode': 'system'}
        : localSettings.networkSettings,
    extraSettings: <String, Object?>{
      'model_settings': <String, Object?>{
        'provider_id': provider.id,
        'model_id': _probeModelId,
        'stream_mode': 'non_stream',
        'api_mode': 'chat',
      },
    },
  );

  final runId = DateTime.now().toIso8601String();
  final workspaceRoot = buildProbeWorkspaceDirectory(
    repoRoot: repoRoot,
    probeName: 'real_gui_viewmodel_information_long_task_probe',
    runId: runId,
  );
  await workspaceRoot.create(recursive: true);
  final runArtifactDir = Directory(
    '$repoRoot${Platform.pathSeparator}artifacts${Platform.pathSeparator}'
    'real_gui_viewmodel_information_long_task_probe_runs'
    '${Platform.pathSeparator}${safeProbeTimestamp(runId)}',
  );
  await runArtifactDir.create(recursive: true);

  final report = <String, Object?>{
    'probe_name': 'real_gui_viewmodel_information_long_task_probe',
    'provider_id': provider.id,
    'model_id': provider.modelId,
    'probe_config_source': apiConfig.sourceLabel,
    'run_id': runId,
    'started_at': DateTime.now().toIso8601String(),
    'workspace_root': workspaceRoot.path,
    'run_artifact_dir': runArtifactDir.path,
    'story_seed': _storySeedSummary,
    'budget_policy': <String, Object?>{
      'chapter_budget_upper_bound': _chapterBudgetUpperBound,
      'probe_execution_safety_batches': runtimeOptions.queueBatches,
      'queue_max_steps_per_batch': runtimeOptions.queueMaxStepsPerBatch,
      'expression_constraint_policy_mode':
          runtimeOptions.expressionConstraintPolicyMode,
      'note': '200章是测试预算上限；探针不会预先硬排全部章节，章节推进与节奏由长任务队列和智能体自然展开。',
    },
  };

  try {
    final project = await _createProbeProject(
      bundle: bundle,
      workspaceRoot: workspaceRoot,
    );
    report['project_root'] = project.rootPath;
    await _seedHistoricalTransmigrationProject(
      bundle.projectWorkspacePort,
      project,
    );
    final expressionConstraintSetup = await _installProbeExpressionConstraints(
      bundle: bundle,
      project: project,
    );
    report['expression_constraint_setup'] = expressionConstraintSetup;

    stdout.writeln('ordinary viewmodel step ...');
    final ordinaryWorkbenchStep = await _runOrdinaryWorkbenchStep(
      bundle: bundle,
      settings: settings,
      provider: provider,
      project: project,
      runtimeOptions: runtimeOptions,
    );
    report['ordinary_workbench_step'] = ordinaryWorkbenchStep;
    if (!ValueReaders.boolValue(ordinaryWorkbenchStep['ok'])) {
      throw StateError(
        ValueReaders.stringValue(
          ordinaryWorkbenchStep['error'],
          '普通工作台会话没有形成有效推进。',
        ),
      );
    }

    stdout.writeln('long task setup ...');
    report['long_task_setup'] = await _createLongTaskPlan(
      bundle: bundle,
      settings: settings,
      provider: provider,
      project: project,
      runtimeOptions: runtimeOptions,
    );

    stdout.writeln('long task queue batches ...');
    report['long_task_batches'] = await _runLongTaskBatches(
      bundle: bundle,
      settings: settings,
      project: project,
      runArtifactDir: runArtifactDir,
      repoRoot: repoRoot,
      runtimeOptions: runtimeOptions,
    );

    stdout.writeln('viewmodel projection ...');
    final viewmodel = await _buildGuiViewModelReport(
      bundle: bundle,
      project: project,
    );
    report['gui_viewmodel'] = viewmodel;

    final validation = _validateReport(report);
    report['validation'] = validation;
    report['ok'] = ValueReaders.boolValue(validation['ok']);
    report['report_category'] = ValueReaders.boolValue(validation['ok'])
        ? ProbeReportCategories.success
        : ValueReaders.stringValue(
            validation['report_category'],
            ProbeReportCategories.contentQualityFailure,
          );
  } catch (error, stackTrace) {
    report['ok'] = false;
    report['error'] = '$error';
    report['stack_trace'] = '$stackTrace';
    report['report_category'] = classifyDraftProbeReportCategory(
      ok: false,
      errorSummary: '$error',
    );
  } finally {
    report['finished_at'] = DateTime.now().toIso8601String();
    await _writeReports(repoRoot, runArtifactDir, report);
    stdout.writeln(ValueReaders.boolValue(report['ok']) ? 'PASS' : 'FAIL');
    if (!ValueReaders.boolValue(report['ok'])) {
      exitCode = 1;
    }
  }
}

Future<ProjectDescriptor> _createProbeProject({
  required AdapterBundle bundle,
  required Directory workspaceRoot,
}) {
  final createProjectWorkspaceUseCase = CreateProjectWorkspaceUseCase(
    projectRepository: bundle.projectRepository,
    projectWorkspacePort: bundle.projectWorkspacePort,
    projectContentRepository: bundle.projectContentRepository,
    projectReadableProjectionService: bundle.projectReadableProjectionService,
  );
  return createProjectWorkspaceUseCase.execute(
    projectsRootPath: workspaceRoot.path,
    title: '明代社畜穿越资料纪律探针',
    projectType: 'long_novel',
    runtimeBaselineId: 'continuous_autonomous',
  );
}

Future<JsonMap> _installProbeExpressionConstraints({
  required AdapterBundle bundle,
  required ProjectDescriptor project,
}) async {
  final profileRepository = ExpressionConstraintProfileRepository(
    workspacePort: bundle.projectWorkspacePort,
  );
  final bindingRepository = ProjectExpressionConstraintBindingRepository(
    workspacePort: bundle.projectWorkspacePort,
  );
  final bindings = defaultProbeExpressionBindings(
    idPrefix: 'gui_viewmodel_probe',
  );
  await bindingRepository.saveBindings(project, bindings);
  final profiles = await profileRepository.loadProfiles(project);
  return buildProbeExpressionConstraintSetupReport(
    loadedProfiles: profiles,
    savedBindings: bindings,
  );
}

Future<JsonMap> _runOrdinaryWorkbenchStep({
  required AdapterBundle bundle,
  required AppSettings settings,
  required ProviderEndpointSettings provider,
  required ProjectDescriptor project,
  required _ProbeRuntimeOptions runtimeOptions,
}) async {
  final taskRepository = ProjectTaskRepository(
    workspacePort: bundle.projectWorkspacePort,
  );
  final conversationRuntimeService = ProjectConversationDraftRuntimeService(
    workspacePort: bundle.projectWorkspacePort,
    hostPort: bundle.projectToolHostPort,
    taskRepository: taskRepository,
  );
  final draftExecutionConstraintRuntimeService =
      ProjectDraftExecutionConstraintRuntimeService.fromWorkspacePort(
        workspacePort: bundle.projectWorkspacePort,
      );
  final executionConstraints = await draftExecutionConstraintRuntimeService
      .resolve(
        project,
        appliesTo: ConstraintBindingAppliesTo.writing,
        agentId: 'default_generalist',
        stageId: 'draft',
        legacyChapterLengthOptions: const <String, Object?>{
          'enable_chapter_word_constraints': true,
          'chapter_word_target': 2000,
          'chapter_word_min': 1600,
          'chapter_word_max': 2600,
        },
        expressionConstraintPolicyMode:
            runtimeOptions.expressionConstraintPolicyMode,
      );
  final preparation = await conversationRuntimeService.prepareDraftRun(
    project,
    taskType: 'information',
    pinnedRelativePaths: _ordinaryPinnedPaths,
    expressionConstraintPolicyMode:
        runtimeOptions.expressionConstraintPolicyMode,
  );
  final useCase = _createGenerateDraftUseCase(
    bundle: bundle,
    provider: provider,
    settings: settings,
  );
  final progressPhases = <String>[];
  final result = await useCase.execute(
    project: project,
    userPrompt: _ordinaryWorkbenchPrompt,
    modelId: provider.modelId,
    title: _ordinaryWorkbenchTitle,
    sessionContext: mergeProbeSessionContext(
      ValueReaders.stringValue(
        executionConstraints['session_context_markdown'],
      ),
      preparation.sessionContextMarkdown,
    ),
    requestOptions: const <String, Object?>{'stream': false},
    contextSettings: settings.contextSettings,
    modelProfile: settings.extraSettings,
    exposedToolIds: preparation.exposedToolIds,
    expressionConstraintProfiles: ValueReaders.objectList(
      executionConstraints['expression_constraint_profiles'],
    ),
    projectExpressionConstraintBindings: ValueReaders.objectList(
      executionConstraints['project_expression_constraint_bindings'],
    ),
    onProgress: (progress) {
      progressPhases.add(progress.phase);
    },
  );
  ProjectConversationDraftRuntimeArtifacts artifacts;
  try {
    artifacts = await conversationRuntimeService.finalizeDraftRun(
      project: project,
      preparation: preparation,
      result: result,
      title: _ordinaryWorkbenchTitle,
    );
  } catch (error, stackTrace) {
    return <String, Object?>{
      'ok': false,
      'execution_entry': 'workbench_conversation_like_viewmodel_path',
      'error': '$error',
      'stack_trace': '$stackTrace',
      'progress_phases': progressPhases,
      ..._draftResultDiagnostics(result),
    };
  }
  final changedPaths = <String>{
    ...result.changedPaths,
    ...artifacts.changedPaths,
  }.toList(growable: false);
  final toolNames = result.executedTools
      .map(ValueReaders.mapValue)
      .map((tool) => ValueReaders.stringValue(tool['name']))
      .where((name) => name.trim().isNotEmpty)
      .toList(growable: false);
  final hasOrdinaryProgress =
      artifacts.outputPath.trim().isNotEmpty ||
      changedPaths.isNotEmpty ||
      toolNames.isNotEmpty ||
      result.waitingForUserChoice ||
      result.draftMarkdown.trim().isNotEmpty;
  return <String, Object?>{
    'ok': hasOrdinaryProgress,
    'execution_entry': 'workbench_conversation_like_viewmodel_path',
    'progress_phases': progressPhases,
    'output_path': artifacts.outputPath,
    'chapter_delivery': ValueReaders.deepCopyMap(artifacts.chapterDelivery),
    'information_status': artifacts.informationStatus,
    'information_summary': artifacts.informationSummary,
    'information_changed_paths': artifacts.informationChangedPaths,
    'changed_paths': changedPaths,
    'tool_names': toolNames,
    'tool_summary': _toolSummaryFromDraftResult(result),
    'execution_constraints': _executionConstraintSummary(executionConstraints),
    'expression_constraint_report': buildExpressionConstraintProbeReport(
      writingExecutionResult: artifacts.writingExecutionResult,
      chapterDelivery: artifacts.chapterDelivery,
    ),
    'draft_result_diagnostics': _draftResultDiagnostics(result),
    'draft_markdown_tail': _tailText(result.draftMarkdown, 1200),
  };
}

JsonMap _executionConstraintSummary(JsonMap executionConstraints) {
  final runtimeReport = ValueReaders.mapValue(
    executionConstraints['runtime_report'],
  );
  final expressionReport = ValueReaders.mapValue(
    runtimeReport['expression_constraints'],
  );
  final executionGate = ValueReaders.mapValue(runtimeReport['execution_gate']);
  final expressionGate = ValueReaders.mapValue(
    executionGate['expression_constraints'],
  );
  final chapterLengthMetadata = ValueReaders.mapValue(
    executionConstraints['chapter_length_metadata'],
  );
  final chapterLengthProfile = ValueReaders.mapValue(
    chapterLengthMetadata['chapter_length_profile'],
  );
  return <String, Object?>{
    'expression_profile_count': ValueReaders.objectList(
      executionConstraints['expression_constraint_profiles'],
    ).length,
    'expression_binding_count': ValueReaders.objectList(
      executionConstraints['project_expression_constraint_bindings'],
    ).length,
    'expression_active': ValueReaders.boolValue(expressionGate['active']),
    'expression_injection_mode': ValueReaders.stringValue(
      executionConstraints['expression_constraint_injection_mode'],
      ValueReaders.stringValue(expressionReport['injection_mode']),
    ),
    'expression_review_required': ValueReaders.boolValue(
      executionConstraints['expression_constraint_review_required'],
      ValueReaders.boolValue(expressionGate['review_required']),
    ),
    'chapter_length_configured': chapterLengthProfile.isNotEmpty,
    'chapter_word_target': ValueReaders.intValue(
      chapterLengthProfile['target_length'],
    ),
    'chapter_word_min': ValueReaders.intValue(
      chapterLengthProfile['preferred_min'],
    ),
    'chapter_word_max': ValueReaders.intValue(
      chapterLengthProfile['preferred_max'],
    ),
    'runtime_report': ValueReaders.deepCopyMap(runtimeReport),
  };
}

Future<JsonMap> _createLongTaskPlan({
  required AdapterBundle bundle,
  required AppSettings settings,
  required ProviderEndpointSettings provider,
  required ProjectDescriptor project,
  required _ProbeRuntimeOptions runtimeOptions,
}) async {
  final taskRepository = ProjectTaskRepository(
    workspacePort: bundle.projectWorkspacePort,
  );
  final modeRepository = ProjectModeGuidanceRepository(
    workspacePort: bundle.projectWorkspacePort,
  );
  final buildPlanInputUseCase = BuildModeGuidancePlanInputUseCase(
    statePort: modeRepository,
  );
  final workflowRuntimeService = _createWorkflowRuntimeService(
    bundle: bundle,
    taskRepository: taskRepository,
  );
  await _seedReadyState(
    repository: modeRepository,
    transitionService: ModeGuidanceTransitionService(),
    project: project,
  );
  final planInput = await buildPlanInputUseCase.execute(
    project,
    modeId: 'seed_autopilot_novel',
  );
  if (planInput == null || !planInput.isReady) {
    throw StateError('模式一计划输入未准备完成。');
  }
  final created = await workflowRuntimeService.createLongTaskWorkflow(
    project,
    planInput.runtimeMode,
    options: <String, Object?>{
      ...planInput.options,
      'checkpoint_interval': 6,
      'runtime_baseline_id': 'continuous_autonomous',
      'enable_chapter_word_constraints': true,
      'chapter_word_target': 2000,
      'chapter_word_min': 1600,
      'chapter_word_max': 2600,
      'sample_chapter_word_target': 1800,
      'sample_chapter_word_min': 1400,
      'sample_chapter_word_max': 2400,
      'max_steps': runtimeOptions.queueMaxStepsPerBatch,
      'max_seconds': 7200,
      'unattended': true,
      'auto_advance_chapters': true,
      'stop_on_waiting_user': true,
      'stop_on_user_choice': true,
      'expression_constraint_policy_mode':
          runtimeOptions.expressionConstraintPolicyMode,
    },
  );
  final tasks = await workflowRuntimeService.listWorkflowTasks(project);
  return <String, Object?>{
    'ok': true,
    'mode': planInput.runtimeMode,
    'plan_path': ValueReaders.stringValue(created['plan_path']),
    'plan_markdown_path': ValueReaders.stringValue(
      created['plan_markdown_path'],
    ),
    'initial_materialized_task_count': tasks.length,
    'initial_chapter_task_count': tasks
        .where(
          (task) => ValueReaders.stringValue(task['task_type']) == 'chapter',
        )
        .length,
    'initial_task_summaries': tasks.map(_taskSummary).toList(growable: false),
    'provider_used_for_runtime': provider.id,
    'settings_permission_mode': settings.permissionSettings,
  };
}

Future<JsonMap> _runLongTaskBatches({
  required AdapterBundle bundle,
  required AppSettings settings,
  required ProjectDescriptor project,
  required Directory runArtifactDir,
  required String repoRoot,
  required _ProbeRuntimeOptions runtimeOptions,
}) async {
  final taskRepository = ProjectTaskRepository(
    workspacePort: bundle.projectWorkspacePort,
  );
  final workflowRuntimeService = _createWorkflowRuntimeService(
    bundle: bundle,
    taskRepository: taskRepository,
  );
  var longRunPath = '';
  final batches = <JsonMap>[];
  for (
    var batchIndex = 1;
    batchIndex <= runtimeOptions.queueBatches;
    batchIndex += 1
  ) {
    final result = await workflowRuntimeService.runWorkflowTaskQueue(
      project,
      settings,
      options: <String, Object?>{
        'max_steps': runtimeOptions.queueMaxStepsPerBatch,
        'max_seconds': 7200,
        'runtime_baseline_id': 'continuous_autonomous',
        'runtime_mode': TaskRuntimeConstants.modeSeedToFullNovel,
        'unattended': true,
        'auto_advance_chapters': true,
        'stop_on_waiting_user': true,
        'stop_on_user_choice': true,
        'expression_constraint_policy_mode':
            runtimeOptions.expressionConstraintPolicyMode,
        if (longRunPath.trim().isNotEmpty)
          'continue_long_task_run_path': longRunPath,
      },
    );
    longRunPath = ValueReaders.stringValue(result['long_task_run_path']);
    final batchReport = <String, Object?>{
      'batch_index': batchIndex,
      'ok': ValueReaders.boolValue(result['ok']),
      'steps_run': ValueReaders.intValue(result['steps_run']),
      'stop_reason': ValueReaders.stringValue(result['stop_reason']),
      'stop_note': ValueReaders.stringValue(result['stop_note']),
      'task_queue_path': ValueReaders.stringValue(result['relative_path']),
      'task_queue_summary_path': ValueReaders.stringValue(
        result['summary_path'],
      ),
      'long_task_run_path': longRunPath,
      'last_result_summary': _lastResultSummary(
        ValueReaders.mapValue(result['last_result']),
        stopReason: ValueReaders.stringValue(result['stop_reason']),
        stopSummary: ValueReaders.stringValue(result['stop_note']),
      ),
      'checkpoint_action': const <String, Object?>{},
      'chapter_file_count_after_batch': await _countChapterFiles(
        bundle,
        project,
      ),
    };
    batches.add(batchReport);
    await _writeProgressSnapshot(runArtifactDir, repoRoot, <String, Object?>{
      'project_root': project.rootPath,
      'long_task_run_path': longRunPath,
      'batch_index': batchIndex,
      'chapter_file_count': batchReport['chapter_file_count_after_batch'],
      'last_batch': batchReport,
    });
    if (!ValueReaders.boolValue(result['ok'])) {
      break;
    }
    final stopReason = ValueReaders.stringValue(result['stop_reason']);
    if (_shouldAutoApplyCheckpointContinue(stopReason)) {
      final checkpointAction = await _autoApplyCheckpointContinueIfLowRisk(
        workflowRuntimeService: workflowRuntimeService,
        project: project,
        batchResult: result,
      );
      batchReport['checkpoint_action'] = checkpointAction;
      await _writeProgressSnapshot(runArtifactDir, repoRoot, <String, Object?>{
        'project_root': project.rootPath,
        'long_task_run_path': longRunPath,
        'batch_index': batchIndex,
        'chapter_file_count': batchReport['chapter_file_count_after_batch'],
        'last_batch': batchReport,
      });
      if (ValueReaders.boolValue(checkpointAction['continued'])) {
        continue;
      }
    }
    if (stopReason == 'waiting_user' ||
        stopReason == 'waiting_user_checkpoint' ||
        stopReason == 'waiting_user_choice' ||
        stopReason == 'information_waiting_user' ||
        stopReason == 'step_failed') {
      break;
    }
  }
  final tasks = await workflowRuntimeService.listWorkflowTasks(project);
  final runs = await taskRepository.listRunRecords(
    project,
    prefix: 'tracking/long_task_runs/',
    limit: 20,
  );
  return <String, Object?>{
    'ok':
        batches.isNotEmpty &&
        batches.every((batch) => ValueReaders.boolValue(batch['ok'], true)),
    'batches': batches,
    'long_task_run_path': longRunPath,
    'chapter_file_count': await _countChapterFiles(bundle, project),
    'task_status_counts': _taskStatusCounts(tasks),
    'materialized_task_count': tasks.length,
    'materialized_chapter_task_count': tasks
        .where(
          (task) => ValueReaders.stringValue(task['task_type']) == 'chapter',
        )
        .length,
    'run_records': runs
        .map(
          (record) => <String, Object?>{
            'id': ValueReaders.stringValue(record['id']),
            'relative_path': ValueReaders.stringValue(record['relative_path']),
            'status': ValueReaders.stringValue(record['status']),
            'completed_steps': ValueReaders.intValue(record['completed_steps']),
            'stop_reason': ValueReaders.stringValue(record['stop_reason']),
            'last_task_title': ValueReaders.stringValue(
              record['last_task_title'],
            ),
            'last_information_summary': ValueReaders.stringValue(
              record['last_information_summary'],
            ),
            'last_chapter_delivery_path': ValueReaders.stringValue(
              record['last_chapter_delivery_path'],
            ),
          },
        )
        .toList(growable: false),
  };
}

bool _shouldAutoApplyCheckpointContinue(String stopReason) {
  return stopReason == 'waiting_user_checkpoint' ||
      stopReason == 'waiting_user_choice';
}

Future<JsonMap> _autoApplyCheckpointContinueIfLowRisk({
  required ProjectWorkflowRuntimeService workflowRuntimeService,
  required ProjectDescriptor project,
  required JsonMap batchResult,
}) async {
  final lastResult = ValueReaders.mapValue(batchResult['last_result']);
  final checkpointReviewPath = ValueReaders.stringValue(
    ValueReaders.mapValue(lastResult['checkpoint_review'])['relative_path'],
  ).trim();
  if (checkpointReviewPath.isEmpty) {
    return const <String, Object?>{
      'ok': false,
      'continued': false,
      'error': 'checkpoint_review_path is missing',
    };
  }
  final actionPackage = await workflowRuntimeService
      .buildCheckpointReviewActionPackage(project, checkpointReviewPath);
  final actions = ValueReaders.mapList(actionPackage['actions']);
  final recommendedActionId = ValueReaders.stringValue(
    actionPackage['recommended_action_id'],
  ).trim();
  final preferredActionId = _preferredCheckpointContinueActionId(
    actions,
    recommendedActionId,
  );
  if (preferredActionId.isEmpty) {
    return <String, Object?>{
      'ok': ValueReaders.boolValue(actionPackage['ok']),
      'continued': false,
      'checkpoint_review_path': checkpointReviewPath,
      'recommended_action_id': recommendedActionId,
      'action_summary': ValueReaders.stringValue(
        actionPackage['action_summary'],
      ),
      'available_actions': actions
          .where((action) => ValueReaders.boolValue(action['enabled']))
          .map((action) => ValueReaders.stringValue(action['id']))
          .toList(growable: false),
    };
  }
  final applied = await workflowRuntimeService.applyCheckpointReviewAction(
    project,
    checkpointReviewPath,
    preferredActionId,
  );
  return <String, Object?>{
    'ok': ValueReaders.boolValue(applied['ok']),
    'continued': ValueReaders.boolValue(applied['ok']),
    'checkpoint_review_path': checkpointReviewPath,
    'applied_action_id': preferredActionId,
    'recommended_action_id': recommendedActionId,
    'action_summary': ValueReaders.stringValue(actionPackage['action_summary']),
    'changed_paths': ValueReaders.stringList(applied['changed_paths']),
    'task_status': ValueReaders.stringValue(
      ValueReaders.mapValue(applied['task'])['status'],
    ),
    'error': ValueReaders.stringValue(applied['error']),
  };
}

String _preferredCheckpointContinueActionId(
  List<JsonMap> actions,
  String recommendedActionId,
) {
  final enabledIds = actions
      .where((action) => ValueReaders.boolValue(action['enabled']))
      .map((action) => ValueReaders.stringValue(action['id']).trim())
      .where((id) => id.isNotEmpty)
      .toSet();
  const continueIds = <String>{
    'continue_long_task',
    'confirm_checkpoint_continue',
  };
  if (continueIds.contains(recommendedActionId) &&
      enabledIds.contains(recommendedActionId)) {
    return recommendedActionId;
  }
  for (final id in continueIds) {
    if (enabledIds.contains(id)) {
      return id;
    }
  }
  return '';
}

ProjectWorkflowRuntimeService _createWorkflowRuntimeService({
  required AdapterBundle bundle,
  required ProjectTaskRepository taskRepository,
}) {
  return ProjectWorkflowRuntimeService(
    taskRepository: taskRepository,
    promptTemplateService: ProjectPromptTemplateService(
      workspacePort: bundle.projectWorkspacePort,
    ),
    hostAwareGenerateDraftUseCaseFactory:
        (
          provider,
          networkSettings, {
          hostInformationPermissionContext,
          hostToolPermissionContext,
        }) {
          final basePort = bundle.projectToolExecutionPort;
          final scopedToolExecutionPort = basePort is ProjectToolDispatcher
              ? basePort.scopedWithHostPermissionContexts(
                  hostInformationPermissionContext:
                      hostInformationPermissionContext,
                  hostToolPermissionContext: hostToolPermissionContext,
                )
              : basePort;
          return GenerateDraftUseCase(
            projectWorkspacePort: bundle.projectWorkspacePort,
            llmGateway: bundle.createGateway(
              provider,
              networkSettings: networkSettings,
            ),
            toolExecutionPort: scopedToolExecutionPort,
            contextAssemblerService: ContextAssemblerService(
              budgetService: ContextBudgetService(),
              staticSectionService: ContextStaticSectionService(
                projectPromptContract: ProjectPromptContract(),
              ),
              projectFileSectionService: ContextProjectFileSectionService(),
            ),
            projectPromptContract: ProjectPromptContract(),
            hostToolPermissionContext: hostToolPermissionContext,
            hostPlatform: _currentHostPlatform(),
            loadAvailableAgents: (project) =>
                bundle.agentPackageCatalog.loadAgentPackages(project),
            loadAvailableAgentGroups: (project) =>
                bundle.agentGroupCatalog.loadAgentGroups(project),
          );
        },
    generateDraftUseCaseFactory: (provider, networkSettings) {
      return GenerateDraftUseCase(
        projectWorkspacePort: bundle.projectWorkspacePort,
        llmGateway: bundle.createGateway(
          provider,
          networkSettings: networkSettings,
        ),
        toolExecutionPort: bundle.projectToolExecutionPort,
        contextAssemblerService: ContextAssemblerService(
          budgetService: ContextBudgetService(),
          staticSectionService: ContextStaticSectionService(
            projectPromptContract: ProjectPromptContract(),
          ),
          projectFileSectionService: ContextProjectFileSectionService(),
        ),
        projectPromptContract: ProjectPromptContract(),
        hostPlatform: _currentHostPlatform(),
        loadAvailableAgents: (project) =>
            bundle.agentPackageCatalog.loadAgentPackages(project),
        loadAvailableAgentGroups: (project) =>
            bundle.agentGroupCatalog.loadAgentGroups(project),
      );
    },
  );
}

GenerateDraftUseCase _createGenerateDraftUseCase({
  required AdapterBundle bundle,
  required ProviderEndpointSettings provider,
  required AppSettings settings,
}) {
  final hostContext =
      const ProjectInformationPermissionSettingsResolverService()
          .resolveFromAppSettings(
            settings,
            source: 'gui_viewmodel_probe.ordinary_workbench_step',
          );
  final hostToolContext = const ProjectToolPermissionSettingsResolverService()
      .resolveFromAppSettings(
        settings,
        source: 'gui_viewmodel_probe.ordinary_workbench_step',
      );
  final basePort = bundle.projectToolExecutionPort;
  final scopedToolPort = basePort is ProjectToolDispatcher
      ? basePort.scopedWithHostPermissionContexts(
          hostInformationPermissionContext: hostContext,
          hostToolPermissionContext: hostToolContext,
        )
      : basePort;
  return GenerateDraftUseCase(
    projectWorkspacePort: bundle.projectWorkspacePort,
    llmGateway: bundle.createGateway(
      provider,
      networkSettings: settings.networkSettings,
    ),
    toolExecutionPort: scopedToolPort,
    contextAssemblerService: ContextAssemblerService(
      budgetService: ContextBudgetService(),
      staticSectionService: ContextStaticSectionService(
        projectPromptContract: ProjectPromptContract(),
      ),
      projectFileSectionService: ContextProjectFileSectionService(),
    ),
    projectPromptContract: ProjectPromptContract(),
    hostToolPermissionContext: hostToolContext,
    hostPlatform: _currentHostPlatform(),
    loadAvailableAgents: (project) =>
        bundle.agentPackageCatalog.loadAgentPackages(project),
    loadAvailableAgentGroups: (project) =>
        bundle.agentGroupCatalog.loadAgentGroups(project),
  );
}

Future<JsonMap> _buildGuiViewModelReport({
  required AdapterBundle bundle,
  required ProjectDescriptor project,
}) async {
  final workspaceEntries = await bundle.projectWorkspacePort.listEntries(
    project.rootPath,
  );
  final fileContents = await _readInformationViewModelFiles(
    bundle.projectWorkspacePort,
    project,
    workspaceEntries,
  );
  final projectFileCounts = await _countProjectFileEvidence(
    project: project,
    workspaceEntries: workspaceEntries,
  );
  final informationViewData = const WorkspaceInformationProjectionService()
      .build(workspaceEntries: workspaceEntries, fileContents: fileContents);
  final longTaskRuns = await _runInstancesForProject(bundle, project);
  final selectedRun = longTaskRuns.isEmpty ? null : longTaskRuns.first;
  ProjectLongTaskStationDetail? detail;
  if (selectedRun != null) {
    final taskRepository = ProjectTaskRepository(
      workspacePort: bundle.projectWorkspacePort,
    );
    detail = await ProjectLongTaskStationDetailService(
      taskRepository: taskRepository,
      reviewReportService: ProjectReviewReportService(
        workspacePort: bundle.projectWorkspacePort,
        taskRepository: taskRepository,
      ),
    ).loadForRun(selectedRun);
  }
  final stationViewData = const LongTaskStationViewDataService().build(
    LongTaskStationSnapshot(
      runs: longTaskRuns,
      selectedRunId: selectedRun?.id ?? '',
      selectedRunDetail: detail,
      currentProjectPath: project.rootPath,
      isCurrentProjectFilterActive: true,
      detailStatusMessage: detail == null ? '未加载运行详情。' : '已加载项目链路详情。',
      statusMessage: longTaskRuns.isEmpty
          ? '当前项目暂无运行实例。'
          : '当前项目共有 ${longTaskRuns.length} 个运行实例。',
      isLoading: false,
      isDetailLoading: false,
      isSupervisorRunning: bundle.longTaskSupervisor.isRunning,
    ),
  );
  return <String, Object?>{
    'workbench_information_viewmodel': <String, Object?>{
      'title': informationViewData.title,
      'summary': informationViewData.summary,
      'usage_summary': informationViewData.usageSummary,
      'has_content': informationViewData.hasContent,
      'entries': informationViewData.entries
          .map(_workbenchInformationEntry)
          .toList(growable: false),
      'pending_entries': informationViewData.pendingEntries
          .map(_workbenchInformationEntry)
          .toList(growable: false),
    },
    'long_task_station_viewmodel': <String, Object?>{
      'title': stationViewData.title,
      'scope_label': stationViewData.scopeLabel,
      'status_message': stationViewData.statusMessage,
      'supervisor_status_label': stationViewData.supervisorStatusLabel,
      'total_count': stationViewData.totalCount,
      'active_count': stationViewData.activeCount,
      'attention_count': stationViewData.attentionCount,
      'runs': stationViewData.runs
          .map(
            (run) => <String, Object?>{
              'id': run.id,
              'title': run.title,
              'subtitle': run.subtitle,
              'status_label': run.statusLabel,
              'task_label': run.taskLabel,
              'badges': run.badges,
              'requires_attention': run.requiresAttention,
              'is_active': run.isActive,
              'is_selected': run.isSelected,
            },
          )
          .toList(growable: false),
      'selected_run': _stationSelectedRun(stationViewData.selectedRun),
    },
    'project_file_counts': projectFileCounts,
    'project_files': workspaceEntries
        .map((entry) => _relativePath(entry['relative_path']))
        .where((path) => path.trim().isNotEmpty)
        .toList(growable: false),
  };
}

Future<List<RunInstance>> _runInstancesForProject(
  AdapterBundle bundle,
  ProjectDescriptor project,
) async {
  final taskRepository = ProjectTaskRepository(
    workspacePort: bundle.projectWorkspacePort,
  );
  final runRecords = await taskRepository.listRunRecords(
    project,
    prefix: 'tracking/long_task_runs/',
    limit: 20,
  );
  final result = <RunInstance>[];
  for (final record in runRecords) {
    final runId = ValueReaders.stringValue(record['id']);
    if (runId.trim().isEmpty) {
      continue;
    }
    final status = _runStatusFromRecord(record);
    final createdAt = _dateTimeFromRecord(
      ValueReaders.stringValue(record['created_at']),
    );
    final updatedAt = _dateTimeFromRecord(
      ValueReaders.stringValue(record['updated_at']),
      fallback: createdAt,
    );
    result.add(
      RunInstance(
        id: runId,
        project: RunProjectReference.fromProject(project),
        runtimeBaselineId: ValueReaders.stringValue(
          record['runtime_baseline_id'],
          'continuous_autonomous',
        ),
        modeId: ValueReaders.stringValue(
          record['mode'],
          TaskRuntimeConstants.modeSeedToFullNovel,
        ),
        workflowStrategyId: ValueReaders.stringValue(record['strategy']),
        status: status,
        createdAt: createdAt,
        updatedAt: updatedAt,
        lastHeartbeatAt: updatedAt,
        startedAt: createdAt,
        activeTaskId: ValueReaders.stringValue(record['last_task_id']),
        activeTaskTitle: ValueReaders.stringValue(record['last_task_title']),
        note: ValueReaders.stringValue(record['stop_note']),
        stopReason: ValueReaders.stringValue(record['stop_reason']),
        metadata: <String, Object?>{
          'source': 'gui_viewmodel_probe.project_run_record',
          'relative_path': ValueReaders.stringValue(record['relative_path']),
        },
      ),
    );
  }
  return result;
}

LongTaskRunStatus _runStatusFromRecord(JsonMap record) {
  final status = ValueReaders.stringValue(record['status']);
  final stopReason = ValueReaders.stringValue(record['stop_reason']);
  if (status == TaskRuntimeConstants.statusRunning) {
    return LongTaskRunStatus.running;
  }
  if (status == TaskRuntimeConstants.statusPaused) {
    if (stopReason.contains('waiting') || stopReason.contains('checkpoint')) {
      return LongTaskRunStatus.waitingGate;
    }
    return LongTaskRunStatus.paused;
  }
  if (status == TaskRuntimeConstants.statusFailed) {
    return LongTaskRunStatus.failedManualAttention;
  }
  if (status == TaskRuntimeConstants.statusSucceeded) {
    return LongTaskRunStatus.stopped;
  }
  return LongTaskRunStatus.fromId(status);
}

DateTime _dateTimeFromRecord(String raw, {DateTime? fallback}) {
  return DateTime.tryParse(raw) ?? fallback ?? DateTime.now();
}

Future<Map<String, String>> _readInformationViewModelFiles(
  ProjectWorkspacePort workspacePort,
  ProjectDescriptor project,
  List<JsonMap> entries,
) async {
  final result = <String, String>{};
  for (final entry in entries) {
    final path = ValueReaders.stringValue(
      entry['relative_path'],
    ).replaceAll('\\', '/');
    if (!_shouldReadForInformationViewModel(path)) {
      continue;
    }
    final content = await workspacePort.readTextFile(project.rootPath, path);
    if (content != null) {
      result[path] = content;
    }
  }
  return result;
}

bool _shouldReadForInformationViewModel(String path) {
  if (path == InformationProjectionDocument.knowledgeSummaryRelativePath ||
      path == InformationProjectionDocument.designSummaryRelativePath ||
      path == InformationProjectionDocument.researchSummaryRelativePath ||
      path == InformationProjectionDocument.referenceBoundaryRelativePath) {
    return true;
  }
  if (path.endsWith('activation_report.json')) {
    return true;
  }
  return path.startsWith('.novel_agent/information/knowledge_cards/') ||
      path.startsWith('.novel_agent/information/design_elements/') ||
      path.startsWith('.novel_agent/information/research_requests/') ||
      path.startsWith('.novel_agent/information/reference_works/');
}

JsonMap _validateReport(JsonMap report) {
  final ordinary = ValueReaders.mapValue(report['ordinary_workbench_step']);
  final batches = ValueReaders.mapValue(report['long_task_batches']);
  final viewmodel = ValueReaders.mapValue(report['gui_viewmodel']);
  final workbenchVm = ValueReaders.mapValue(
    viewmodel['workbench_information_viewmodel'],
  );
  final stationVm = ValueReaders.mapValue(
    viewmodel['long_task_station_viewmodel'],
  );
  final fileCounts = ValueReaders.mapValue(viewmodel['project_file_counts']);
  final failureReasons = <String>[];
  if (!ValueReaders.boolValue(ordinary['ok'])) {
    failureReasons.add('普通工作台会话没有形成有效推进。');
  }
  if (!ValueReaders.boolValue(batches['ok'])) {
    failureReasons.add('长任务批次运行失败。');
  }
  if (ValueReaders.intValue(fileCounts['chapter_files']) < 1) {
    failureReasons.add('项目内没有可读章节正文。');
  }
  if (ValueReaders.intValue(fileCounts['research_notes']) < 1 &&
      ValueReaders.intValue(fileCounts['research_requests']) < 1 &&
      !ValueReaders.boolValue(workbenchVm['has_content'])) {
    failureReasons.add('资料收集没有形成 request/note/viewmodel 可见摘要。');
  }
  if (ValueReaders.intValue(stationVm['total_count']) < 1) {
    failureReasons.add('长任务总站 viewmodel 没有读到运行实例。');
  }
  _appendExpressionConstraintProbeFailures(
    failureReasons,
    label: '普通工作台会话',
    report: ValueReaders.mapValue(ordinary['expression_constraint_report']),
  );
  for (final batch in ValueReaders.mapList(batches['batches'])) {
    _appendExpressionConstraintProbeFailures(
      failureReasons,
      label: '长任务 Batch ${ValueReaders.intValue(batch['batch_index'])}',
      report: ValueReaders.mapValue(
        ValueReaders.mapValue(
          ValueReaders.mapValue(batch)['last_result_summary'],
        )['expression_constraint_report'],
      ),
    );
  }
  final ok = failureReasons.isEmpty;
  return <String, Object?>{
    'ok': ok,
    'report_category': ok
        ? ProbeReportCategories.success
        : ProbeReportCategories.contentQualityFailure,
    'failure_reasons': failureReasons,
    'summary': ok
        ? 'GUI/viewmodel 资料摘要、章节产物与长任务运行状态均可见。'
        : failureReasons.join('；'),
  };
}

void _appendExpressionConstraintProbeFailures(
  List<String> failureReasons, {
  required String label,
  required JsonMap report,
}) {
  if (!ValueReaders.boolValue(report['present'])) {
    return;
  }
  final disposition = ValueReaders.stringValue(report['disposition']);
  final gateSeverity = ValueReaders.stringValue(report['gate_severity']);
  final riskSignals = ValueReaders.stringList(report['risk_signals']);
  if (disposition != ExpressionConstraintGateRecommendedDispositions.repair &&
      gateSeverity != ExpressionConstraintGateSeverities.blocking) {
    return;
  }
  final summary = ValueReaders.stringValue(
    report['gate_summary'],
    ValueReaders.stringValue(report['summary']),
  );
  final riskText = riskSignals.isEmpty
      ? ''
      : ' 风险：${riskSignals.take(3).join('；')}';
  failureReasons.add(
    '$label 表达限制仍有未收口风险：${summary.trim().isEmpty ? disposition : summary}.$riskText',
  );
}

Future<void> _seedHistoricalTransmigrationProject(
  ProjectWorkspacePort workspacePort,
  ProjectDescriptor project,
) async {
  await workspacePort.writeTextFile(
    project.rootPath,
    'specs/project_spec.md',
    [
      '# 项目规格',
      '',
      '- 类型：轻松向历史穿越种田/经营长篇。',
      '- 朝代选择：明代后期，万历年间江南市镇附近。',
      '- 主角：现代社畜周砚，过劳后穿越成地方士绅家的纨绔/游手好闲少爷周延璋。',
      '- 核心看点：他用现代基础科学、管理经验和工程常识，一点点改善家业、作坊、农田、水利、卫生和地方生计。',
      '- 节奏要求：轻松、有生活气，不要开局暴富，不要三章平推朝局；先从小规模验证和身边矛盾开始。',
      '- 信息纪律：涉及明代制度、科举、赋税、里甲/保甲、县衙、工艺、农具、水利、肥皂/玻璃/酒精/糖等真实背景时，先通过 request_external_research 或研究笔记形成依据，再沉淀进正文或设定；不能假装已经查过。',
      '- 通用性要求：不要把“明代”“穿越”“科学发展”写进程序逻辑；这些只是本项目输入。',
      '',
    ].join('\n'),
  );
  await workspacePort.writeTextFile(
    project.rootPath,
    'styles/轻松历史经营风格.md',
    [
      '# 轻松历史经营风格',
      '',
      '- 口吻轻松但不浮滑，主角可以吐槽，但不要像现代短视频文案。',
      '- 发展节奏要有试错、成本、地方人情和技术限制。',
      '- 技术知识要尽量落到可操作的小步骤，不要一句“现代科学”解决所有问题。',
      '- 少用解释腔，多用场景、动作、对话展示信息。',
      '',
    ].join('\n'),
  );
  await workspacePort.writeTextFile(
    project.rootPath,
    'outlines/story/创作起点.md',
    [
      '# 创作起点',
      '',
      '周砚醒来后发现自己成了周延璋，一个刚因斗鸡赌气摔进池塘的纨绔少爷。',
      '周家在江南市镇有田、有小作坊，却现金流紧张、家仆怨气重、族中长辈准备趁机夺权。',
      '周砚不急着改变时代，而是先弄清楚自己身处的制度、人情与技术条件，再从卫生、账目、作坊流程和农田灌溉这些小事入手。',
      '',
    ].join('\n'),
  );
  await workspacePort.writeTextFile(
    project.rootPath,
    'assets/characters/周砚_周延璋.md',
    [
      '# 周砚 / 周延璋',
      '',
      '- 前世：现代公司社畜，懂项目管理、基础理工常识和一点商业流程。',
      '- 今生身份：地方士绅家的闲散少爷，名声不好但资源并非为零。',
      '- 初始弱点：不懂明代规矩，身体原主留下不少烂账，人情信用很差。',
      '- 目标：先活稳，再把家业和身边人的生活一点点扶起来。',
      '',
    ].join('\n'),
  );
  await workspacePort.writeTextFile(
    project.rootPath,
    'assets/world/明代后期江南市镇.md',
    [
      '# 明代后期江南市镇',
      '',
      '- 本文件只记录已在正文或研究中确认过的世界信息。',
      '- 尚未核查的制度、工艺、地名、计量单位，不要直接当成定论。',
      '',
    ].join('\n'),
  );
  await workspacePort.writeTextFile(
    project.rootPath,
    'research/research_questions.md',
    [
      '# Research Questions',
      '',
      '- How should the relations among county yamen, gentry, clans, and workshops in late Ming Jiangnan be presented?',
      '- How can soap, soapberry, wood ash, and alkaline lye be handled without turning the prose into hard exposition?',
      '- What details around water wheels, pedal pumps, irrigation ditches, and small workshop improvements are worth writing?',
      '- Which of sugar, alcohol, glass, papermaking, or dyeing are suitable as early-stage goals?',
      '',
    ].join('\n'),
  );
}

Future<void> _seedReadyState({
  required ProjectModeGuidanceRepository repository,
  required ModeGuidanceTransitionService transitionService,
  required ProjectDescriptor project,
}) async {
  var state = transitionService.initialize('seed_autopilot_novel');
  for (final item in const <Map<String, String>>[
    <String, String>{
      'stage': 'seed_scope',
      'field': 'seed_scope',
      'value':
          '轻松向历史穿越经营长篇。现代社畜周砚穿越到明代后期江南士绅家的纨绔少爷周延璋身上，从小规模卫生、账目、作坊和水利改良开始，逐步用现代科学常识发展家业与地方生计。',
      'label': '已有种子',
    },
    <String, String>{
      'stage': 'core_promise',
      'field': 'core_promise',
      'value': '轻松生活感、真实历史约束、科学知识小步验证、家业经营成长；不走开局暴富和三章平推朝局。',
      'label': '核心承诺',
    },
    <String, String>{
      'stage': 'world_anchor',
      'field': 'world_anchor',
      'value': '时代背景为明代后期万历年间江南市镇；涉及制度、工艺、科学史与生产细节时必须先形成资料研究或明确缺口，不能凭空断言。',
      'label': '世界锚点',
    },
    <String, String>{
      'stage': 'protagonist_drive',
      'field': 'protagonist_drive',
      'value': '周砚要先在陌生时代活稳，修复原主留下的坏名声，再用可验证的小技术和现代组织经验改善身边人的生活。',
      'label': '主角驱动',
    },
    <String, String>{
      'stage': 'style_target',
      'field': 'style_target',
      'value': '中文商业网文式轻松历史经营风格，有吐槽但不过度现代段子化；少解释腔，多场景、动作、对话和试错。',
      'label': '风格目标',
    },
    <String, String>{
      'stage': 'autonomy_guardrails',
      'field': 'autonomy_guardrails',
      'value':
          '以200章以内作为预算上限自然发展，不人为固定每段章节数；每轮先规划、样章、再分批推进，遇到资料缺口、检查点或失败应停下并记录。',
      'label': '托管边界',
    },
    <String, String>{
      'stage': 'review_ready',
      'field': 'review_ready',
      'value': '已确认以上信息，可以启动长任务。',
      'label': '确认启动',
    },
  ]) {
    state = transitionService.answer(
      state,
      stageId: item['stage']!,
      fieldKey: item['field']!,
      value: item['value']!,
      label: item['label']!,
      source: 'option',
    );
  }
  await repository.save(project, state);
}

JsonMap _taskSummary(JsonMap task) {
  final metadata = ValueReaders.mapValue(task['metadata']);
  return <String, Object?>{
    'id': ValueReaders.stringValue(task['id']),
    'title': ValueReaders.stringValue(task['title']),
    'task_type': ValueReaders.stringValue(task['task_type']),
    'chapter': ValueReaders.stringValue(task['chapter']),
    'stage': ValueReaders.stringValue(metadata['stage']),
    'status': ValueReaders.stringValue(task['status']),
    'relative_path': ValueReaders.stringValue(task['relative_path']),
    'output_paths': ValueReaders.stringList(task['output_paths']),
  };
}

JsonMap _lastResultSummary(
  JsonMap result, {
  String stopReason = '',
  String stopSummary = '',
}) {
  return <String, Object?>{
    'ok': ValueReaders.boolValue(result['ok']),
    'output_paths': ValueReaders.stringList(result['output_paths']),
    'changed_paths': ValueReaders.stringList(result['changed_paths']),
    'checkpoint_review_path': ValueReaders.stringValue(
      ValueReaders.mapValue(result['checkpoint_review'])['relative_path'],
    ),
    'chapter_delivery_path': ValueReaders.stringValue(
      result['chapter_delivery_path'],
    ),
    'chapter_delivery_state': ValueReaders.stringValue(
      result['chapter_delivery_state'],
    ),
    'tool_names': _toolNamesFromWorkflowResult(result),
    'expression_constraint_report': buildExpressionConstraintProbeReport(
      writingExecutionResult: ValueReaders.mapValue(
        result['writing_execution_result'],
      ),
      chapterDelivery: ValueReaders.mapValue(result['chapter_delivery']),
      stopReason: stopReason,
      stopSummary: stopSummary,
    ),
    'error': ValueReaders.stringValue(result['error']),
  };
}

List<String> _toolNamesFromWorkflowResult(JsonMap result) {
  final explicit = ValueReaders.stringList(result['tool_names']);
  if (explicit.isNotEmpty) {
    return explicit;
  }
  return ValueReaders.objectList(result['executed_tools'])
      .map(ValueReaders.mapValue)
      .map((tool) => ValueReaders.stringValue(tool['name']))
      .where((name) => name.trim().isNotEmpty)
      .toList(growable: false);
}

JsonMap _toolSummaryFromDraftResult(DraftGenerationResult result) {
  final toolNameCounts = <String, int>{};
  for (final rawTool in result.executedTools) {
    final name = ValueReaders.stringValue(
      ValueReaders.mapValue(rawTool)['name'],
    );
    if (name.trim().isEmpty) {
      continue;
    }
    toolNameCounts[name] = (toolNameCounts[name] ?? 0) + 1;
  }
  return <String, Object?>{'tool_name_counts': toolNameCounts};
}

JsonMap _draftResultDiagnostics(DraftGenerationResult result) {
  final toolNames = result.executedTools
      .map(ValueReaders.mapValue)
      .map((tool) => ValueReaders.stringValue(tool['name']))
      .where((name) => name.trim().isNotEmpty)
      .toList(growable: false);
  return <String, Object?>{
    'tool_names': toolNames,
    'tool_summary': _toolSummaryFromDraftResult(result),
    'written_paths': result.writtenPaths,
    'changed_paths': result.changedPaths,
    'selected_paths': result.selectedPaths,
    'waiting_for_user_choice': result.waitingForUserChoice,
    'stopped_by_tool_error': result.stoppedByToolError,
    'tool_error_summary': result.toolErrorSummary,
    'draft_markdown_length': result.draftMarkdown.length,
    'draft_markdown_tail': _tailText(result.draftMarkdown, 1600),
    'reasoning_tail': _tailText(result.reasoningContent, 1600),
    'executed_tools_tail': result.executedTools
        .map(ValueReaders.mapValue)
        .map(_executedToolDiagnostic)
        .toList(growable: false),
    'transcript_tail': result.transcriptMessages
        .skip(
          result.transcriptMessages.length > 10
              ? result.transcriptMessages.length - 10
              : 0,
        )
        .map(_transcriptMessageDiagnostic)
        .toList(growable: false),
  };
}

JsonMap _executedToolDiagnostic(JsonMap tool) {
  final arguments = ValueReaders.mapValue(tool['arguments']);
  final result = ValueReaders.mapValue(tool['result']);
  return <String, Object?>{
    'id': ValueReaders.stringValue(tool['id']),
    'name': ValueReaders.stringValue(tool['name']),
    'ok': ValueReaders.boolValue(tool['ok'], true),
    'not_executed': ValueReaders.boolValue(tool['not_executed']),
    'argument_keys': arguments.keys.toList(growable: false),
    'argument_summary': _toolArgumentSummary(arguments),
    'result_keys': result.keys.toList(growable: false),
    'result_summary': _toolResultSummary(result),
  };
}

JsonMap _toolArgumentSummary(JsonMap arguments) {
  return <String, Object?>{
    'relative_path': ValueReaders.stringValue(arguments['relative_path']),
    'chapter_path': ValueReaders.stringValue(arguments['chapter_path']),
    'title': ValueReaders.stringValue(arguments['title']),
    'query': ValueReaders.stringValue(arguments['query']),
    'purpose': ValueReaders.stringValue(arguments['purpose']),
    'content_length': ValueReaders.stringValue(arguments['content']).length,
    'chapter_content_length': ValueReaders.stringValue(
      arguments['chapter_content'],
    ).length,
    'content_tail': _tailText(
      ValueReaders.stringValue(arguments['content']),
      400,
    ),
    'chapter_content_tail': _tailText(
      ValueReaders.stringValue(arguments['chapter_content']),
      400,
    ),
  };
}

JsonMap _toolResultSummary(JsonMap result) {
  final domainOutcome = ValueReaders.mapValue(result['domain_outcome']);
  final outcomePayload = ValueReaders.mapValue(
    domainOutcome['outcome_payload'],
  );
  return <String, Object?>{
    'ok': ValueReaders.boolValue(result['ok'], true),
    'relative_path': ValueReaders.stringValue(result['relative_path']),
    'changed_paths': ValueReaders.stringList(result['changed_paths']),
    'error': ValueReaders.stringValue(result['error']),
    'tool_result_summary': ValueReaders.stringValue(
      result['tool_result_summary'],
    ),
    'domain_outcome_status': ValueReaders.stringValue(
      result['domain_outcome_status'],
      ValueReaders.stringValue(domainOutcome['outcome_status']),
    ),
    'delivery_id': ValueReaders.stringValue(outcomePayload['delivery_id']),
    'chapter_path': ValueReaders.stringValue(outcomePayload['chapter_path']),
  };
}

JsonMap _transcriptMessageDiagnostic(JsonMap message) {
  final toolCalls = ValueReaders.objectList(message['tool_calls'])
      .map(ValueReaders.mapValue)
      .map((call) {
        final function = ValueReaders.mapValue(call['function']);
        return <String, Object?>{
          'id': ValueReaders.stringValue(call['id']),
          'name': ValueReaders.stringValue(
            function['name'],
            ValueReaders.stringValue(call['name']),
          ),
        };
      })
      .toList(growable: false);
  return <String, Object?>{
    'role': ValueReaders.stringValue(message['role']),
    'name': ValueReaders.stringValue(message['name']),
    'tool_call_id': ValueReaders.stringValue(message['tool_call_id']),
    'content_tail': _tailText(
      ValueReaders.stringValue(message['content']),
      1200,
    ),
    'tool_calls': toolCalls,
  };
}

Map<String, Object?> _taskStatusCounts(List<JsonMap> tasks) {
  final counts = <String, int>{};
  for (final task in tasks) {
    final status = ValueReaders.stringValue(task['status'], 'unknown');
    counts[status] = (counts[status] ?? 0) + 1;
  }
  return counts;
}

Future<int> _countChapterFiles(
  AdapterBundle bundle,
  ProjectDescriptor project,
) async {
  final entries = await bundle.projectWorkspacePort.listEntries(
    project.rootPath,
  );
  return entries
      .map((entry) => _relativePath(entry['relative_path']))
      .where((path) => path.startsWith('chapters/') && path.endsWith('.md'))
      .length;
}

Future<JsonMap> _countProjectFileEvidence({
  required ProjectDescriptor project,
  required List<JsonMap> workspaceEntries,
}) async {
  final visiblePaths = workspaceEntries
      .map((entry) => _relativePath(entry['relative_path']))
      .where((path) => path.trim().isNotEmpty)
      .toList(growable: false);
  return <String, Object?>{
    'chapter_files': visiblePaths
        .where((path) => path.startsWith('chapters/') && path.endsWith('.md'))
        .length,
    'research_notes': await _countFilesUnderProject(
      project.rootPath,
      '.novel_agent/information/research_notes',
    ),
    'research_requests': await _countFilesUnderProject(
      project.rootPath,
      '.novel_agent/information/research_requests',
    ),
  };
}

Future<int> _countFilesUnderProject(
  String projectRootPath,
  String relativeDirectoryPath,
) async {
  final directory = Directory(
    [
      projectRootPath,
      ...relativeDirectoryPath.split('/'),
    ].join(Platform.pathSeparator),
  );
  if (!await directory.exists()) {
    return 0;
  }
  var count = 0;
  await for (final entity in directory.list(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is File) {
      count += 1;
    }
  }
  return count;
}

String _relativePath(Object? raw) {
  return ValueReaders.stringValue(raw).replaceAll('\\', '/');
}

JsonMap _workbenchInformationEntry(dynamic entry) {
  return <String, Object?>{
    'id': entry.id,
    'title': entry.title,
    'subtitle': entry.subtitle,
    'summary': entry.summary,
    'status_label': entry.statusLabel,
    'usage_label': entry.usageLabel,
    'risk_label': entry.riskLabel,
    'action_label': entry.actionLabel,
    'relative_path': entry.relativePath,
    'pending_research_request_id': entry.pendingResearchRequestId,
    'supports_pending_research_actions': entry.supportsPendingResearchActions,
  };
}

JsonMap _stationSelectedRun(dynamic selectedRun) {
  if (selectedRun == null) {
    return const <String, Object?>{};
  }
  return <String, Object?>{
    'id': selectedRun.id,
    'project_title': selectedRun.projectTitle,
    'status_label': selectedRun.statusLabel,
    'active_task_label': selectedRun.activeTaskLabel,
    'active_task_path': selectedRun.activeTaskPath,
    'blocker_label': selectedRun.blockerLabel,
    'blocker_note': selectedRun.blockerNote,
    'task_chain_title': selectedRun.taskChainTitle,
    'task_chain_subtitle': selectedRun.taskChainSubtitle,
    'task_chain_count': selectedRun.taskChainItems.length,
    'information_summary': selectedRun.informationSummary == null
        ? const <String, Object?>{}
        : <String, Object?>{
            'title': selectedRun.informationSummary!.title,
            'subtitle': selectedRun.informationSummary!.subtitle,
            'summary': selectedRun.informationSummary!.summary,
            'relative_path': selectedRun.informationSummary!.relativePath,
          },
    'information_projection_items': selectedRun.informationProjectionItems
        .map(
          (item) => <String, Object?>{
            'title': item.title,
            'subtitle': item.subtitle,
            'summary': item.summary,
            'relative_path': item.relativePath,
            'action_label': item.actionLabel,
          },
        )
        .toList(growable: false),
    'information_permission_items': selectedRun.informationPermissionItems
        .map(
          (item) => <String, Object?>{
            'title': item.title,
            'subtitle': item.subtitle,
            'summary': item.summary,
            'relative_path': item.relativePath,
            'action_label': item.actionLabel,
            'pending_research_request_id': item.pendingResearchRequestId,
          },
        )
        .toList(growable: false),
    'preferred_recent_output': selectedRun.preferredRecentOutput == null
        ? const <String, Object?>{}
        : <String, Object?>{
            'title': selectedRun.preferredRecentOutput!.title,
            'summary': selectedRun.preferredRecentOutput!.summary,
            'relative_path': selectedRun.preferredRecentOutput!.relativePath,
          },
    'stop_diagnosis': selectedRun.stopDiagnosis == null
        ? const <String, Object?>{}
        : <String, Object?>{
            'code': selectedRun.stopDiagnosis!.code,
            'category': selectedRun.stopDiagnosis!.category,
            'label': selectedRun.stopDiagnosis!.label,
            'summary': selectedRun.stopDiagnosis!.summary,
            'detail': selectedRun.stopDiagnosis!.detail,
          },
    'expression_constraint_status':
        selectedRun.expressionConstraintStatus == null
        ? const <String, Object?>{}
        : <String, Object?>{
            'category': selectedRun.expressionConstraintStatus!.category,
            'label': selectedRun.expressionConstraintStatus!.label,
            'summary': selectedRun.expressionConstraintStatus!.summary,
            'blocks_repair':
                selectedRun.expressionConstraintStatus!.blocksRepair,
            'suggests_strengthen':
                selectedRun.expressionConstraintStatus!.suggestsStrengthen,
            'is_disabled': selectedRun.expressionConstraintStatus!.isDisabled,
          },
  };
}

Future<void> _writeProgressSnapshot(
  Directory runArtifactDir,
  String repoRoot,
  JsonMap snapshot,
) async {
  final text = const JsonEncoder.withIndent('  ').convert(snapshot);
  final runFile = File(
    '${runArtifactDir.path}${Platform.pathSeparator}progress.json',
  );
  final latestFile = File(
    '$repoRoot${Platform.pathSeparator}artifacts${Platform.pathSeparator}'
    'real_gui_viewmodel_information_long_task_probe_progress.json',
  );
  await runFile.writeAsString(text);
  await latestFile.parent.create(recursive: true);
  await latestFile.writeAsString(text);
}

Future<void> _writeReports(
  String repoRoot,
  Directory runArtifactDir,
  JsonMap report,
) async {
  final latestJsonFile = File(
    '$repoRoot${Platform.pathSeparator}artifacts${Platform.pathSeparator}'
    'real_gui_viewmodel_information_long_task_probe_report.json',
  );
  final runJsonFile = File(
    '${runArtifactDir.path}${Platform.pathSeparator}report.json',
  );
  final latestMarkdownFile = File(
    '$repoRoot${Platform.pathSeparator}artifacts${Platform.pathSeparator}'
    'real_gui_viewmodel_information_long_task_probe_report.md',
  );
  final runMarkdownFile = File(
    '${runArtifactDir.path}${Platform.pathSeparator}report.md',
  );
  final jsonText = const JsonEncoder.withIndent('  ').convert(report);
  await latestJsonFile.parent.create(recursive: true);
  await latestJsonFile.writeAsString(jsonText);
  await runJsonFile.writeAsString(jsonText);
  final markdown = _renderReportMarkdown(report);
  await latestMarkdownFile.writeAsString(markdown);
  await runMarkdownFile.writeAsString(markdown);
  stdout.writeln('run_report: ${runJsonFile.path}');
  stdout.writeln('report: ${latestJsonFile.path}');
  stdout.writeln('markdown: ${latestMarkdownFile.path}');
}

String _renderReportMarkdown(JsonMap report) {
  final validation = ValueReaders.mapValue(report['validation']);
  final ordinary = ValueReaders.mapValue(report['ordinary_workbench_step']);
  final batches = ValueReaders.mapValue(report['long_task_batches']);
  final viewmodel = ValueReaders.mapValue(report['gui_viewmodel']);
  final workbenchVm = ValueReaders.mapValue(
    viewmodel['workbench_information_viewmodel'],
  );
  final stationVm = ValueReaders.mapValue(
    viewmodel['long_task_station_viewmodel'],
  );
  final ordinaryExpression = ValueReaders.mapValue(
    ordinary['expression_constraint_report'],
  );
  final latestBatch = ValueReaders.mapList(batches['batches']).isEmpty
      ? const <String, Object?>{}
      : ValueReaders.mapValue(ValueReaders.mapList(batches['batches']).last);
  final latestBatchResult = ValueReaders.mapValue(
    latestBatch['last_result_summary'],
  );
  final latestBatchExpression = ValueReaders.mapValue(
    latestBatchResult['expression_constraint_report'],
  );
  final selectedRun = ValueReaders.mapValue(stationVm['selected_run']);
  final selectedRunStopDiagnosis = ValueReaders.mapValue(
    selectedRun['stop_diagnosis'],
  );
  final selectedRunExpressionStatus = ValueReaders.mapValue(
    selectedRun['expression_constraint_status'],
  );
  final fileCounts = ValueReaders.mapValue(viewmodel['project_file_counts']);
  final lines = <String>[
    '# GUI/ViewModel 信息收集长任务真实探针报告',
    '',
    '- 结果：${ValueReaders.boolValue(report['ok']) ? 'PASS' : 'FAIL'}',
    '- 分类：${ValueReaders.stringValue(report['report_category'])}',
    '- 摘要：${ValueReaders.stringValue(validation['summary'])}',
    '- 项目路径：`${ValueReaders.stringValue(report['project_root'])}`',
    '- 工作区：`${ValueReaders.stringValue(report['workspace_root'])}`',
    '',
    '## 普通工作台会话',
    '',
    '- 主要输出：`${ValueReaders.stringValue(ordinary['output_path'])}`',
    '- 信息状态：${ValueReaders.stringValue(ordinary['information_status'])}',
    '- 信息摘要：${ValueReaders.stringValue(ordinary['information_summary'])}',
    '- 工具：${ValueReaders.stringList(ordinary['tool_names']).join('、')}',
    '- 表达策略：${ValueReaders.stringValue(ordinaryExpression['policy_mode'])}',
    '- 注入强度：${ValueReaders.stringValue(ordinaryExpression['injection_strength'])}',
    '- 审查要求：${ValueReaders.stringValue(ordinaryExpression['review_requirement'])}',
    '- 审查证据：required=${ValueReaders.boolValue(ordinaryExpression['review_required'])} / provided=${ValueReaders.boolValue(ordinaryExpression['review_provided'])}',
    '- 风险处置：${ValueReaders.stringValue(ordinaryExpression['disposition'])}',
    '- 风险信号：${ValueReaders.stringList(ordinaryExpression['risk_signals']).join('、')}',
    '- 路径归一：${ValueReaders.stringValue(ValueReaders.mapValue(ordinaryExpression['path_resolution'])['requested_path'])} -> ${ValueReaders.stringValue(ValueReaders.mapValue(ordinaryExpression['path_resolution'])['resolved_path'])}',
    '',
    '## 长任务批次',
    '',
    '- 长任务运行记录：`${ValueReaders.stringValue(batches['long_task_run_path'])}`',
    '- 章节文件数：${ValueReaders.intValue(batches['chapter_file_count'])}',
    '- 已物化任务：${ValueReaders.intValue(batches['materialized_task_count'])}',
    '- 已物化章节任务：${ValueReaders.intValue(batches['materialized_chapter_task_count'])}',
    '- 最近停点：${ValueReaders.stringValue(ValueReaders.mapValue(latestBatchExpression['stop_reason'])['code'])}',
    '- 最近停点摘要：${ValueReaders.stringValue(ValueReaders.mapValue(latestBatchExpression['stop_reason'])['summary'])}',
    '- 最近表达策略：${ValueReaders.stringValue(latestBatchExpression['policy_mode'])}',
    '- 最近风险处置：${ValueReaders.stringValue(latestBatchExpression['disposition'])}',
    '- 最近章节路径：${ValueReaders.stringValue(ValueReaders.mapValue(latestBatchExpression['path_resolution'])['requested_path'])} -> ${ValueReaders.stringValue(ValueReaders.mapValue(latestBatchExpression['path_resolution'])['resolved_path'])}',
    '',
    '## GUI ViewModel',
    '',
    '- Workbench 资料摘要：${ValueReaders.stringValue(workbenchVm['summary'])}',
    '- Workbench 使用摘要：${ValueReaders.stringValue(workbenchVm['usage_summary'])}',
    '- Long Task Station：${ValueReaders.stringValue(stationVm['status_message'])}',
    '- Station 运行数：${ValueReaders.intValue(stationVm['total_count'])}',
    '- 选中运行停点：${ValueReaders.stringValue(selectedRunStopDiagnosis['label'])}',
    '- 选中运行停点摘要：${ValueReaders.stringValue(selectedRunStopDiagnosis['summary'])}',
    '- 选中运行表达状态：${ValueReaders.stringValue(selectedRunExpressionStatus['label'])}',
    '- 选中运行表达摘要：${ValueReaders.stringValue(selectedRunExpressionStatus['summary'])}',
    '- 文件计数：章节 ${ValueReaders.intValue(fileCounts['chapter_files'])}，研究记录 ${ValueReaders.intValue(fileCounts['research_notes'])}，研究请求 ${ValueReaders.intValue(fileCounts['research_requests'])}',
    '',
    '## 失败原因',
    '',
  ];
  final failureReasons = ValueReaders.stringList(validation['failure_reasons']);
  if (failureReasons.isEmpty) {
    lines.add('- 无');
  } else {
    for (final reason in failureReasons) {
      lines.add('- $reason');
    }
  }
  lines.add('');
  lines.add('## 批次明细');
  lines.add('');
  for (final batch in ValueReaders.mapList(batches['batches'])) {
    lines.add(
      '- Batch ${ValueReaders.intValue(batch['batch_index'])}: '
      'ok=${ValueReaders.boolValue(batch['ok'])}, '
      'steps=${ValueReaders.intValue(batch['steps_run'])}, '
      'stop=${ValueReaders.stringValue(batch['stop_reason'])}, '
      'chapters=${ValueReaders.intValue(batch['chapter_file_count_after_batch'])}',
    );
  }
  lines.add('');
  return lines.join('\n');
}

HostPlatform _currentHostPlatform() {
  if (Platform.isWindows) {
    return HostPlatform.windows;
  }
  if (Platform.isLinux) {
    return HostPlatform.linux;
  }
  if (Platform.isMacOS) {
    return HostPlatform.macos;
  }
  if (Platform.isAndroid) {
    return HostPlatform.android;
  }
  if (Platform.isIOS) {
    return HostPlatform.ios;
  }
  return HostPlatform.unknown;
}

String _tailText(String text, int maxLength) {
  final clean = text.trim();
  if (clean.length <= maxLength) {
    return clean;
  }
  return clean.substring(clean.length - maxLength);
}

class _ProbeRuntimeOptions {
  const _ProbeRuntimeOptions({
    required this.queueBatches,
    required this.queueMaxStepsPerBatch,
    required this.expressionConstraintPolicyMode,
  });

  factory _ProbeRuntimeOptions.fromArguments(List<String> arguments) {
    return _ProbeRuntimeOptions(
      queueBatches: _intArgument(
        arguments,
        names: const <String>['--batches', '--queue-batches'],
        fallback: _defaultProbeQueueBatches,
        min: 1,
        max: 50,
      ),
      queueMaxStepsPerBatch: _intArgument(
        arguments,
        names: const <String>[
          '--steps',
          '--queue-steps',
          '--max-steps-per-batch',
        ],
        fallback: _defaultQueueMaxStepsPerBatch,
        min: 1,
        max: 30,
      ),
      expressionConstraintPolicyMode: _expressionConstraintPolicyArgument(
        arguments,
      ),
    );
  }

  final int queueBatches;
  final int queueMaxStepsPerBatch;
  final String expressionConstraintPolicyMode;
}

String _expressionConstraintPolicyArgument(List<String> arguments) {
  final raw = _stringArgument(
    arguments,
    names: const <String>[
      '--expression-policy',
      '--expression-constraint-policy',
      '--expression_constraint_policy_mode',
    ],
    fallback: ExpressionConstraintExecutionPolicyModes.adaptive,
  ).trim().toLowerCase();
  return ExpressionConstraintExecutionPolicyModes.knownValues.contains(raw)
      ? raw
      : ExpressionConstraintExecutionPolicyModes.adaptive;
}

String _stringArgument(
  List<String> arguments, {
  required List<String> names,
  required String fallback,
}) {
  for (final name in names) {
    for (var index = 0; index < arguments.length; index += 1) {
      final argument = arguments[index];
      if (argument == name && index + 1 < arguments.length) {
        return arguments[index + 1];
      }
      final prefix = '$name=';
      if (argument.startsWith(prefix)) {
        return argument.substring(prefix.length);
      }
    }
  }
  return fallback;
}

int _intArgument(
  List<String> arguments, {
  required List<String> names,
  required int fallback,
  required int min,
  required int max,
}) {
  for (final name in names) {
    for (var index = 0; index < arguments.length; index += 1) {
      final argument = arguments[index];
      if (argument == name && index + 1 < arguments.length) {
        return _clampedInt(arguments[index + 1], fallback, min, max);
      }
      final prefix = '$name=';
      if (argument.startsWith(prefix)) {
        return _clampedInt(
          argument.substring(prefix.length),
          fallback,
          min,
          max,
        );
      }
    }
  }
  return fallback;
}

int _clampedInt(String raw, int fallback, int min, int max) {
  final value = int.tryParse(raw.trim()) ?? fallback;
  return value.clamp(min, max).toInt();
}

const int _chapterBudgetUpperBound = 200;
const int _defaultProbeQueueBatches = 8;
const int _defaultQueueMaxStepsPerBatch = 6;

const String _storySeedSummary =
    '现代社畜穿越到明代后期江南士绅家纨绔身上，用现代基础科学与经营常识小步发展，轻松向，节奏不急。';

const List<String> _ordinaryPinnedPaths = <String>[
  'specs/project_spec.md',
  'styles/轻松历史经营风格.md',
  'outlines/story/创作起点.md',
  'assets/characters/周砚_周延璋.md',
  'assets/world/明代后期江南市镇.md',
  'research/research_questions.md',
];

const String _ordinaryWorkbenchTitle = '普通会话：开篇筹备与资料核查';

const String _ordinaryWorkbenchPrompt = '''
你现在是用户从 GUI 工作台发起的一次普通会话，不是后台长任务，也不是直接章节交付。

请围绕这个项目的开篇筹备，先判断还缺哪些必要资料、约束或用户确认项，并在本轮完成一件最有价值的推进动作。

要求：
- 优先做开篇筹备相关动作，例如补一条 research note、登记 research request、更新知识卡/设计元素、整理约束，或明确向用户发起待确认项。
- 如果涉及明代后期江南生活细节，不能凭记忆猜写；需要先调用 request_external_research，或至少形成可追踪的 research note / request。
- 不要把普通开篇输入直接短路成“产出第一章正文交付”；除非用户明确要求，否则不要强行把本轮目标升级成 submit_chapter_delivery。
- 完成后只简短说明本轮推进了什么；如果仍需用户决定，明确给出待确认点。
''';
