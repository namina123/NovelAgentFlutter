import 'dart:async';

import 'package:novel_agent_core/novel_agent_core.dart';

import '../runtime/long_task_watchdog.dart';
import '../runtime/project_long_task_run_registry_sync_service.dart';
import '../storage/project_task_repository.dart';
import 'project_long_task_chapter_queue_runtime_service.dart';
import 'project_long_task_checkpoint_action_service.dart';
import 'project_task_queue_runtime_option_resolver.dart';
import 'project_workflow_task_selection_service.dart';

typedef WorkflowTaskOnceRunner =
    Future<JsonMap> Function(
      ProjectDescriptor project,
      AppSettings settings,
      JsonMap selector, {
      JsonMap runRecord,
      JsonMap agent,
      JsonMap options,
      DraftGenerationCancellationToken? cancellationToken,
    });

class ProjectWorkflowQueueRuntimeService {
  ProjectWorkflowQueueRuntimeService({
    required ProjectTaskRepository taskRepository,
    required TaskDefinitionService taskDefinitionService,
    required TaskSelectionService taskSelectionService,
    required ProjectWorkflowTaskSelectionService workflowTaskSelectionService,
    required ProjectLongTaskChapterQueueRuntimeService
    chapterQueueRuntimeService,
    required LongTaskModeService longTaskModeService,
    required LongTaskPathPolicyService longTaskPathPolicyService,
    required BuildLongTaskPlanUseCase buildLongTaskPlanUseCase,
    required LongTaskRunPathService longTaskRunPathService,
    required BuildLongTaskSchedulerSnapshotUseCase
    buildLongTaskSchedulerSnapshotUseCase,
    required LongTaskRunLifecycleService lifecycleService,
    required StartLongTaskRunUseCase startLongTaskRunUseCase,
    required TaskQueueOptionService taskQueueOptionService,
    required TaskQueueStopPolicyService taskQueueStopPolicyService,
    required ProjectTaskQueueRuntimeOptionResolver
    taskQueueRuntimeOptionResolver,
    required LongTaskFinishDispositionService finishDispositionService,
    required LongTaskRunStepRecorderService longTaskRunStepRecorderService,
    required ProjectLongTaskCheckpointActionService checkpointActionService,
    WorkflowTaskOnceRunner? workflowTaskOnceRunner,
    LongTaskWatchdog? longTaskWatchdog,
    ProjectLongTaskRunRegistrySyncService? longTaskRunRegistrySyncService,
    TaskQueuePreflightService? taskQueuePreflightService,
  }) : _taskRepository = taskRepository,
       _taskDefinitionService = taskDefinitionService,
       _taskSelectionService = taskSelectionService,
       _workflowTaskSelectionService = workflowTaskSelectionService,
       _chapterQueueRuntimeService = chapterQueueRuntimeService,
       _longTaskModeService = longTaskModeService,
       _longTaskPathPolicyService = longTaskPathPolicyService,
       _buildLongTaskPlanUseCase = buildLongTaskPlanUseCase,
       _longTaskRunPathService = longTaskRunPathService,
       _buildLongTaskSchedulerSnapshotUseCase =
           buildLongTaskSchedulerSnapshotUseCase,
       _lifecycleService = lifecycleService,
       _startLongTaskRunUseCase = startLongTaskRunUseCase,
       _taskQueueOptionService = taskQueueOptionService,
       _taskQueueStopPolicyService = taskQueueStopPolicyService,
       _taskQueueRuntimeOptionResolver = taskQueueRuntimeOptionResolver,
       _finishDispositionService = finishDispositionService,
       _longTaskRunStepRecorderService = longTaskRunStepRecorderService,
       _checkpointActionService = checkpointActionService,
       _taskQueuePreflightService =
           taskQueuePreflightService ??
           TaskQueuePreflightService(
             optionService: taskQueueOptionService,
             taskSelectionService: taskSelectionService,
             taskDefinitionService: taskDefinitionService,
           ),
       _longTaskRunRegistrySyncService = longTaskRunRegistrySyncService,
       _runWorkflowTaskOnce = workflowTaskOnceRunner,
       _longTaskWatchdog = longTaskWatchdog;

  final ProjectTaskRepository _taskRepository;
  final TaskDefinitionService _taskDefinitionService;
  final TaskSelectionService _taskSelectionService;
  final ProjectWorkflowTaskSelectionService _workflowTaskSelectionService;
  final ProjectLongTaskChapterQueueRuntimeService _chapterQueueRuntimeService;
  final LongTaskModeService _longTaskModeService;
  final LongTaskPathPolicyService _longTaskPathPolicyService;
  final BuildLongTaskPlanUseCase _buildLongTaskPlanUseCase;
  final LongTaskRunPathService _longTaskRunPathService;
  final BuildLongTaskSchedulerSnapshotUseCase
  _buildLongTaskSchedulerSnapshotUseCase;
  final LongTaskRunLifecycleService _lifecycleService;
  final StartLongTaskRunUseCase _startLongTaskRunUseCase;
  final TaskQueueOptionService _taskQueueOptionService;
  final TaskQueueStopPolicyService _taskQueueStopPolicyService;
  final ProjectTaskQueueRuntimeOptionResolver _taskQueueRuntimeOptionResolver;
  final LongTaskFinishDispositionService _finishDispositionService;
  final LongTaskRunStepRecorderService _longTaskRunStepRecorderService;
  final ProjectLongTaskCheckpointActionService _checkpointActionService;
  final TaskQueuePreflightService _taskQueuePreflightService;
  final ProjectLongTaskRunRegistrySyncService? _longTaskRunRegistrySyncService;
  WorkflowTaskOnceRunner? _runWorkflowTaskOnce;
  final LongTaskWatchdog? _longTaskWatchdog;
  // 中文注释: 同一项目同一时刻只允许一条队列在跑，二次进入直接返回 already_running。
  final Set<String> _inFlightProjects = <String>{};

  void bindWorkflowTaskOnceRunner(WorkflowTaskOnceRunner runner) {
    // 中文注释: 单步执行回调用构造后绑定，避免 queue service 反向持有 runtime 的初始化时机。
    _runWorkflowTaskOnce = runner;
  }

  Future<JsonMap> createLongTaskWorkflow(
    ProjectDescriptor project,
    String mode, {
    JsonMap options = const <String, Object?>{},
  }) async {
    // 中文注释: 长任务开局只负责计划与任务物化，避免 runtime 再吞一层装配策略。
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
    final fullTasks = ValueReaders.mapList(built['tasks'])
        .map(
          (task) => ValueReaders.deepCopyMap(task)
            ..['relative_path'] = _longTaskRunPathService.taskPathForNewTask(
              task,
            ),
        )
        .toList(growable: false);
    final materialized = _chapterQueueRuntimeService
        .materializeInitialPlanWindow(
          mode,
          ValueReaders.mapValue(built['plan']),
          fullTasks,
        );
    final tasks = ValueReaders.mapList(
      materialized['tasks'],
    ).map(ValueReaders.deepCopyMap).toList(growable: false);
    await _taskRepository.saveTasks(project, tasks);
    await _taskRepository.saveRecord(
      project,
      planPath,
      ValueReaders.mapValue(materialized['plan']),
    );
    await _taskRepository.writeTextFile(
      project,
      planMarkdownPath,
      ValueReaders.stringValue(materialized['markdown']),
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
    // 中文注释: 列表只做仓储读取与排序，不在 queue 层再写新的规则。
    final tasks = await _taskRepository.listTasks(project, filters: filters);
    return _taskSelectionService.sortTasks(tasks, filters: filters);
  }

  Future<JsonMap> nextWorkflowTask(
    ProjectDescriptor project, {
    JsonMap filters = const <String, Object?>{},
  }) async {
    // 中文注释: 下一任务选择只负责调度，不承担执行细节。
    var tasks = _workflowTaskSelectionService.workflowScopedTasks(
      await listWorkflowTasks(project, filters: filters),
    );
    var primaryTasks = _workflowTaskSelectionService.workflowPrimaryTasks(
      tasks,
    );
    var nextTask = _workflowTaskSelectionService.nextRunnablePrimaryTask(
      primaryTasks: primaryTasks,
      allTasks: tasks,
    );
    if (nextTask.isNotEmpty) {
      return nextTask;
    }
    final materialized = await _chapterQueueRuntimeService
        .ensureMaterializedQueueForNextTask(project, tasks);
    if (!ValueReaders.boolValue(materialized['ok'])) {
      return <String, Object?>{};
    }
    if (ValueReaders.boolValue(materialized['materialized'])) {
      tasks = _workflowTaskSelectionService.workflowScopedTasks(
        await listWorkflowTasks(project, filters: filters),
      );
      primaryTasks = _workflowTaskSelectionService.workflowPrimaryTasks(tasks);
      nextTask = _workflowTaskSelectionService.nextRunnablePrimaryTask(
        primaryTasks: primaryTasks,
        allTasks: tasks,
      );
      if (nextTask.isNotEmpty) {
        return nextTask;
      }
    }
    nextTask = _taskSelectionService.nextRunnableTaskFromTasks(tasks);
    if (nextTask.isNotEmpty) {
      return nextTask;
    }
    final recoveredTask = await _recoverResumeDispatchRunningTask(
      project,
      tasks,
    );
    if (recoveredTask.isNotEmpty) {
      return recoveredTask;
    }
    return const <String, Object?>{};
  }

  Future<JsonMap> _nextWorkflowQueueTask(
    ProjectDescriptor project, {
    JsonMap filters = const <String, Object?>{},
  }) async {
    // 中文注释: 队列推进保留 deferred checkpoint follow-up 的解锁能力，避免主链被自动衍生任务卡住后提前终止。
    var tasks = _workflowTaskSelectionService.workflowScopedTasks(
      await listWorkflowTasks(project, filters: filters),
    );
    var primaryTasks = _workflowTaskSelectionService.workflowPrimaryTasks(
      tasks,
    );
    var nextTask = _workflowTaskSelectionService.nextRunnablePrimaryTask(
      primaryTasks: primaryTasks,
      allTasks: tasks,
    );
    if (nextTask.isNotEmpty) {
      return nextTask;
    }
    final materialized = await _chapterQueueRuntimeService
        .ensureMaterializedQueueForNextTask(project, tasks);
    if (!ValueReaders.boolValue(materialized['ok'])) {
      return <String, Object?>{};
    }
    if (ValueReaders.boolValue(materialized['materialized'])) {
      tasks = _workflowTaskSelectionService.workflowScopedTasks(
        await listWorkflowTasks(project, filters: filters),
      );
      primaryTasks = _workflowTaskSelectionService.workflowPrimaryTasks(tasks);
      nextTask = _workflowTaskSelectionService.nextRunnablePrimaryTask(
        primaryTasks: primaryTasks,
        allTasks: tasks,
      );
      if (nextTask.isNotEmpty) {
        return nextTask;
      }
    }
    final deferredFollowupTask = _workflowTaskSelectionService
        .nextBlockingDeferredCheckpointFollowupTask(
          tasks,
          primaryTasks: primaryTasks,
        );
    if (deferredFollowupTask.isNotEmpty) {
      return deferredFollowupTask;
    }
    return _recoverResumeDispatchRunningTask(project, primaryTasks);
  }

  Future<JsonMap> runNextWorkflowTaskOnce(
    ProjectDescriptor project,
    AppSettings settings, {
    JsonMap agent = const <String, Object?>{},
  }) async {
    // 中文注释: 单步推进只是一层轻包装，核心执行仍由主 runtime 处理。
    final task = await nextWorkflowTask(project);
    if (task.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': '当前没有可运行任务。',
        'response': <String, Object?>{},
      };
    }
    final runner = _runWorkflowTaskOnce;
    if (runner == null) {
      return <String, Object?>{
        'ok': false,
        'error': 'Workflow task runner is unavailable.',
        'response': <String, Object?>{},
      };
    }
    return runner(project, settings, <String, Object?>{
      'relative_path': ValueReaders.stringValue(task['relative_path']),
    }, agent: agent);
  }

  Future<JsonMap> taskQueuePreflight(
    ProjectDescriptor project, {
    JsonMap options = const <String, Object?>{},
  }) async {
    // 中文注释: 预检只读取任务与运行摘要，保留“能不能跑、为什么停”的解释性。
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
    // 中文注释: 队列运行记录统一按约定目录读取。
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
    // 中文注释: 长任务运行记录统一按约定目录读取。
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
    // 中文注释: 调度计划只做 snapshot 读取与投影，不在这里新造策略。
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
      await _currentWorkflowTasks(project),
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
    // 中文注释: 暂停只改运行记录，不隐式改任务文件状态。
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
    final savedRecord = await _taskRepository.saveRecord(
      project,
      relativePath,
      updated,
    );
    await _syncLongTaskRunRecord(project, savedRecord);
    final schedulerSnapshot = _buildLongTaskSchedulerSnapshotUseCase.execute(
      savedRecord,
      await _currentWorkflowTasks(project),
      options: ValueReaders.mapValue(savedRecord['options']),
    );
    final runCenterContract = _runCenterContractFromSchedulerSnapshot(
      schedulerSnapshot,
    );
    return <String, Object?>{
      'ok': true,
      'record': savedRecord,
      'run_center_contract': runCenterContract,
      'scheduler_snapshot': <String, Object?>{
        ...schedulerSnapshot,
        'run_center_contract': runCenterContract,
      },
    };
  }

  Future<JsonMap> resumeLongTaskRun(
    ProjectDescriptor project,
    AppSettings settings,
    String relativePath, {
    JsonMap options = const <String, Object?>{},
    JsonMap agent = const <String, Object?>{},
  }) async {
    // 中文注释: 恢复长任务直接复用队列入口，不在这里增加第二条恢复逻辑。
    await _autoConfirmCheckpointBeforeResumeIfPossible(project, relativePath);
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

  Future<JsonMap> stopLongTaskRun(
    ProjectDescriptor project,
    String relativePath, {
    String note = '用户请求停止长任务。',
  }) async {
    // 中文注释: 停止只改运行记录状态，不额外改写任务本身。
    final record = await _taskRepository.loadRecord(project, relativePath);
    if (record.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Long task run not found.',
      };
    }
    final updated = _lifecycleService.finishRecord(
      record,
      reason: 'manual_stop',
      note: note,
    );
    final savedRecord = await _taskRepository.saveRecord(
      project,
      relativePath,
      updated,
    );
    await _syncLongTaskRunRecord(project, savedRecord);
    final schedulerSnapshot = _buildLongTaskSchedulerSnapshotUseCase.execute(
      savedRecord,
      await _currentWorkflowTasks(project),
      options: ValueReaders.mapValue(savedRecord['options']),
    );
    final runCenterContract = _runCenterContractFromSchedulerSnapshot(
      schedulerSnapshot,
    );
    return <String, Object?>{
      'ok': true,
      'record': savedRecord,
      'run_center_contract': runCenterContract,
      'scheduler_snapshot': <String, Object?>{
        ...schedulerSnapshot,
        'run_center_contract': runCenterContract,
      },
    };
  }

  Future<JsonMap> runWorkflowTaskQueue(
    ProjectDescriptor project,
    AppSettings settings, {
    JsonMap options = const <String, Object?>{},
    JsonMap agent = const <String, Object?>{},
  }) async {
    // 中文注释: 队列入口先收并发守卫与 watchdog 生命周期，真正执行收在 _runWorkflowTaskQueueBody。
    final projectId = project.id;
    if (!_inFlightProjects.add(projectId)) {
      return <String, Object?>{
        'ok': false,
        'error': 'already_running',
        'project_id': projectId,
        'message': '该项目已有长任务正在运行，请等待当前批次结束或先停止。',
      };
    }
    final watchdog = _longTaskWatchdog;
    var startedWatchdogHere = false;
    try {
      if (watchdog != null && !watchdog.isWatchdogRunning) {
        watchdog.start();
        startedWatchdogHere = true;
      }
      return await _runWorkflowTaskQueueBody(
        project,
        settings,
        options: options,
        agent: agent,
      );
    } finally {
      if (startedWatchdogHere) {
        final activeWatchdog = _longTaskWatchdog;
        if (activeWatchdog != null) {
          await activeWatchdog.stop();
        }
      }
      _inFlightProjects.remove(projectId);
    }
  }

  Future<JsonMap> _runWorkflowTaskQueueBody(
    ProjectDescriptor project,
    AppSettings settings, {
    JsonMap options = const <String, Object?>{},
    JsonMap agent = const <String, Object?>{},
  }) async {
    // 中文注释: 受控连续运行在这里收口，只编排队列，不再把其它调度职责往回塞。
    final resolvedOptions = await _taskQueueRuntimeOptionResolver.resolve(
      project,
      options: options,
    );
    final cleanOptions = _taskQueueOptionService.normalizeOptions(
      resolvedOptions,
    );
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
      resolvedOptions['continue_long_task_run_path'],
      ValueReaders.stringValue(resolvedOptions['long_task_run_path']),
    ).trim();
    JsonMap longRunRecord = const <String, Object?>{};
    final workflowTasks = await _currentWorkflowTasks(project);
    if (longRunPath.isEmpty) {
      final inferredStart = _startLongTaskRunUseCase.execute(
        workflowTasks,
        options: cleanOptions,
      );
      final inferredPath = ValueReaders.stringValue(
        inferredStart['relative_path'],
      );
      if (inferredPath.isNotEmpty) {
        final existing = await _taskRepository.loadRecord(
          project,
          inferredPath,
        );
        if (existing.isNotEmpty) {
          longRunPath = inferredPath;
          longRunRecord = _lifecycleService.resumeRecord(existing);
          longRunRecord = await _taskRepository.saveRecord(
            project,
            longRunPath,
            longRunRecord,
          );
          await _syncLongTaskRunRecord(project, longRunRecord);
        }
      }
      if (longRunRecord.isEmpty) {
        longRunPath = ValueReaders.stringValue(inferredStart['relative_path']);
        longRunRecord = ValueReaders.mapValue(inferredStart['record']);
        longRunRecord = await _taskRepository.saveRecord(
          project,
          longRunPath,
          longRunRecord,
        );
        await _syncLongTaskRunRecord(project, longRunRecord);
      }
    } else {
      longRunRecord = await _taskRepository.loadRecord(project, longRunPath);
      if (longRunRecord.isEmpty) {
        // 中文注释: 显式恢复路径下找不到运行记录时如实返回，不再静默跑空队列。
        queueRecord = ValueReaders.deepCopyMap(queueRecord)
          ..['status'] = _taskQueueStopPolicyService.statusForReason(
            'record_missing',
          )
          ..['stop_reason'] = 'record_missing'
          ..['stop_note'] = '未找到要恢复的长任务运行记录。'
          ..['updated_at'] = DateTime.now().toIso8601String();
        await _taskRepository.saveRecord(project, queuePath, queueRecord);
        return <String, Object?>{
          'ok': false,
          'error': 'long_task_run_record_missing',
          'continue_long_task_run_path': longRunPath,
          'message': '未找到要恢复的长任务运行记录，可能已被删除或移动。',
          'relative_path': queuePath,
          'record': queueRecord,
          'queue_record': queueRecord,
          'response': <String, Object?>{},
          'output_paths': const <Object?>[],
          'changed_paths': const <Object?>[],
        };
      }
      longRunRecord = _lifecycleService.resumeRecord(longRunRecord);
      longRunRecord = await _taskRepository.saveRecord(
        project,
        longRunPath,
        longRunRecord,
      );
      await _syncLongTaskRunRecord(project, longRunRecord);
    }

    final runner = _runWorkflowTaskOnce;
    if (runner == null) {
      return <String, Object?>{
        'ok': false,
        'error': 'Workflow task runner is unavailable.',
        'response': <String, Object?>{},
      };
    }
    final maxStepsPerBatch = ValueReaders.intValue(
      cleanOptions['max_steps'],
      3,
    );
    final maxSecondsPerBatch = ValueReaders.intValue(
      cleanOptions['max_seconds'],
      -1,
    );
    final unattended = ValueReaders.boolValue(cleanOptions['unattended']);
    final maxBatches = ValueReaders.intValue(cleanOptions['max_batches'], 50);
    final maxTotalSeconds = ValueReaders.intValue(
      cleanOptions['max_total_seconds'],
      3600,
    );
    final runStartedAt = DateTime.now();
    var stepsRun = 0;
    var batchesRun = 0;
    var stopReason = '';
    var stopNote = '';
    JsonMap lastResult = const <String, Object?>{};
    var batchStartedAt = DateTime.now();
    // 中文注释: 外层 while 承担 unattended 自续，内层 while 仍是每批 max_steps 预算。
    outer:
    while (true) {
      var batchSteps = 0;
      while (batchSteps < maxStepsPerBatch) {
        if (maxTotalSeconds > 0 &&
            DateTime.now().difference(runStartedAt).inSeconds >=
                maxTotalSeconds) {
          stopReason = 'max_seconds';
          stopNote = '已达到本次运行的总时间限制，长任务已暂停，可稍后继续。';
          break outer;
        }
        final maxSeconds = maxSecondsPerBatch;
        if (maxSeconds > 0 &&
            DateTime.now().difference(batchStartedAt).inSeconds >= maxSeconds) {
          stopReason = 'max_seconds';
          stopNote = '已达到本次运行的最长时间限制，长任务已暂停，可稍后继续。';
          break;
        }
        final nextTask = await _nextWorkflowQueueTask(project);
        if (nextTask.isEmpty) {
          stopReason = 'no_runnable_task';
          stopNote = '当前没有依赖满足且处于 queued/retrying 的任务。';
          break outer;
        }
        final remainingDuration = maxSeconds <= 0
            ? null
            : Duration(seconds: maxSeconds) -
                  DateTime.now().difference(batchStartedAt);
        final cancellationToken = remainingDuration == null
            ? null
            : DraftGenerationCancellationToken();
        final safeTimeoutDuration = remainingDuration == null
            ? null
            : (remainingDuration <= Duration.zero
                  ? const Duration(milliseconds: 1)
                  : remainingDuration);
        final stepSelector = <String, Object?>{
          'relative_path': ValueReaders.stringValue(nextTask['relative_path']),
        };
        final stepFuture = runner(
          project,
          settings,
          stepSelector,
          runRecord: longRunRecord,
          agent: agent,
          options: cleanOptions,
          cancellationToken: cancellationToken,
        );
        if (cancellationToken == null || safeTimeoutDuration == null) {
          lastResult = await stepFuture;
        } else {
          final timeoutResult = Completer<JsonMap>();
          final timeoutTimer = Timer(safeTimeoutDuration, () {
            cancellationToken.cancel();
            if (!timeoutResult.isCompleted) {
              timeoutResult.complete(_workflowTaskTimeoutResult());
            }
          });
          stepFuture.then(
            (value) {
              if (!timeoutResult.isCompleted) {
                timeoutResult.complete(value);
              }
            },
            onError: (Object error, StackTrace stackTrace) {
              if (!timeoutResult.isCompleted) {
                timeoutResult.completeError(error, stackTrace);
              }
            },
          );
          lastResult = await timeoutResult.future;
          timeoutTimer.cancel();
          if (ValueReaders.boolValue(lastResult['timeout'])) {
            await _taskRepository.transitionTask(
              project,
              stepSelector,
              TaskRuntimeConstants.statusQueued,
              note: '当前批次已达到最长时间限制，已取消本步，等待后续继续。',
            );
          }
        }
        stepsRun += 1;
        batchSteps += 1;
        final updatedTask = await _taskRepository.loadTask(
          project,
          <String, Object?>{
            'relative_path': ValueReaders.stringValue(
              nextTask['relative_path'],
            ),
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
          longRunRecord = await _taskRepository.saveRecord(
            project,
            longRunPath,
            longRunRecord,
          );
          await _syncLongTaskRunRecord(project, longRunRecord);
        }

        if (ValueReaders.boolValue(lastResult['timeout'])) {
          stopReason = 'max_seconds';
          stopNote = '已达到本次运行的最长时间限制，长任务已暂停，可稍后继续。';
          break;
        }

        final stopDecision = _taskQueueStopPolicyService.stopAfterStep(
          lastResult,
          updatedTask,
          options: cleanOptions,
        );
        if (ValueReaders.boolValue(stopDecision['stop'])) {
          stopReason = ValueReaders.stringValue(stopDecision['reason']);
          stopNote = ValueReaders.stringValue(stopDecision['note']);
          break outer;
        }
      }
      batchesRun += 1;
      if (stopReason.isEmpty) {
        stopReason = batchSteps >= maxStepsPerBatch ? 'max_steps' : 'completed';
        stopNote = stopReason == 'max_steps' ? '已达到本批最大步数。' : '队列已完成。';
      }
      // 中文注释: unattended 模式下，仅因每批上限（max_steps / max_seconds）触发的暂停才自续，
      // 且受总批数与总时长限制；任何需要人工 / repair 介入的停止原因都终止本次调用。
      final isBatchBoundary =
          stopReason == 'max_steps' || stopReason == 'max_seconds';
      final underTotalCap =
          maxTotalSeconds <= 0 ||
          DateTime.now().difference(runStartedAt).inSeconds < maxTotalSeconds;
      final stillRunnable = (await _nextWorkflowQueueTask(project)).isNotEmpty;
      final shouldContinue =
          unattended &&
          isBatchBoundary &&
          underTotalCap &&
          stillRunnable &&
          batchesRun < maxBatches;
      if (shouldContinue) {
        final reloaded = await _taskRepository.loadRecord(project, longRunPath);
        if (reloaded.isNotEmpty &&
            ValueReaders.stringValue(reloaded['status']) !=
                TaskRuntimeConstants.statusRunning) {
          // 中文注释: 批次之间发现运行记录已被外部停止，终止自续，交给 finalize 收尾。
          stopReason = 'manual_stop';
          stopNote = '用户请求停止长任务。';
          break;
        }
        longRunRecord = _lifecycleService.resumeRecord(
          reloaded.isNotEmpty ? reloaded : longRunRecord,
        );
        longRunRecord = await _taskRepository.saveRecord(
          project,
          longRunPath,
          longRunRecord,
        );
        await _syncLongTaskRunRecord(project, longRunRecord);
        stopReason = '';
        stopNote = '';
        batchStartedAt = DateTime.now();
        continue;
      }
      break;
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
      longRunRecord =
          ValueReaders.stringValue(disposition['record_action']) == 'pause'
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
      longRunRecord = await _taskRepository.saveRecord(
        project,
        longRunPath,
        longRunRecord,
      );
      await _syncLongTaskRunRecord(project, longRunRecord);
      final schedulerSnapshot = _buildLongTaskSchedulerSnapshotUseCase.execute(
        longRunRecord,
        await _currentWorkflowTasks(project),
        options: cleanOptions,
      );
      await _taskRepository.writeTextFile(
        project,
        ValueReaders.stringValue(
          schedulerSnapshot['summary_path'],
          'tracking/long_task_runs/$queueId.summary.md',
        ),
        LongTaskSchedulerMarkdownRenderer().renderMarkdown(schedulerSnapshot),
      );
      await _taskRepository.saveRecord(
        project,
        ValueReaders.stringValue(
          schedulerSnapshot['relative_path'],
          longRunPath,
        ),
        {
          ...longRunRecord,
          'run_center_contract': _runCenterContractFromSchedulerSnapshot(
            schedulerSnapshot,
          ),
          'scheduler_snapshot': schedulerSnapshot,
        },
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
      'queue_record': queueRecord,
      'long_task_run_path': longRunPath,
      'long_task_record': longRunRecord,
      'long_task_run_record': longRunRecord,
      'long_task_run_center_contract': longRunRecord.isEmpty
          ? const <String, Object?>{}
          : _runCenterContractFromSchedulerSnapshot(
              _buildLongTaskSchedulerSnapshotUseCase.execute(
                longRunRecord,
                await _currentWorkflowTasks(project),
                options: cleanOptions,
              ),
            ),
      'response': _responseFromLastResult(lastResult),
      'output_paths': ValueReaders.stringList(lastResult['output_paths']),
      'changed_paths': const <Object?>[],
    };
  }

  Future<List<JsonMap>> _currentWorkflowTasks(
    ProjectDescriptor project, {
    JsonMap filters = const <String, Object?>{},
  }) async {
    return _workflowTaskSelectionService.workflowScopedTasks(
      await listWorkflowTasks(project, filters: filters),
    );
  }

  Future<JsonMap> _recoverResumeDispatchRunningTask(
    ProjectDescriptor project,
    List<JsonMap> tasks,
  ) async {
    for (final task in tasks) {
      if (ValueReaders.stringValue(task['status']) !=
          TaskRuntimeConstants.statusRunning) {
        continue;
      }
      final writingExecution = ValueReaders.mapValue(
        task['last_writing_execution_result'],
      );
      final recovery = ValueReaders.mapValue(writingExecution['recovery']);
      final nextAction = ValueReaders.stringValue(
        writingExecution['next_action'],
        ValueReaders.stringValue(recovery['recommended_action']),
      ).trim();
      if (nextAction != 'resume_dispatch') {
        continue;
      }
      await _taskRepository.transitionTask(
        project,
        <String, Object?>{
          'relative_path': ValueReaders.stringValue(task['relative_path']),
        },
        TaskRuntimeConstants.statusFailed,
        note: '检测到遗留 running 恢复态任务，先标记为 failed 以进入受控重试。',
      );
      final recovered = await _taskRepository.transitionTask(
        project,
        <String, Object?>{
          'relative_path': ValueReaders.stringValue(task['relative_path']),
        },
        TaskRuntimeConstants.statusRetrying,
        note: '检测到遗留 running 恢复态任务，已恢复为 retrying 继续调度。',
      );
      return ValueReaders.mapValue(recovered['task']);
    }
    return const <String, Object?>{};
  }

  Future<void> _autoConfirmCheckpointBeforeResumeIfPossible(
    ProjectDescriptor project,
    String longTaskRunPath,
  ) async {
    final cleanRunPath = longTaskRunPath.trim();
    if (cleanRunPath.isEmpty) {
      return;
    }
    final runRecord = await _taskRepository.loadRecord(project, cleanRunPath);
    if (runRecord.isEmpty) {
      return;
    }
    final checkpointReviewPath = ValueReaders.stringValue(
      runRecord['last_checkpoint_review_path'],
    ).trim();
    if (checkpointReviewPath.isEmpty) {
      return;
    }
    final actionPackage = await _checkpointActionService.buildActionPackage(
      project,
      checkpointReviewPath,
    );
    if (!ValueReaders.boolValue(actionPackage['ok'])) {
      return;
    }
    final command = _preferredCheckpointResumeCommand(actionPackage);
    if (command.isEmpty) {
      return;
    }
    await _checkpointActionService.applyAction(
      project,
      checkpointReviewPath,
      command,
    );
  }

  String _preferredCheckpointResumeCommand(JsonMap actionPackage) {
    final actions = ValueReaders.mapList(actionPackage['actions']);
    for (final preferred in const <String>[
      'continue_long_task',
      'confirm_checkpoint_continue',
    ]) {
      for (final action in actions) {
        if (ValueReaders.stringValue(action['id']).trim() != preferred) {
          continue;
        }
        if (ValueReaders.boolValue(action['enabled'])) {
          return preferred;
        }
      }
    }
    return '';
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
      'activation_report_path': ValueReaders.stringValue(
        result['activation_report_path'],
      ),
      'activation_report_summary': ValueReaders.stringValue(
        result['activation_report_summary'],
      ),
      'chapter_delivery_state': ValueReaders.stringValue(
        result['chapter_delivery_state'],
      ),
      'chapter_delivery_path': ValueReaders.stringValue(
        result['chapter_delivery_path'],
      ),
      'created_at': DateTime.now().toIso8601String(),
    });
    next['steps'] = steps;
    next['completed_steps'] = steps.length;
    next['last_task_id'] = ValueReaders.stringValue(task['id']);
    next['last_task_relative_path'] = ValueReaders.stringValue(
      task['relative_path'],
    );
    next['last_activation_report_path'] = ValueReaders.stringValue(
      result['activation_report_path'],
    );
    next['last_chapter_delivery_state'] = ValueReaders.stringValue(
      result['chapter_delivery_state'],
    );
    next['last_chapter_delivery_path'] = ValueReaders.stringValue(
      result['chapter_delivery_path'],
    );
    next['updated_at'] = DateTime.now().toIso8601String();
    return next;
  }

  JsonMap _workflowTaskTimeoutResult() {
    return const <String, Object?>{
      'ok': false,
      'timeout': true,
      'error': 'Workflow task execution timed out.',
      'response': <String, Object?>{},
      'output_paths': <Object?>[],
      'changed_paths': <Object?>[],
      'executed_tools': <Object?>[],
      'execution': <String, Object?>{},
      'checkpoint_review': <String, Object?>{},
    };
  }

  JsonMap _runCenterContractFromSchedulerSnapshot(JsonMap schedulerSnapshot) {
    // 中文注释: 兼容旧/新 snapshot 结构，优先顶层，缺失时再回退到 scheduler_plan 内。
    final topLevel = ValueReaders.mapValue(
      schedulerSnapshot['run_center_contract'],
    );
    if (topLevel.isNotEmpty) {
      return topLevel;
    }
    final nested = ValueReaders.mapValue(
      ValueReaders.mapValue(
        schedulerSnapshot['scheduler_plan'],
      )['run_center_contract'],
    );
    if (nested.isNotEmpty) {
      return nested;
    }
    return const <String, Object?>{};
  }

  Future<void> _syncLongTaskRunRecord(
    ProjectDescriptor project,
    JsonMap runRecord,
  ) async {
    final service = _longTaskRunRegistrySyncService;
    if (service == null || runRecord.isEmpty) {
      return;
    }
    await service.syncRecord(project, runRecord);
  }

  JsonMap _responseFromLastResult(JsonMap result) {
    return <String, Object?>{
      'ok': ValueReaders.boolValue(result['ok'], true),
      'content': ValueReaders.stringValue(result['content']),
      'tool_calls': ValueReaders.objectList(result['tool_calls']),
      'waiting_for_user_choice': ValueReaders.boolValue(
        result['waiting_for_user_choice'],
      ),
      'reasoning_content': ValueReaders.stringValue(
        result['reasoning_content'],
      ),
      'error_summary': ValueReaders.stringValue(result['error_summary']),
    };
  }
}
