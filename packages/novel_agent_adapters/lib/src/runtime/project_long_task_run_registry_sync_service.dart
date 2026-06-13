import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:novel_agent_core/src/workflow/long_task_covered_source_task_service.dart';

import '../storage/project_task_repository.dart';
import 'long_task_supervisor.dart';

class ProjectLongTaskRunRegistrySyncService {
  ProjectLongTaskRunRegistrySyncService({
    required LongTaskSupervisor supervisor,
    required ProjectTaskRepository taskRepository,
    RunInstanceFactoryService? runInstanceFactoryService,
    LongTaskCoveredSourceTaskService? coveredSourceTaskService,
  }) : _supervisor = supervisor,
       _taskRepository = taskRepository,
       _runInstanceFactoryService =
           runInstanceFactoryService ?? const RunInstanceFactoryService(),
       _coveredSourceTaskService =
           coveredSourceTaskService ?? const LongTaskCoveredSourceTaskService();

  final LongTaskSupervisor _supervisor;
  final ProjectTaskRepository _taskRepository;
  final RunInstanceFactoryService _runInstanceFactoryService;
  final LongTaskCoveredSourceTaskService _coveredSourceTaskService;

  Future<RunInstance?> syncRecord(
    ProjectDescriptor project,
    JsonMap runRecord,
  ) async {
    final runId = ValueReaders.stringValue(runRecord['id']).trim();
    if (runId.isEmpty) {
      return null;
    }
    final tasks = await _taskRepository.listTasks(project);
    final createdAt =
        _optionalDateTime(runRecord['created_at']) ?? DateTime.now();
    final updatedAt = _optionalDateTime(runRecord['updated_at']) ?? createdAt;
    final runtimeBaselineId = _runtimeBaselineId(runRecord);
    final modeId = ValueReaders.stringValue(runRecord['mode']).trim();
    final workflowStrategyId = _workflowStrategyId(runRecord);
    final activeTask = _activeTask(tasks, runRecord);
    final recoveryState = LongTaskRecoveryState.fromJson(
      ValueReaders.mapValue(runRecord['last_recovery_state']),
    );
    final stopOutcome = _stopOutcome(runRecord);
    final nextStatus = _runStatus(
      runRecord,
      activeTask: activeTask,
      recoveryState: recoveryState,
    );
    final existing = await _supervisor.loadRun(runId);
    final base =
        existing ??
        _runInstanceFactoryService.createLongTaskInstance(
          runId: runId,
          project: project,
          runtimeBaseline: RuntimeBaseline(
            id: runtimeBaselineId,
            title: runtimeBaselineId,
            description: '',
            supportedProjectTypeIds: <String>[project.projectType],
          ),
          modeId: modeId,
          workflowStrategyId: workflowStrategyId,
          initialStatus: nextStatus,
          now: createdAt,
        );
    final note = _note(runRecord, activeTask: activeTask);
    final stopReason = _stopReason(runRecord, activeTask: activeTask);
    final startedAt =
        existing?.startedAt ??
        (nextStatus == LongTaskRunStatus.draftingGuidance ? null : createdAt);
    final instance = base.copyWith(
      runtimeBaselineId: runtimeBaselineId,
      modeId: modeId,
      workflowStrategyId: workflowStrategyId,
      status: nextStatus,
      createdAt: existing?.createdAt ?? createdAt,
      updatedAt: updatedAt,
      lastHeartbeatAt: nextStatus.isActive ? updatedAt : null,
      clearLastHeartbeatAt: !nextStatus.isActive,
      startedAt: startedAt,
      clearStartedAt: startedAt == null,
      stoppedAt: nextStatus.isTerminal ? updatedAt : null,
      clearStoppedAt: !nextStatus.isTerminal,
      activeTaskId: ValueReaders.stringValue(activeTask['id']).trim(),
      activeTaskTitle: ValueReaders.stringValue(activeTask['title']).trim(),
      note: note,
      stopReason: stopReason,
      stopOutcome: stopOutcome,
      recoveryState: recoveryState,
      metadata: <String, Object?>{
        ...ValueReaders.deepCopyMap(base.metadata),
        'record_relative_path': ValueReaders.stringValue(
          runRecord['relative_path'],
        ),
        'record_status': ValueReaders.stringValue(runRecord['status']),
        'task_count': tasks.length,
      },
    );
    await _supervisor.trackRun(instance);
    return instance;
  }

  String _runtimeBaselineId(JsonMap runRecord) {
    return ValueReaders.stringValue(
      runRecord['runtime_baseline_id'],
      ValueReaders.stringValue(
        ValueReaders.mapValue(runRecord['options'])['runtime_baseline_id'],
        'continuous_autonomous',
      ),
    ).trim();
  }

  String _workflowStrategyId(JsonMap runRecord) {
    return ValueReaders.stringValue(
      ValueReaders.mapValue(runRecord['strategy'])['transaction_model'],
      ValueReaders.stringValue(
        ValueReaders.mapValue(runRecord['strategy'])['name'],
        ValueReaders.stringValue(runRecord['mode']),
      ),
    ).trim();
  }

  JsonMap _activeTask(List<JsonMap> tasks, JsonMap runRecord) {
    final planId = ValueReaders.stringValue(
      runRecord['plan_id'],
      ValueReaders.stringValue(
        ValueReaders.mapValue(runRecord['options'])['plan_id'],
      ),
    ).trim();
    final candidateTasks = planId.isEmpty
        ? tasks
        : tasks
              .where(
                (task) =>
                    ValueReaders.stringValue(
                      ValueReaders.mapValue(task['metadata'])['plan_id'],
                    ).trim() ==
                    planId,
              )
              .toList(growable: false);

    JsonMap? firstByStatus(String status) {
      for (final task in candidateTasks) {
        if (ValueReaders.stringValue(task['status']).trim() == status) {
          return task;
        }
      }
      return null;
    }

    JsonMap? firstUncoveredByStatus(String status) {
      final task = _coveredSourceTaskService.firstUncoveredTaskByStatus(
        candidateTasks,
        status,
      );
      return task.isEmpty ? null : task;
    }

    return ValueReaders.deepCopyMap(
      firstByStatus(TaskRuntimeConstants.statusRunning) ??
          firstUncoveredByStatus(TaskRuntimeConstants.statusFailed) ??
          firstByStatus(TaskRuntimeConstants.statusRetrying) ??
          firstByStatus(TaskRuntimeConstants.statusPlanning) ??
          firstByStatus(TaskRuntimeConstants.statusQueued) ??
          firstUncoveredByStatus(TaskRuntimeConstants.statusWaitingUser) ??
          const <String, Object?>{},
    );
  }

  LongTaskStopOutcome _stopOutcome(JsonMap runRecord) {
    final direct = LongTaskStopOutcome.fromJson(
      ValueReaders.mapValue(runRecord['stop_outcome']),
    );
    if (direct.present) {
      return direct;
    }
    return LongTaskStopOutcome.fromJson(
      ValueReaders.mapValue(
        ValueReaders.mapValue(runRecord['last_recovery_state'])['stop_outcome'],
      ),
    );
  }

  LongTaskRunStatus _runStatus(
    JsonMap runRecord, {
    required JsonMap activeTask,
    required LongTaskRecoveryState recoveryState,
  }) {
    final recordStatus = ValueReaders.stringValue(
      runRecord['status'],
      TaskRuntimeConstants.statusRunning,
    ).trim();
    final activeTaskStatus = ValueReaders.stringValue(
      activeTask['status'],
    ).trim();
    if (activeTaskStatus == TaskRuntimeConstants.statusFailed ||
        recordStatus == TaskRuntimeConstants.statusFailed) {
      return LongTaskRunStatus.failedManualAttention;
    }
    if (activeTaskStatus == TaskRuntimeConstants.statusWaitingUser) {
      return LongTaskRunStatus.waitingGate;
    }
    if (recoveryState.present &&
        recoveryState.runStatus == LongTaskRunStatus.recovering.id) {
      return LongTaskRunStatus.recovering;
    }
    if (recordStatus == TaskRuntimeConstants.statusPaused) {
      return LongTaskRunStatus.paused;
    }
    if (recordStatus == TaskRuntimeConstants.statusSucceeded ||
        recordStatus == TaskRuntimeConstants.statusCancelled) {
      return LongTaskRunStatus.stopped;
    }
    return LongTaskRunStatus.running;
  }

  String _note(JsonMap runRecord, {required JsonMap activeTask}) {
    final candidates = <String>[
      ValueReaders.stringValue(runRecord['stop_note']).trim(),
      ValueReaders.stringValue(
        runRecord['last_writing_execution_summary'],
      ).trim(),
      ValueReaders.stringValue(runRecord['summary']).trim(),
      ValueReaders.stringValue(activeTask['title']).trim().isEmpty
          ? ''
          : '当前任务：${ValueReaders.stringValue(activeTask['title']).trim()}',
    ];
    for (final item in candidates) {
      if (item.isNotEmpty) {
        return item;
      }
    }
    return '';
  }

  String _stopReason(JsonMap runRecord, {required JsonMap activeTask}) {
    final direct = ValueReaders.stringValue(runRecord['stop_reason']).trim();
    if (direct.isNotEmpty) {
      return direct;
    }
    final activeTaskStatus = ValueReaders.stringValue(
      activeTask['status'],
    ).trim();
    if (activeTaskStatus == TaskRuntimeConstants.statusFailed) {
      return 'failed_task';
    }
    if (activeTaskStatus == TaskRuntimeConstants.statusWaitingUser) {
      return 'waiting_user_checkpoint';
    }
    return '';
  }

  DateTime? _optionalDateTime(Object? rawValue) {
    final text = ValueReaders.stringValue(rawValue).trim();
    if (text.isEmpty) {
      return null;
    }
    return DateTime.tryParse(text);
  }
}
