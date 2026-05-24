import 'package:novel_agent_core/novel_agent_core.dart';

import '../storage/project_prompt_template_service.dart';
import '../storage/project_task_repository.dart';

typedef WorkflowGenerateDraftUseCaseFactory =
    GenerateDraftUseCase Function(ProviderEndpointSettings provider);

class ProjectWorkflowRuntimeService {
  ProjectWorkflowRuntimeService({
    required ProjectTaskRepository taskRepository,
    required ProjectPromptTemplateService promptTemplateService,
    required WorkflowGenerateDraftUseCaseFactory generateDraftUseCaseFactory,
    TaskDefinitionService? taskDefinitionService,
    TaskSelectionService? taskSelectionService,
    TaskQueueOptionService? taskQueueOptionService,
    TaskQueueStopPolicyService? taskQueueStopPolicyService,
    TaskQueuePreflightService? taskQueuePreflightService,
    LongTaskModeService? longTaskModeService,
    LongTaskPathPolicyService? longTaskPathPolicyService,
    BuildLongTaskPlanUseCase? buildLongTaskPlanUseCase,
    LongTaskRunPathService? longTaskRunPathService,
    StartLongTaskRunUseCase? startLongTaskRunUseCase,
    BuildLongTaskSchedulerSnapshotUseCase?
    buildLongTaskSchedulerSnapshotUseCase,
    BuildLongTaskPromptUseCase? buildLongTaskPromptUseCase,
    LongTaskPostprocessTransactionService? postprocessTransactionService,
    LongTaskPostprocessPromptRenderer? postprocessPromptRenderer,
    LongTaskRunStepRecorderService? longTaskRunStepRecorderService,
    LongTaskFinishDispositionService? finishDispositionService,
    LongTaskRunLifecycleService? lifecycleService,
    PrepareChapterAtomicExecutionUseCase? prepareExecutionUseCase,
    BuildLongTaskRevisionPlanUseCase? buildLongTaskRevisionPlanUseCase,
    LongTaskRevisionApplyService? longTaskRevisionApplyService,
    RevisionDiffPreviewService? revisionDiffPreviewService,
    RevisionDiffMarkdownRenderer? revisionDiffMarkdownRenderer,
  }) : _taskRepository = taskRepository,
       _promptTemplateService = promptTemplateService,
       _generateDraftUseCaseFactory = generateDraftUseCaseFactory,
       _taskDefinitionService =
           taskDefinitionService ?? TaskDefinitionService(),
       _taskSelectionService =
           taskSelectionService ??
           TaskSelectionService(
             taskDefinitionService:
                 taskDefinitionService ?? TaskDefinitionService(),
           ),
       _taskQueueOptionService =
           taskQueueOptionService ?? TaskQueueOptionService(),
       _taskQueueStopPolicyService =
           taskQueueStopPolicyService ??
           TaskQueueStopPolicyService(
             optionService: taskQueueOptionService ?? TaskQueueOptionService(),
           ),
       _taskQueuePreflightService =
           taskQueuePreflightService ??
           TaskQueuePreflightService(
             optionService: taskQueueOptionService ?? TaskQueueOptionService(),
             taskSelectionService:
                 taskSelectionService ??
                 TaskSelectionService(
                   taskDefinitionService:
                       taskDefinitionService ?? TaskDefinitionService(),
                 ),
             taskDefinitionService:
                 taskDefinitionService ?? TaskDefinitionService(),
           ),
       _longTaskModeService = longTaskModeService ?? LongTaskModeService(),
       _longTaskPathPolicyService =
           longTaskPathPolicyService ?? LongTaskPathPolicyService(),
       _buildLongTaskPlanUseCase =
           buildLongTaskPlanUseCase ??
           _defaultBuildLongTaskPlanUseCase(
             longTaskModeService ?? LongTaskModeService(),
             longTaskPathPolicyService ?? LongTaskPathPolicyService(),
           ),
       _longTaskRunPathService =
           longTaskRunPathService ??
           LongTaskRunPathService(
             pathPolicyService:
                 longTaskPathPolicyService ?? LongTaskPathPolicyService(),
           ),
       _startLongTaskRunUseCase =
           startLongTaskRunUseCase ??
           _defaultStartLongTaskRunUseCase(
             longTaskModeService ?? LongTaskModeService(),
             longTaskPathPolicyService ?? LongTaskPathPolicyService(),
           ),
       _buildLongTaskSchedulerSnapshotUseCase =
           buildLongTaskSchedulerSnapshotUseCase ??
           _defaultBuildLongTaskSchedulerSnapshotUseCase(
             longTaskModeService ?? LongTaskModeService(),
             longTaskPathPolicyService ?? LongTaskPathPolicyService(),
             taskDefinitionService ?? TaskDefinitionService(),
           ),
       _buildLongTaskPromptUseCase =
           buildLongTaskPromptUseCase ??
           _defaultBuildLongTaskPromptUseCase(
             longTaskModeService ?? LongTaskModeService(),
             longTaskPathPolicyService ?? LongTaskPathPolicyService(),
           ),
       _postprocessTransactionService =
           postprocessTransactionService ??
           _defaultPostprocessTransactionService(
             longTaskModeService ?? LongTaskModeService(),
             longTaskPathPolicyService ?? LongTaskPathPolicyService(),
           ),
       _postprocessPromptRenderer =
           postprocessPromptRenderer ??
           _defaultPostprocessPromptRenderer(
             longTaskPathPolicyService ?? LongTaskPathPolicyService(),
           ),
       _longTaskRunStepRecorderService =
           longTaskRunStepRecorderService ??
           LongTaskRunStepRecorderService(
             taskSummaryService: LongTaskTaskSummaryService(),
           ),
       _finishDispositionService =
           finishDispositionService ??
           _defaultFinishDispositionService(
             longTaskModeService ?? LongTaskModeService(),
           ),
       _lifecycleService = lifecycleService ?? LongTaskRunLifecycleService(),
       _prepareExecutionUseCase =
           prepareExecutionUseCase ?? _defaultPrepareExecutionUseCase(),
       _buildLongTaskRevisionPlanUseCase =
           buildLongTaskRevisionPlanUseCase ??
           _defaultBuildLongTaskRevisionPlanUseCase(
             longTaskModeService ?? LongTaskModeService(),
             longTaskPathPolicyService ?? LongTaskPathPolicyService(),
           ),
       _longTaskRevisionApplyService =
           longTaskRevisionApplyService ??
           LongTaskRevisionApplyService(
             runPathService:
                 longTaskRunPathService ??
                 LongTaskRunPathService(
                   pathPolicyService:
                       longTaskPathPolicyService ??
                       LongTaskPathPolicyService(),
                 ),
             transitionService: TaskTransitionService(),
             taskDefinitionService:
                 taskDefinitionService ?? TaskDefinitionService(),
           ),
       _revisionDiffPreviewService =
           revisionDiffPreviewService ?? RevisionDiffPreviewService(),
       _revisionDiffMarkdownRenderer =
           revisionDiffMarkdownRenderer ?? RevisionDiffMarkdownRenderer();

  final ProjectTaskRepository _taskRepository;
  final ProjectPromptTemplateService _promptTemplateService;
  final WorkflowGenerateDraftUseCaseFactory _generateDraftUseCaseFactory;
  final TaskDefinitionService _taskDefinitionService;
  final TaskSelectionService _taskSelectionService;
  final TaskQueueOptionService _taskQueueOptionService;
  final TaskQueueStopPolicyService _taskQueueStopPolicyService;
  final TaskQueuePreflightService _taskQueuePreflightService;
  final LongTaskModeService _longTaskModeService;
  final LongTaskPathPolicyService _longTaskPathPolicyService;
  final BuildLongTaskPlanUseCase _buildLongTaskPlanUseCase;
  final LongTaskRunPathService _longTaskRunPathService;
  final StartLongTaskRunUseCase _startLongTaskRunUseCase;
  final BuildLongTaskSchedulerSnapshotUseCase
  _buildLongTaskSchedulerSnapshotUseCase;
  final BuildLongTaskPromptUseCase _buildLongTaskPromptUseCase;
  final LongTaskPostprocessTransactionService _postprocessTransactionService;
  final LongTaskPostprocessPromptRenderer _postprocessPromptRenderer;
  final LongTaskRunStepRecorderService _longTaskRunStepRecorderService;
  final LongTaskFinishDispositionService _finishDispositionService;
  final LongTaskRunLifecycleService _lifecycleService;
  final PrepareChapterAtomicExecutionUseCase _prepareExecutionUseCase;
  final BuildLongTaskRevisionPlanUseCase _buildLongTaskRevisionPlanUseCase;
  final LongTaskRevisionApplyService _longTaskRevisionApplyService;
  final RevisionDiffPreviewService _revisionDiffPreviewService;
  final RevisionDiffMarkdownRenderer _revisionDiffMarkdownRenderer;

  List<JsonMap> listTaskRuntimeModes() {
    // 中文注释: 模式定义直接来自 core，确保任务中心和 CLI 的枚举完全同源。
    return _taskDefinitionService.modeDefinitions();
  }

  Future<JsonMap> createLongTaskWorkflow(
    ProjectDescriptor project,
    String mode, {
    JsonMap options = const <String, Object?>{},
  }) async {
    // 中文注释: 长任务开局同时落计划与任务文件，形成可恢复的项目级队列。
    final createdAt = DateTime.now().toIso8601String();
    final planId =
        'plan_${_longTaskPathPolicyService.safeId(mode)}_${DateTime.now().microsecondsSinceEpoch}';
    final planPath = 'tracking/long_task/$planId.plan.json';
    final planMarkdownPath = 'tracking/long_task/$planId.plan.md';
    final built = _buildLongTaskPlanUseCase.execute(
      mode,
      planId,
      options: options,
      createdAt: createdAt,
      planPath: planPath,
      planMarkdownPath: planMarkdownPath,
    );
    final tasks = ValueReaders.mapList(built['tasks'])
        .map((task) => ValueReaders.deepCopyMap(task)
          ..['relative_path'] = _longTaskRunPathService.taskPathForNewTask(task))
        .toList(growable: false);
    await _taskRepository.saveTasks(project, tasks);
    await _taskRepository.saveRecord(
      project,
      planPath,
      ValueReaders.mapValue(built['plan']),
    );
    await _taskRepository.writeTextFile(
      project,
      planMarkdownPath,
      ValueReaders.stringValue(built['markdown']),
    );
    return <String, Object?>{
      'ok': true,
      'mode': _longTaskModeService.normalizeMode(mode),
      'plan_id': planId,
      'created_tasks': tasks,
      'plan_path': planPath,
      'plan_markdown_path': planMarkdownPath,
      'changed_paths': <Object?>[
        planPath,
        planMarkdownPath,
        ...tasks.map((task) => ValueReaders.stringValue(task['relative_path'])),
      ],
    };
  }

  Future<List<JsonMap>> listWorkflowTasks(
    ProjectDescriptor project, {
    JsonMap filters = const <String, Object?>{},
  }) async {
    // 中文注释: 任务列表统一按 core 排序服务输出，保证不同宿主看到同一顺序。
    final tasks = await _taskRepository.listTasks(project, filters: filters);
    return _taskSelectionService.sortTasks(tasks, filters: filters);
  }

  Future<JsonMap> nextWorkflowTask(
    ProjectDescriptor project, {
    JsonMap filters = const <String, Object?>{},
  }) async {
    // 中文注释: 下一可运行任务完全复用共享调度规则。
    final tasks = await listWorkflowTasks(project, filters: filters);
    return _taskSelectionService.nextRunnableTaskFromTasks(tasks);
  }

  Future<JsonMap> nextWorkflowPostprocessTask(
    ProjectDescriptor project, {
    JsonMap filters = const <String, Object?>{},
  }) async {
    // 中文注释: 下一后处理任务与普通 runnable 分离选择，保持旧项目语义。
    final tasks = await listWorkflowTasks(project, filters: filters);
    return _taskSelectionService.nextPostprocessTaskFromTasks(tasks);
  }

  Future<JsonMap> workflowChainView(
    ProjectDescriptor project, {
    JsonMap filters = const <String, Object?>{},
  }) async {
    // 中文注释: 链路视图返回轻量节点与下一步摘要，供 GUI/CLI 做总览和恢复提示。
    final tasks = await listWorkflowTasks(project, filters: filters);
    final nodes = tasks
        .map(
          (task) => <String, Object?>{
            'id': ValueReaders.stringValue(task['id']),
            'title': ValueReaders.stringValue(task['title']),
            'status': ValueReaders.stringValue(task['status']),
            'task_type': ValueReaders.stringValue(task['task_type']),
            'relative_path': ValueReaders.stringValue(task['relative_path']),
            'depends_on': ValueReaders.stringList(task['depends_on']),
            'manual_checkpoint': ValueReaders.boolValue(
              ValueReaders.mapValue(task['metadata'])['manual_checkpoint'],
            ),
          },
        )
        .toList(growable: false);
    return <String, Object?>{
      'ok': true,
      'chains': nodes,
      'next_task': _taskDefinitionService.taskSummary(
        _taskSelectionService.nextRunnableTaskFromTasks(tasks),
      ),
      'next_postprocess_task': _taskDefinitionService.taskSummary(
        _taskSelectionService.nextPostprocessTaskFromTasks(tasks),
      ),
    };
  }

  Future<JsonMap> saveWorkflowChainSnapshot(
    ProjectDescriptor project, {
    JsonMap filters = const <String, Object?>{},
  }) async {
    // 中文注释: 链路快照只落 Markdown，可被会话压缩恢复和人工检查共同复用。
    final view = await workflowChainView(project, filters: filters);
    final relativePath =
        'tracking/task_chains/chain_${DateTime.now().microsecondsSinceEpoch}.md';
    final lines = <String>[
      '# 任务链路快照',
      '',
      '- 时间：${DateTime.now().toIso8601String()}',
      '- 下一任务：${ValueReaders.stringValue(ValueReaders.mapValue(view['next_task'])['title'], '无')}',
      '- 下一后处理：${ValueReaders.stringValue(ValueReaders.mapValue(view['next_postprocess_task'])['title'], '无')}',
      '',
      '## 节点',
    ];
    for (final node in ValueReaders.mapList(view['chains'])) {
      lines.add(
        '- ${ValueReaders.stringValue(node['status'])}｜${ValueReaders.stringValue(node['task_type'])}｜${ValueReaders.stringValue(node['title'])}',
      );
    }
    await _taskRepository.writeTextFile(project, relativePath, lines.join('\n'));
    return <String, Object?>{
      'ok': true,
      'relative_path': relativePath,
      'markdown_path': relativePath,
      'changed_paths': <Object?>[relativePath],
    };
  }

  Future<JsonMap> saveWorkflowTaskPlan(
    ProjectDescriptor project,
    JsonMap selector,
  ) async {
    // 中文注释: 当前单任务计划先落共享事务提示，足够支撑“先看再跑”的旧工作流。
    final task = await _taskRepository.loadTask(project, selector);
    if (task.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Task not found.',
        'relative_path': '',
      };
    }
    final prompt = _buildLongTaskPromptUseCase.execute(
      task,
      options: <String, Object?>{
        'project_templates': await _templateMap(project),
      },
    );
    final safeId = _longTaskPathPolicyService.safeId(
      ValueReaders.stringValue(task['id']),
      fallbackPrefix: 'task',
    );
    final relativePath = 'tracking/task_plans/$safeId.plan.md';
    await _taskRepository.writeTextFile(project, relativePath, prompt);
    return <String, Object?>{
      'ok': true,
      'relative_path': relativePath,
      'markdown_path': relativePath,
      'prompt': prompt,
      'changed_paths': <Object?>[relativePath],
    };
  }

  Future<JsonMap> prepareWorkflowTaskExecution(
    ProjectDescriptor project,
    JsonMap selector, {
    JsonMap projectInfo = const <String, Object?>{},
    JsonMap agent = const <String, Object?>{},
    JsonMap modelProfile = const <String, Object?>{},
    JsonMap contextSettings = const <String, Object?>{},
  }) async {
    // 中文注释: 执行包准备会把 execution JSON 和 checklist Markdown 一起落盘。
    final task = await _taskRepository.loadTask(project, selector);
    if (task.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Task not found.',
        'relative_path': '',
      };
    }
    await _taskRepository.transitionTask(
      project,
      selector,
      TaskRuntimeConstants.statusPlanning,
      note: '开始准备章节原子执行包。',
    );
    final prompt = _buildLongTaskPromptUseCase.execute(
      task,
      options: <String, Object?>{
        'project_templates': await _templateMap(project),
      },
    );
    final entries = await _taskRepository.workspacePort.listEntries(
      project.rootPath,
    );
    final result = _prepareExecutionUseCase.execute(
      <String, Object?>{
        'project': projectInfo.isEmpty
            ? <String, Object?>{
                'id': project.id,
                'title': project.name,
                'path': project.rootPath,
                'project_type': project.projectType,
              }
            : projectInfo,
        'task': task,
        'project_files': entries,
        'session_context': '',
        'current_file_body': '',
        'current_file_path': '',
        'user_prompt': prompt,
        'agent': agent,
        'optional_agents': const <Object?>[],
        'context_settings': contextSettings,
        'model_profile': modelProfile,
      },
    );
    if (!ValueReaders.boolValue(result['ok'])) {
      await _taskRepository.transitionTask(
        project,
        selector,
        TaskRuntimeConstants.statusFailed,
        note: '章节原子执行包准备失败：${ValueReaders.stringValue(result["error"])}',
      );
      return result;
    }
    final execution = ValueReaders.mapValue(result['execution'])
      ..['prompt_preview_markdown'] = prompt;
    final executionPath = ValueReaders.stringValue(result['execution_path']);
    final checklistPath = ValueReaders.stringValue(result['checklist_path']);
    await _taskRepository.saveRecord(project, executionPath, execution);
    await _taskRepository.writeTextFile(project, checklistPath, prompt);
    await _taskRepository.transitionTask(
      project,
      selector,
      TaskRuntimeConstants.statusPlanning,
      note: '章节原子执行包已准备，等待模型执行。',
      extra: <String, Object?>{
        'atomic_execution_path': executionPath,
        'atomic_checklist_path': checklistPath,
        'context_pack_id': ValueReaders.stringValue(result['context_pack_id']),
        'proposed_output_paths': ValueReaders.mapValue(
          result['proposed_output_paths'],
        ),
      },
    );
    return <String, Object?>{
      'ok': true,
      'execution_path': executionPath,
      'checklist_path': checklistPath,
      'relative_path': executionPath,
      'context_pack_id': ValueReaders.stringValue(result['context_pack_id']),
      'execution': execution,
      'changed_paths': <Object?>[executionPath, checklistPath],
    };
  }

  Future<JsonMap> loadWorkflowTaskExecution(
    ProjectDescriptor project,
    JsonMap selector,
  ) async {
    // 中文注释: 执行包详情统一通过任务记录中的 atomic_execution_path 定位。
    final task = await _taskRepository.loadTask(project, selector);
    if (task.isEmpty) {
      return <String, Object?>{};
    }
    final executionPath = ValueReaders.stringValue(
      task['atomic_execution_path'],
    ).trim();
    if (executionPath.isEmpty) {
      return <String, Object?>{};
    }
    return _taskRepository.loadRecord(project, executionPath);
  }

  Future<JsonMap> runWorkflowTaskOnce(
    ProjectDescriptor project,
    AppSettings settings,
    JsonMap selector, {
    JsonMap runRecord = const <String, Object?>{},
    JsonMap agent = const <String, Object?>{},
  }) async {
    // 中文注释: 单步执行复用共享生成用例和项目工具调度，形成 GUI/CLI 共用运行链。
    final provider = settings.defaultProvider();
    if (provider == null) {
      return <String, Object?>{
        'ok': false,
        'error': '未找到可用 provider。',
        'response': <String, Object?>{},
      };
    }
    var task = await _taskRepository.loadTask(project, selector);
    if (task.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Task not found.',
        'response': <String, Object?>{},
      };
    }
    if (ValueReaders.stringValue(task['atomic_execution_path']).trim().isEmpty) {
      final prepared = await prepareWorkflowTaskExecution(
        project,
        selector,
        modelProfile: <String, Object?>{
          'id': provider.id,
          'base_url': provider.baseUrl,
          'model_id': provider.modelId,
        },
        contextSettings: settings.contextSettings,
      );
      if (!ValueReaders.boolValue(prepared['ok'])) {
        return <String, Object?>{
          'ok': false,
          'error': ValueReaders.stringValue(
            prepared['error'],
            'Prepare task failed.',
          ),
          'response': <String, Object?>{},
        };
      }
      task = await _taskRepository.loadTask(project, selector);
    }
    final prompt = _buildLongTaskPromptUseCase.execute(
      task,
      runRecord: runRecord,
      options: <String, Object?>{
        'project_templates': await _templateMap(project),
      },
    );
    await _taskRepository.transitionTask(
      project,
      selector,
      TaskRuntimeConstants.statusRunning,
      note: '章节原子任务开始单步模型执行。',
    );
    final useCase = _generateDraftUseCaseFactory(provider);
    final result = await useCase.execute(
      project: project,
      userPrompt: prompt,
      modelId: settings.defaultModelId.trim().isEmpty
          ? provider.modelId
          : settings.defaultModelId,
      title: ValueReaders.stringValue(task['title']),
      intent: 'workflow_task',
      agent: agent,
    );
    final outputPaths = result.writtenPaths;
    JsonMap revisionDiff = const <String, Object?>{};
    if (ValueReaders.stringValue(task['task_type']) == 'revision') {
      revisionDiff = await _saveRevisionDiffIfNeeded(
        project,
        task,
        result.executedTools,
      );
    }
    final executionPath = ValueReaders.stringValue(task['atomic_execution_path']);
    if (executionPath.trim().isNotEmpty) {
      final execution = await _taskRepository.loadRecord(project, executionPath);
      if (execution.isNotEmpty) {
        final nextExecution = ValueReaders.deepCopyMap(execution)
          ..['output_paths'] = outputPaths
          ..['last_result_preview'] = result.draftMarkdown
          ..['updated_at'] = DateTime.now().toIso8601String();
        if (ValueReaders.boolValue(revisionDiff['ok'])) {
          nextExecution['revision_diff_path'] = ValueReaders.stringValue(
            revisionDiff['relative_path'],
          );
        }
        await _taskRepository.saveRecord(project, executionPath, nextExecution);
      }
    }
    await _taskRepository.transitionTask(
      project,
      selector,
      TaskRuntimeConstants.statusWaitingUser,
      note: outputPaths.isEmpty
          ? '模型已返回，等待用户确认后继续。'
          : '模型已写入项目文件，等待用户确认后继续。',
      extra: <String, Object?>{
        'output_paths': outputPaths,
        if (ValueReaders.boolValue(revisionDiff['ok']))
          'revision_diff_path': ValueReaders.stringValue(
            revisionDiff['relative_path'],
          ),
        if (ValueReaders.boolValue(revisionDiff['ok']))
          'revision_diff_summary': ValueReaders.stringValue(
            ValueReaders.mapValue(revisionDiff['report'])['summary'],
          ),
      },
    );
    return <String, Object?>{
      'ok': true,
      'response': _resultAsResponse(result),
      'output_paths': outputPaths,
      'revision_diff': revisionDiff,
      'executed_tools': result.executedTools,
      'changed_paths': result.changedPaths,
    };
  }

  Future<JsonMap> runNextWorkflowTaskOnce(
    ProjectDescriptor project,
    AppSettings settings, {
    JsonMap agent = const <String, Object?>{},
  }) async {
    // 中文注释: 下一任务单步执行只是对 next runnable 的薄包装。
    final task = await nextWorkflowTask(project);
    if (task.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': '当前没有可运行任务。',
        'response': <String, Object?>{},
      };
    }
    return runWorkflowTaskOnce(
      project,
      settings,
      <String, Object?>{
        'relative_path': ValueReaders.stringValue(task['relative_path']),
      },
      agent: agent,
    );
  }

  Future<JsonMap> taskQueuePreflight(
    ProjectDescriptor project, {
    JsonMap options = const <String, Object?>{},
  }) async {
    // 中文注释: 预检只读任务与最近运行摘要，解释“能不能跑、为什么会停”。
    return _taskQueuePreflightService.preflightFromTasks(
      await listWorkflowTasks(project),
      options: options,
      recentRuns: await listTaskQueueRuns(project),
    );
  }

  Future<List<JsonMap>> listTaskQueueRuns(
    ProjectDescriptor project, {
    int limit = 10,
  }) {
    // 中文注释: 受控队列运行记录统一保存在 tracking/task_queue_runs/。
    return _taskRepository.listRunRecords(
      project,
      prefix: 'tracking/task_queue_runs/',
      limit: limit,
    );
  }

  Future<List<JsonMap>> listLongTaskRuns(
    ProjectDescriptor project, {
    int limit = 10,
  }) {
    // 中文注释: 长任务运行记录统一保存在 tracking/long_task_runs/。
    return _taskRepository.listRunRecords(
      project,
      prefix: 'tracking/long_task_runs/',
      limit: limit,
    );
  }

  Future<JsonMap> longTaskSchedulerPlan(
    ProjectDescriptor project, {
    String relativePath = '',
    JsonMap options = const <String, Object?>{},
  }) async {
    // 中文注释: 调度 tick 计划既支持指定运行记录，也支持默认使用最近一条长任务记录。
    var runPath = relativePath.trim();
    if (runPath.isEmpty) {
      final recentRuns = await listLongTaskRuns(project, limit: 1);
      if (recentRuns.isNotEmpty) {
        runPath = ValueReaders.stringValue(recentRuns.first['relative_path']);
      }
    }
    if (runPath.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Long task run not found.',
        'action': 'idle',
      };
    }
    final record = await _taskRepository.loadRecord(project, runPath);
    if (record.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Long task run not found.',
        'action': 'idle',
      };
    }
    final snapshot = _buildLongTaskSchedulerSnapshotUseCase.execute(
      record,
      await listWorkflowTasks(project),
      options: options,
    );
    return <String, Object?>{
      'ok': true,
      'relative_path': runPath,
      ...snapshot,
      ...ValueReaders.mapValue(snapshot['scheduler_plan']),
    };
  }

  Future<JsonMap> pauseLongTaskRun(
    ProjectDescriptor project,
    String relativePath, {
    String note = '用户暂停长任务。',
  }) async {
    // 中文注释: 暂停只改运行记录，不隐式改动任务文件状态。
    final record = await _taskRepository.loadRecord(project, relativePath);
    if (record.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Long task run not found.',
      };
    }
    final updated = _lifecycleService.pauseRecord(
      record,
      reason: 'manual_pause',
      note: note,
    );
    await _taskRepository.saveRecord(project, relativePath, updated);
    return <String, Object?>{'ok': true, 'record': updated};
  }

  Future<JsonMap> resumeLongTaskRun(
    ProjectDescriptor project,
    AppSettings settings,
    String relativePath, {
    JsonMap options = const <String, Object?>{},
    JsonMap agent = const <String, Object?>{},
  }) {
    // 中文注释: 恢复长任务直接复用队列运行入口，并显式传入继续的运行记录路径。
    return runWorkflowTaskQueue(
      project,
      settings,
      options: <String, Object?>{
        ...options,
        'continue_long_task_run_path': relativePath,
      },
      agent: agent,
    );
  }

  Future<JsonMap> runWorkflowTaskQueue(
    ProjectDescriptor project,
    AppSettings settings, {
    JsonMap options = const <String, Object?>{},
    JsonMap agent = const <String, Object?>{},
  }) async {
    // 中文注释: 受控连续运行按安全步数推进，并把队列记录与长任务记录都写到 tracking/。
    final cleanOptions = _taskQueueOptionService.normalizeOptions(options);
    final queueId = 'task_queue_${DateTime.now().microsecondsSinceEpoch}';
    final queuePath = 'tracking/task_queue_runs/$queueId.json';
    var queueRecord = <String, Object?>{
      'schema_version': 1,
      'id': queueId,
      'status': 'running',
      'options': cleanOptions,
      'steps': <Object?>[],
      'completed_steps': 0,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'relative_path': queuePath,
      'summary_path': 'tracking/task_queue_runs/$queueId.md',
    };
    await _taskRepository.saveRecord(project, queuePath, queueRecord);

    var longRunPath = ValueReaders.stringValue(
      options['continue_long_task_run_path'],
      ValueReaders.stringValue(options['long_task_run_path']),
    ).trim();
    JsonMap longRunRecord = const <String, Object?>{};
    if (longRunPath.isEmpty) {
      final start = _startLongTaskRunUseCase.execute(
        await listWorkflowTasks(project),
        options: cleanOptions,
      );
      longRunPath = ValueReaders.stringValue(start['relative_path']);
      longRunRecord = ValueReaders.mapValue(start['record']);
      await _taskRepository.saveRecord(project, longRunPath, longRunRecord);
    } else {
      longRunRecord = await _taskRepository.loadRecord(project, longRunPath);
      if (longRunRecord.isNotEmpty) {
        longRunRecord = _lifecycleService.resumeRecord(longRunRecord);
        await _taskRepository.saveRecord(project, longRunPath, longRunRecord);
      }
    }

    var stepsRun = 0;
    var stopReason = '';
    var stopNote = '';
    JsonMap lastResult = const <String, Object?>{};
    while (stepsRun < ValueReaders.intValue(cleanOptions['max_steps'], 3)) {
      final nextTask = await nextWorkflowTask(project);
      if (nextTask.isEmpty) {
        stopReason = 'no_runnable_task';
        stopNote = '当前没有依赖满足且处于 queued/retrying 的任务。';
        break;
      }
      lastResult = await runWorkflowTaskOnce(
        project,
        settings,
        <String, Object?>{
          'relative_path': ValueReaders.stringValue(nextTask['relative_path']),
        },
        runRecord: longRunRecord,
        agent: agent,
      );
      stepsRun += 1;
      final updatedTask = await _taskRepository.loadTask(
        project,
        <String, Object?>{
          'relative_path': ValueReaders.stringValue(nextTask['relative_path']),
        },
      );
      queueRecord = _appendQueueStep(
        queueRecord,
        updatedTask,
        lastResult,
        index: stepsRun,
      );
      await _taskRepository.saveRecord(project, queuePath, queueRecord);

      if (longRunRecord.isNotEmpty) {
        longRunRecord = _longTaskRunStepRecorderService.recordStep(
          longRunRecord,
          updatedTask,
          lastResult,
        );
        await _taskRepository.saveRecord(project, longRunPath, longRunRecord);
      }

      final stopDecision = _taskQueueStopPolicyService.stopAfterStep(
        lastResult,
        updatedTask,
        options: cleanOptions,
      );
      if (ValueReaders.boolValue(stopDecision['stop'])) {
        stopReason = ValueReaders.stringValue(stopDecision['reason']);
        stopNote = ValueReaders.stringValue(stopDecision['note']);
        break;
      }
    }

    if (stopReason.isEmpty) {
      stopReason = stepsRun >= ValueReaders.intValue(cleanOptions['max_steps'], 3)
          ? 'max_steps'
          : 'completed';
      stopNote = stopReason == 'max_steps' ? '已达到本批最大步数。' : '队列已完成。';
    }
    queueRecord = ValueReaders.deepCopyMap(queueRecord)
      ..['status'] = _taskQueueStopPolicyService.statusForReason(stopReason)
      ..['completed_steps'] = stepsRun
      ..['stop_reason'] = stopReason
      ..['stop_note'] = stopNote
      ..['updated_at'] = DateTime.now().toIso8601String();
    await _taskRepository.saveRecord(project, queuePath, queueRecord);
    await _taskRepository.writeTextFile(
      project,
      ValueReaders.stringValue(queueRecord['summary_path']),
      TaskQueueRecordRenderer().renderMarkdown(queueRecord),
    );

    if (longRunRecord.isNotEmpty) {
      final disposition = _finishDispositionService.finishDisposition(
        stopReason,
        stepsRun,
        options: <String, Object?>{
          ...cleanOptions,
          'mode': ValueReaders.stringValue(longRunRecord['mode']),
          'stop_note': stopNote,
        },
      );
      longRunRecord = ValueReaders.stringValue(
            disposition['record_action'],
          ) ==
          'pause'
          ? _lifecycleService.pauseRecord(
              longRunRecord,
              reason: ValueReaders.stringValue(disposition['reason']),
              note: ValueReaders.stringValue(disposition['note']),
            )
          : _lifecycleService.finishRecord(
              longRunRecord,
              reason: ValueReaders.stringValue(disposition['terminal_reason']),
              note: ValueReaders.stringValue(disposition['note']),
            );
      await _taskRepository.saveRecord(project, longRunPath, longRunRecord);
      final schedulerSnapshot = _buildLongTaskSchedulerSnapshotUseCase.execute(
        longRunRecord,
        await listWorkflowTasks(project),
        options: cleanOptions,
      );
      await _taskRepository.writeTextFile(
        project,
        ValueReaders.stringValue(longRunRecord['summary_path']),
        ValueReaders.stringValue(schedulerSnapshot['markdown']),
      );
    }

    return <String, Object?>{
      'ok': ValueReaders.boolValue(lastResult['ok'], true) || stepsRun == 0,
      'relative_path': queuePath,
      'summary_path': ValueReaders.stringValue(queueRecord['summary_path']),
      'stop_reason': stopReason,
      'stop_note': stopNote,
      'steps_run': stepsRun,
      'last_result': lastResult,
      'record': queueRecord,
      'long_task_run_path': longRunPath,
      'long_task_record': longRunRecord,
    };
  }

  Future<JsonMap> runWorkflowTaskPostprocessOnce(
    ProjectDescriptor project,
    AppSettings settings,
    JsonMap selector, {
    JsonMap agent = const <String, Object?>{},
  }) async {
    // 中文注释: 后处理提示明确“不要重写正文”，只推进摘要、记忆与检查产物。
    final provider = settings.defaultProvider();
    if (provider == null) {
      return <String, Object?>{
        'ok': false,
        'error': '未找到可用 provider。',
        'response': <String, Object?>{},
      };
    }
    final task = await _taskRepository.loadTask(project, selector);
    if (task.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Task not found.',
        'response': <String, Object?>{},
      };
    }
    final execution = await loadWorkflowTaskExecution(project, selector);
    if (execution.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': '请先准备执行包并执行一次正文生成。',
        'response': <String, Object?>{},
      };
    }
    final draftPaths = ValueReaders.stringList(
      execution.containsKey('output_paths')
          ? execution['output_paths']
          : task['output_paths'],
    );
    final prompt = _postprocessPromptRenderer.renderPostprocessPrompt(
      _postprocessTransactionService.buildPostprocessTransaction(
        task,
        execution,
        draftPaths,
        options: <String, Object?>{
          'project_templates': await _templateMap(project),
        },
      ),
    );
    await _taskRepository.transitionTask(
      project,
      selector,
      TaskRuntimeConstants.statusRunning,
      note: '章节原子任务开始单步后处理。',
    );
    final useCase = _generateDraftUseCaseFactory(provider);
    final result = await useCase.execute(
      project: project,
      userPrompt: prompt,
      modelId: settings.defaultModelId.trim().isEmpty
          ? provider.modelId
          : settings.defaultModelId,
      title: ValueReaders.stringValue(task['title']),
      intent: 'workflow_postprocess',
      agent: agent,
    );
    final mergedOutputs = _mergePaths(
      ValueReaders.stringList(task['output_paths']),
      result.writtenPaths,
    );
    await _taskRepository.transitionTask(
      project,
      selector,
      TaskRuntimeConstants.statusWaitingUser,
      note: '后处理已返回，等待用户确认是否标记完成或继续修订。',
      extra: <String, Object?>{'output_paths': mergedOutputs},
    );
    return <String, Object?>{
      'ok': true,
      'response': _resultAsResponse(result),
      'output_paths': result.writtenPaths,
      'tool_names': _toolNamesFromExecutedTools(result.executedTools),
    };
  }

  Future<JsonMap> runNextWorkflowTaskPostprocessOnce(
    ProjectDescriptor project,
    AppSettings settings, {
    JsonMap agent = const <String, Object?>{},
  }) async {
    // 中文注释: 自动选择下一条等待后处理任务，并只跑一次后处理。
    final task = await nextWorkflowPostprocessTask(project);
    if (task.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': '当前没有可后处理任务。',
        'response': <String, Object?>{},
      };
    }
    return runWorkflowTaskPostprocessOnce(
      project,
      settings,
      <String, Object?>{
        'relative_path': ValueReaders.stringValue(task['relative_path']),
      },
      agent: agent,
    );
  }

  Future<JsonMap> completeWorkflowTaskAndRunNext(
    ProjectDescriptor project,
    AppSettings settings,
    JsonMap selector, {
    JsonMap agent = const <String, Object?>{},
  }) async {
    // 中文注释: 完成当前任务后立刻安全推进下一任务一个单步。
    final completion = await _taskRepository.transitionTask(
      project,
      selector,
      TaskRuntimeConstants.statusSucceeded,
      note: '用户确认任务完成，并请求继续下一任务。',
    );
    if (!ValueReaders.boolValue(completion['ok'])) {
      return <String, Object?>{
        'ok': false,
        'error': ValueReaders.stringValue(
          completion['error'],
          'Task completion failed.',
        ),
        'completion': completion,
        'next_result': <String, Object?>{},
      };
    }
    final nextTask = await nextWorkflowTask(project);
    if (nextTask.isEmpty) {
      return <String, Object?>{
        'ok': true,
        'completion': completion,
        'next_result': <String, Object?>{},
        'stop_reason': 'no_runnable_task',
      };
    }
    final nextResult = await runWorkflowTaskOnce(
      project,
      settings,
      <String, Object?>{
        'relative_path': ValueReaders.stringValue(nextTask['relative_path']),
      },
      agent: agent,
    );
    return <String, Object?>{
      'ok': ValueReaders.boolValue(nextResult['ok']),
      'error': ValueReaders.stringValue(nextResult['error']),
      'completion': completion,
      'next_task': nextTask,
      'next_result': nextResult,
    };
  }

  Future<JsonMap> acceptRevisionTask(
    ProjectDescriptor project,
    JsonMap selector,
  ) async {
    // 中文注释: 接受修复结果只更新任务状态和已接受的 diff 路径。
    final task = await _taskRepository.loadTask(project, selector);
    if (task.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Task not found.',
        'relative_path': '',
      };
    }
    if (ValueReaders.stringValue(task['task_type']) != 'revision') {
      return <String, Object?>{
        'ok': false,
        'error': 'Only revision tasks can be accepted here.',
        'relative_path': ValueReaders.stringValue(task['relative_path']),
      };
    }
    return _taskRepository.transitionTask(
      project,
      selector,
      TaskRuntimeConstants.statusSucceeded,
      note: '用户接受修复结果。',
      extra: <String, Object?>{
        'accepted_revision_diff_path': ValueReaders.stringValue(
          task['revision_diff_path'],
        ),
      },
    );
  }

  Future<JsonMap> rollbackRevisionTask(
    ProjectDescriptor project,
    JsonMap selector,
  ) async {
    // 中文注释: 回滚依据修复 diff 中记录的 backup_path -> target_path 配对直接恢复文件。
    final task = await _taskRepository.loadTask(project, selector);
    if (task.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Task not found.',
        'relative_path': '',
      };
    }
    if (ValueReaders.stringValue(task['task_type']) != 'revision') {
      return <String, Object?>{
        'ok': false,
        'error': 'Only revision tasks can be rolled back here.',
        'relative_path': ValueReaders.stringValue(task['relative_path']),
      };
    }
    final diffPath = ValueReaders.stringValue(task['revision_diff_path']).trim();
    if (diffPath.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Revision diff path is missing.',
        'relative_path': ValueReaders.stringValue(task['relative_path']),
      };
    }
    final report = await _taskRepository.loadRecord(
      project,
      diffPath.replaceAll(RegExp(r'\.md$'), '.json'),
    );
    if (report.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Revision diff not found.',
        'relative_path': ValueReaders.stringValue(task['relative_path']),
      };
    }
    final restored = <String>[];
    final failed = <JsonMap>[];
    for (final pair in ValueReaders.mapList(report['pairs'])) {
      final backupPath = ValueReaders.stringValue(pair['backup_path']).trim();
      final targetPath = ValueReaders.stringValue(pair['target_path']).trim();
      if (backupPath.isEmpty || targetPath.isEmpty) {
        failed.add(<String, Object?>{
          'target_path': targetPath,
          'backup_path': backupPath,
          'error': 'Missing backup or target path.',
        });
        continue;
      }
      final backupContent =
          await _taskRepository.readTextFile(project, backupPath) ?? '';
      if (backupContent.isEmpty) {
        failed.add(<String, Object?>{
          'target_path': targetPath,
          'backup_path': backupPath,
          'error': 'Backup file not found.',
        });
        continue;
      }
      await _taskRepository.writeTextFile(project, targetPath, backupContent);
      restored.add(targetPath);
    }
    final transition = await _taskRepository.transitionTask(
      project,
      selector,
      TaskRuntimeConstants.statusCancelled,
      note: '用户根据修复 Diff 回滚修复。',
      extra: <String, Object?>{
        'rollback_result': <String, Object?>{
          'ok': failed.isEmpty && restored.isNotEmpty,
          'restored_paths': restored,
          'failed': failed,
        },
        'rolled_back_revision_diff_path': diffPath,
      },
    );
    return <String, Object?>{
      'ok': failed.isEmpty && restored.isNotEmpty,
      'relative_path': ValueReaders.stringValue(task['relative_path']),
      'rollback': <String, Object?>{
        'ok': failed.isEmpty && restored.isNotEmpty,
        'restored_paths': restored,
        'failed': failed,
      },
      'transition': transition,
      'warning': failed.isEmpty ? '' : '部分或全部目标回滚失败。',
    };
  }

  Future<JsonMap> transitionWorkflowTask(
    ProjectDescriptor project,
    JsonMap selector,
    String status, {
    String note = '',
    JsonMap extra = const <String, Object?>{},
  }) {
    // 中文注释: 手动暂停、恢复、重试、取消等动作统一走共享状态迁移入口。
    return _taskRepository.transitionTask(
      project,
      selector,
      status,
      note: note,
      extra: extra,
    );
  }

  Future<JsonMap> buildLongTaskRevisionPlan(
    ProjectDescriptor project,
    String command, {
    String runPath = '',
    JsonMap arguments = const <String, Object?>{},
  }) async {
    // 中文注释: 修订计划先输出补丁合同，真正落盘由 applyLongTaskRevisionPlan 处理。
    JsonMap record = const <String, Object?>{};
    if (runPath.trim().isNotEmpty) {
      record = await _taskRepository.loadRecord(project, runPath);
    } else {
      final recentRuns = await listLongTaskRuns(project, limit: 1);
      if (recentRuns.isNotEmpty) {
        record = recentRuns.first;
      }
    }
    return _buildLongTaskRevisionPlanUseCase.execute(
      record,
      await listWorkflowTasks(project),
      command,
      arguments: arguments,
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  Future<JsonMap> applyLongTaskRevisionPlan(
    ProjectDescriptor project,
    JsonMap revision,
  ) async {
    // 中文注释: 修订补丁应用阶段只负责真正把新任务与更新后的任务文件写回项目。
    final applied = _longTaskRevisionApplyService.applyRevisionPlan(
      await listWorkflowTasks(project),
      revision,
      createdAt: DateTime.now().toIso8601String(),
    );
    if (!ValueReaders.boolValue(applied['ok'])) {
      return applied;
    }
    final tasks = await _taskRepository.saveTasks(
      project,
      ValueReaders.objectList(applied['tasks']),
    );
    return <String, Object?>{
      'ok': true,
      'tasks': tasks,
      'changed_paths': ValueReaders.stringList(applied['changed_paths']),
      'changed_task_ids': ValueReaders.stringList(applied['changed_task_ids']),
    };
  }

  Future<JsonMap> _templateMap(ProjectDescriptor project) async {
    // 中文注释: 模板映射给任务提示和后处理提示复用，避免上层反复组装。
    final result = <String, Object?>{};
    final templates = await _promptTemplateService.listMergedTemplates(project);
    for (final template in templates) {
      final id = ValueReaders.stringValue(template['id']).trim();
      if (id.isNotEmpty) {
        result[id] = ValueReaders.stringValue(template['content']);
      }
    }
    return result;
  }

  JsonMap _resultAsResponse(DraftGenerationResult result) {
    // 中文注释: 任务运行结果折叠成旧 AppState 风格字典，方便 UI/CLI 沿用同一渲染口径。
    return <String, Object?>{
      'content': result.draftMarkdown,
      'tool_calls': result.executedTools,
      'waiting_for_user_choice': result.waitingForUserChoice,
      'selected_paths': result.selectedPaths,
      'context_pack_summary': ValueReaders.stringValue(result.contextPack['summary']),
      'prompt_preview_markdown': result.prompt,
    };
  }

  JsonMap _appendQueueStep(
    JsonMap record,
    JsonMap task,
    JsonMap result, {
    required int index,
  }) {
    // 中文注释: 队列记录只保留审计摘要，不重复持久化大段正文和上下文包。
    final next = ValueReaders.deepCopyMap(record);
    final steps = ValueReaders.objectList(next['steps']);
    steps.add(<String, Object?>{
      'index': index,
      'task_id': ValueReaders.stringValue(task['id']),
      'task_title': ValueReaders.stringValue(task['title']),
      'task_relative_path': ValueReaders.stringValue(task['relative_path']),
      'task_status_after': ValueReaders.stringValue(task['status']),
      'ok': ValueReaders.boolValue(result['ok']),
      'error': ValueReaders.stringValue(result['error']),
      'output_paths': ValueReaders.stringList(result['output_paths']),
      'created_at': DateTime.now().toIso8601String(),
    });
    next['steps'] = steps;
    next['completed_steps'] = steps.length;
    next['last_task_id'] = ValueReaders.stringValue(task['id']);
    next['last_task_relative_path'] = ValueReaders.stringValue(task['relative_path']);
    next['updated_at'] = DateTime.now().toIso8601String();
    return next;
  }

  List<String> _mergePaths(List<String> left, List<String> right) {
    // 中文注释: 输出路径合并后保持先前顺序，避免后处理覆盖正文阶段的重要定位。
    final result = <String>[...left];
    for (final item in right) {
      if (!result.contains(item)) {
        result.add(item);
      }
    }
    return result;
  }

  List<String> _toolNamesFromExecutedTools(List<Object?> executedTools) {
    // 中文注释: 紧凑工具名摘要供后处理结果页和 CLI 输出使用。
    final result = <String>[];
    for (final rawTool in executedTools) {
      final tool = ValueReaders.mapValue(rawTool);
      final name = ValueReaders.stringValue(tool['name']).trim();
      if (name.isNotEmpty && !result.contains(name)) {
        result.add(name);
      }
    }
    return result;
  }

  Future<JsonMap> _saveRevisionDiffIfNeeded(
    ProjectDescriptor project,
    JsonMap task,
    List<Object?> executedTools,
  ) async {
    // 中文注释: 修复 diff 报告从本轮工具结果抽取 backup_path/relative_path 配对，保障可回滚链条。
    final pairs = <JsonMap>[];
    for (final rawTool in executedTools) {
      final tool = ValueReaders.mapValue(rawTool);
      final result = ValueReaders.mapValue(tool['result']);
      final backupPath = ValueReaders.stringValue(result['backup_path']).trim();
      final targetPath = ValueReaders.stringValue(result['relative_path']).trim();
      if (backupPath.isEmpty || targetPath.isEmpty) {
        continue;
      }
      pairs.add(
        _revisionDiffPreviewService.buildPair(
          targetPath: targetPath,
          backupPath: backupPath,
          beforeText:
              await _taskRepository.readTextFile(project, backupPath) ?? '',
          afterText:
              await _taskRepository.readTextFile(project, targetPath) ?? '',
        ),
      );
    }
    if (pairs.isEmpty) {
      return <String, Object?>{};
    }
    final safeId = _longTaskPathPolicyService.safeId(
      ValueReaders.stringValue(task['id']),
      fallbackPrefix: 'revision',
    );
    final jsonPath =
        'tracking/revision_diffs/$safeId.${DateTime.now().microsecondsSinceEpoch}.json';
    final markdownPath = jsonPath.replaceAll('.json', '.md');
    final report = <String, Object?>{
      'schema_version': 1,
      'kind': 'revision_diff',
      'task_id': ValueReaders.stringValue(task['id']),
      'task_title': ValueReaders.stringValue(task['title']),
      'task_relative_path': ValueReaders.stringValue(task['relative_path']),
      'summary': _revisionDiffPreviewService.summaryText(pairs),
      'pairs': pairs,
      'created_at': DateTime.now().toIso8601String(),
    };
    await _taskRepository.saveRecord(project, jsonPath, report);
    await _taskRepository.writeTextFile(
      project,
      markdownPath,
      _revisionDiffMarkdownRenderer.renderMarkdown(report),
    );
    return <String, Object?>{
      'ok': true,
      'relative_path': markdownPath,
      'json_path': jsonPath,
      'report': report,
      'changed_paths': <Object?>[jsonPath, markdownPath],
    };
  }

  static BuildLongTaskPlanUseCase _defaultBuildLongTaskPlanUseCase(
    LongTaskModeService modeService,
    LongTaskPathPolicyService pathPolicyService,
  ) {
    final taskFactoryService = LongTaskTaskFactoryService(
      modeService: modeService,
      pathPolicyService: pathPolicyService,
    );
    return BuildLongTaskPlanUseCase(
      taskFactoryService: taskFactoryService,
      planRecordService: LongTaskPlanRecordService(modeService: modeService),
      changedPathsService: LongTaskPlanChangedPathsService(),
      markdownRenderer: LongTaskPlanMarkdownRenderer(),
    );
  }

  static StartLongTaskRunUseCase _defaultStartLongTaskRunUseCase(
    LongTaskModeService modeService,
    LongTaskPathPolicyService pathPolicyService,
  ) {
    final strategyService = LongTaskModeStrategyService(modeService: modeService);
    return StartLongTaskRunUseCase(
      planIdentityService: LongTaskRunPlanIdentityService(
        modeService: modeService,
      ),
      runRecordService: LongTaskRunRecordService(
        modeService: modeService,
        strategyService: strategyService,
        optionService: LongTaskRunOptionService(),
        taskSummaryService: LongTaskTaskSummaryService(),
      ),
      runPathService: LongTaskRunPathService(pathPolicyService: pathPolicyService),
    );
  }

  static BuildLongTaskSchedulerSnapshotUseCase
  _defaultBuildLongTaskSchedulerSnapshotUseCase(
    LongTaskModeService modeService,
    LongTaskPathPolicyService pathPolicyService,
    TaskDefinitionService taskDefinitionService,
  ) {
    final taskSelectionService = TaskSelectionService(
      taskDefinitionService: taskDefinitionService,
    );
    final strategyService = LongTaskModeStrategyService(modeService: modeService);
    final profileService = LongTaskControllerProfileService(
      modeService: modeService,
      strategyService: strategyService,
    );
    final unattendedStrategyService = LongTaskUnattendedStrategyService(
      modeService: modeService,
      strategyService: strategyService,
      profileService: profileService,
    );
    final taskSummaryService = LongTaskTaskSummaryService();
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
    return BuildLongTaskSchedulerSnapshotUseCase(
      schedulerTickPlanService: schedulerTickPlanService,
      batchOptionService: LongTaskBatchOptionService(),
      schedulerMarkdownRenderer: LongTaskSchedulerMarkdownRenderer(),
    );
  }

  static BuildLongTaskPromptUseCase _defaultBuildLongTaskPromptUseCase(
    LongTaskModeService modeService,
    LongTaskPathPolicyService pathPolicyService,
  ) {
    final strategyService = LongTaskModeStrategyService(modeService: modeService);
    final contextService = LongTaskTransactionContextService(
      modeService: modeService,
      pathPolicyService: pathPolicyService,
    );
    final contractService = LongTaskTransactionContractService(
      modeService: modeService,
      pathPolicyService: pathPolicyService,
    );
    return BuildLongTaskPromptUseCase(
      transactionService: LongTaskTaskTransactionService(
        modeService: modeService,
        strategyService: strategyService,
        contextService: contextService,
        contractService: contractService,
      ),
      promptRenderer: LongTaskTaskPromptRenderer(
        contractService: contractService,
      ),
    );
  }

  static LongTaskPostprocessTransactionService
  _defaultPostprocessTransactionService(
    LongTaskModeService modeService,
    LongTaskPathPolicyService pathPolicyService,
  ) {
    return LongTaskPostprocessTransactionService(
      modeService: modeService,
      pathPolicyService: pathPolicyService,
      contextService: LongTaskTransactionContextService(
        modeService: modeService,
        pathPolicyService: pathPolicyService,
      ),
    );
  }

  static LongTaskPostprocessPromptRenderer _defaultPostprocessPromptRenderer(
    LongTaskPathPolicyService pathPolicyService,
  ) {
    return LongTaskPostprocessPromptRenderer(
      contractService: LongTaskTransactionContractService(
        modeService: LongTaskModeService(),
        pathPolicyService: pathPolicyService,
      ),
    );
  }

  static LongTaskFinishDispositionService _defaultFinishDispositionService(
    LongTaskModeService modeService,
  ) {
    final strategyService = LongTaskModeStrategyService(modeService: modeService);
    return LongTaskFinishDispositionService(
      profileService: LongTaskControllerProfileService(
        modeService: modeService,
        strategyService: strategyService,
      ),
    );
  }

  static PrepareChapterAtomicExecutionUseCase _defaultPrepareExecutionUseCase() {
    return PrepareChapterAtomicExecutionUseCase(
      executionBuilderService: ChapterAtomicExecutionBuilderService(
        promptBuilderService: ChapterAtomicPromptBuilderService(
          taskDefinitionService: TaskDefinitionService(),
        ),
        intentService: ChapterAtomicIntentService(),
        outputPathService: ChapterAtomicOutputPathService(),
        stepStateService: ChapterAtomicStepStateService(),
        eventService: ChapterAtomicEventService(),
        contextAssemblerService: ContextAssemblerService(
          budgetService: ContextBudgetService(),
          staticSectionService: ContextStaticSectionService(
            projectPromptContract: ProjectPromptContract(),
          ),
          projectFileSectionService: ContextProjectFileSectionService(),
        ),
        executionPlanService: TaskExecutionPlanService(
          taskDefinitionService: TaskDefinitionService(),
        ),
      ),
    );
  }

  static BuildLongTaskRevisionPlanUseCase
  _defaultBuildLongTaskRevisionPlanUseCase(
    LongTaskModeService modeService,
    LongTaskPathPolicyService pathPolicyService,
  ) {
    return BuildLongTaskRevisionPlanUseCase(
      revisionPlanService: LongTaskRevisionPlanService(
        dynamicTaskFactoryService: LongTaskDynamicTaskFactoryService(
          modeService: modeService,
          pathPolicyService: pathPolicyService,
        ),
      ),
    );
  }
}
