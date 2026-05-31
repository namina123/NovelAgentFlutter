import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'long_task_next_batch_plan_service.dart';
import 'long_task_task_summary_service.dart';
import 'task_runtime_constants.dart';

class LongTaskProgressSnapshotService {
  LongTaskProgressSnapshotService({
    required LongTaskNextBatchPlanService nextBatchPlanService,
    required LongTaskTaskSummaryService taskSummaryService,
  }) : _nextBatchPlanService = nextBatchPlanService,
       _taskSummaryService = taskSummaryService;

  final LongTaskNextBatchPlanService _nextBatchPlanService;
  final LongTaskTaskSummaryService _taskSummaryService;

  JsonMap build(
    JsonMap record,
    List<Object?> tasks, {
    JsonMap options = const <String, Object?>{},
  }) {
    final batchPlan = _nextBatchPlanService.nextBatchPlan(
      record,
      tasks,
      options: options,
    );
    final status = ValueReaders.stringValue(
      record['status'],
      TaskRuntimeConstants.statusRunning,
    ).trim();
    final reason = ValueReaders.stringValue(
      batchPlan['reason'],
      ValueReaders.stringValue(record['stop_reason']),
    ).trim();
    final activeTask = _activeTaskFromBatchOrTasks(batchPlan, tasks);
    final overall = _overallPercent(tasks);
    final waitingUser = _isWaitingUser(reason, activeTask);
    final blocked = waitingUser || _isBlockedReason(reason);
    final phase = _phaseFor(status, reason, activeTask, batchPlan, tasks);
    return <String, Object?>{
      'schema_version': 1,
      'run_id': ValueReaders.stringValue(record['id']),
      'run_path': ValueReaders.stringValue(record['relative_path']),
      'status': status,
      'status_label': _statusLabel(status),
      'phase': phase,
      'phase_label': _phaseLabel(phase),
      'message': _messageFor(
        phase,
        batchPlan: batchPlan,
        activeTask: activeTask,
        reason: reason,
      ),
      'overall_percent': overall,
      'runtime_percent': _runtimePercent(
        phase: phase,
        overallPercent: overall,
        reason: reason,
      ),
      'phase_percent': _phasePercent(phase),
      'active_task': activeTask,
      'active_task_title': ValueReaders.stringValue(activeTask['title']),
      'active_task_path': ValueReaders.stringValue(activeTask['relative_path']),
      'waiting_user': waitingUser,
      'blocked': blocked,
      'blocker': reason,
      'recommended_action_label': _recommendedActionLabel(
        phase: phase,
        waitingUser: waitingUser,
        blocked: blocked,
        reason: reason,
      ),
      'heartbeat_at': ValueReaders.stringValue(record['updated_at']),
      'updated_at': ValueReaders.stringValue(record['updated_at']),
    };
  }

  JsonMap _activeTaskFromBatchOrTasks(JsonMap batchPlan, List<Object?> tasks) {
    final batchTasks = ValueReaders.mapList(batchPlan['tasks']);
    if (batchTasks.isNotEmpty) {
      return batchTasks.first;
    }
    final failed = _firstTaskByStatus(tasks, TaskRuntimeConstants.statusFailed);
    if (failed.isNotEmpty) {
      return _taskSummaryService.taskSummary(failed);
    }
    final waiting = _firstTaskByStatus(
      tasks,
      TaskRuntimeConstants.statusWaitingUser,
    );
    if (waiting.isNotEmpty) {
      return _taskSummaryService.taskSummary(waiting);
    }
    for (final rawTask in tasks) {
      final task = ValueReaders.mapValue(rawTask);
      if (TaskRuntimeConstants.runnableStatuses.contains(
        ValueReaders.stringValue(task['status']),
      )) {
        return _taskSummaryService.taskSummary(task);
      }
    }
    return <String, Object?>{};
  }

  JsonMap _firstTaskByStatus(List<Object?> tasks, String status) {
    for (final rawTask in tasks) {
      final task = ValueReaders.mapValue(rawTask);
      if (ValueReaders.stringValue(task['status']) == status) {
        return task;
      }
    }
    return <String, Object?>{};
  }

  int _overallPercent(List<Object?> tasks) {
    if (tasks.isEmpty) {
      return 0;
    }
    var succeeded = 0;
    for (final rawTask in tasks) {
      final task = ValueReaders.mapValue(rawTask);
      if (ValueReaders.stringValue(task['status']) ==
          TaskRuntimeConstants.statusSucceeded) {
        succeeded += 1;
      }
    }
    return (succeeded * 100) ~/ tasks.length;
  }

  bool _isWaitingUser(String reason, JsonMap activeTask) {
    return reason.startsWith('waiting_user') ||
        reason == 'checkpoint_task' ||
        ValueReaders.stringValue(activeTask['status']) ==
            TaskRuntimeConstants.statusWaitingUser ||
        ValueReaders.stringValue(activeTask['task_type']) == 'checkpoint';
  }

  bool _isBlockedReason(String reason) {
    return reason == 'blocked_dependencies' ||
        reason == 'failed_task' ||
        reason == 'step_failed' ||
        reason == 'manual_stop' ||
        reason == 'no_tasks';
  }

  String _phaseFor(
    String status,
    String reason,
    JsonMap activeTask,
    JsonMap batchPlan,
    List<Object?> tasks,
  ) {
    if (status == TaskRuntimeConstants.statusPaused ||
        reason == 'manual_pause') {
      return 'paused';
    }
    if (reason == 'failed_task' || reason == 'step_failed') {
      return 'failed';
    }
    if (_isWaitingUser(reason, activeTask)) {
      return 'waiting_checkpoint';
    }
    if (reason == 'all_tasks_terminal' ||
        status == TaskRuntimeConstants.statusSucceeded) {
      return 'completed';
    }
    if (reason == 'manual_stop' ||
        status == TaskRuntimeConstants.statusCancelled) {
      return 'stopped';
    }
    if (ValueReaders.stringValue(batchPlan['action']) == 'dispatch_batch') {
      final taskType = ValueReaders.stringValue(activeTask['task_type']).trim();
      if (taskType == 'postprocess') {
        return 'postprocessing';
      }
      return 'running_task';
    }
    if (reason == 'no_tasks') {
      return 'idle';
    }
    if (tasks.isEmpty) {
      return 'idle';
    }
    return 'ready';
  }

  String _statusLabel(String status) {
    switch (status) {
      case TaskRuntimeConstants.statusRunning:
        return '运行中';
      case TaskRuntimeConstants.statusPaused:
        return '已暂停';
      case TaskRuntimeConstants.statusSucceeded:
        return '已完成';
      case TaskRuntimeConstants.statusFailed:
        return '失败';
      case TaskRuntimeConstants.statusCancelled:
        return '已取消';
      default:
        return status.isEmpty ? '未知' : status;
    }
  }

  String _phaseLabel(String phase) {
    switch (phase) {
      case 'idle':
        return '空闲';
      case 'ready':
        return '待启动';
      case 'running_task':
        return '执行任务';
      case 'postprocessing':
        return '后处理';
      case 'waiting_checkpoint':
        return '等待检查点';
      case 'paused':
        return '已暂停';
      case 'failed':
        return '等待失败处理';
      case 'completed':
        return '已完成';
      case 'stopped':
        return '已停止';
      default:
        return phase;
    }
  }

  String _messageFor(
    String phase, {
    required JsonMap batchPlan,
    required JsonMap activeTask,
    required String reason,
  }) {
    final note = ValueReaders.stringValue(batchPlan['note']).trim();
    if (note.isNotEmpty) {
      return note;
    }
    final title = ValueReaders.stringValue(activeTask['title'], '当前任务').trim();
    switch (phase) {
      case 'running_task':
        return '正在推进：$title';
      case 'postprocessing':
        return '正在后处理：$title';
      case 'waiting_checkpoint':
        return '已到达人工确认点，等待用户继续。';
      case 'paused':
        return '长任务已暂停，可稍后恢复。';
      case 'failed':
        return '存在失败任务，等待重试、跳过或人工修复。';
      case 'completed':
        return '长任务队列已完成。';
      case 'stopped':
        return reason == 'manual_stop' ? '用户已停止当前长任务。' : '长任务已停止。';
      case 'idle':
        return '当前长任务暂无可用运行现场。';
      default:
        return '长任务当前没有新的提示。';
    }
  }

  int _runtimePercent({
    required String phase,
    required int overallPercent,
    required String reason,
  }) {
    if (phase == 'completed') {
      return 100;
    }
    if (phase == 'failed' ||
        phase == 'waiting_checkpoint' ||
        phase == 'paused') {
      return overallPercent;
    }
    if (phase == 'running_task' || phase == 'postprocessing') {
      return overallPercent.clamp(0, 99);
    }
    if (reason == 'no_tasks') {
      return 0;
    }
    return overallPercent;
  }

  int? _phasePercent(String phase) {
    switch (phase) {
      case 'completed':
        return 100;
      case 'idle':
        return 0;
      default:
        return null;
    }
  }

  String _recommendedActionLabel({
    required String phase,
    required bool waitingUser,
    required bool blocked,
    required String reason,
  }) {
    if (waitingUser) {
      return '处理检查点';
    }
    if (phase == 'paused') {
      return '继续运行';
    }
    if (phase == 'failed' || reason == 'step_failed') {
      return '处理失败任务';
    }
    if (blocked) {
      return '查看阻塞原因';
    }
    if (phase == 'running_task' || phase == 'postprocessing') {
      return '观察运行现场';
    }
    if (phase == 'completed') {
      return '查看运行回放';
    }
    return '查看任务链';
  }
}
