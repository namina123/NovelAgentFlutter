import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'long_task_next_batch_plan_service.dart';
import 'long_task_task_summary_service.dart';
import 'task_runtime_constants.dart';

class LongTaskRunCenterContractService {
  LongTaskRunCenterContractService({
    required LongTaskNextBatchPlanService nextBatchPlanService,
    required LongTaskTaskSummaryService taskSummaryService,
  }) : _nextBatchPlanService = nextBatchPlanService,
       _taskSummaryService = taskSummaryService;

  final LongTaskNextBatchPlanService _nextBatchPlanService;
  final LongTaskTaskSummaryService _taskSummaryService;

  JsonMap runCenterContract(
    JsonMap record,
    List<Object?> tasks, {
    JsonMap options = const <String, Object?>{},
  }) {
    // 中文注释: 运行中心合同把纯调度状态翻成 GUI/CLI 都能直接消费的控制面板数据。
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
    final controls = _controlsForState(status, reason, activeTask, options);
    return <String, Object?>{
      'ok': true,
      'schema_version': 1,
      'run_id': ValueReaders.stringValue(record['id']),
      'run_path': ValueReaders.stringValue(record['relative_path']),
      'mode': ValueReaders.stringValue(
        record['mode'],
        ValueReaders.stringValue(options['mode']),
      ),
      'status': status,
      'status_label': _statusLabel(status),
      'tone': _toneForStatus(status, reason),
      'reason': reason,
      'note': _noteFromBatch(batchPlan, status),
      'progress': _progressFromRecordTasks(record, tasks),
      'active_task': activeTask,
      'batch_plan': batchPlan,
      'controls': controls,
      'control_summary': _controlSummary(controls),
      'updated_at': ValueReaders.stringValue(record['updated_at']),
    };
  }

  String _statusLabel(String status) {
    // 中文注释: 状态文案固定在 core，避免不同宿主对同一状态翻译不一致。
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

  String _toneForStatus(String status, String reason) {
    // 中文注释: tone 是给上层 UI 的轻量语义标签，不携带任何业务副作用。
    if (status == TaskRuntimeConstants.statusFailed ||
        reason == 'failed_task' ||
        reason == 'step_failed') {
      return 'danger';
    }
    if (status == TaskRuntimeConstants.statusPaused ||
        reason.startsWith('waiting_user') ||
        reason == 'manual_pause') {
      return 'warm';
    }
    if (status == TaskRuntimeConstants.statusSucceeded) {
      return 'success';
    }
    if (status == TaskRuntimeConstants.statusRunning) {
      return 'accent';
    }
    return 'muted';
  }

  JsonMap _progressFromRecordTasks(JsonMap record, List<Object?> tasks) {
    // 中文注释: 进度统计聚合成单一对象，供桌面和移动端运行中心共用。
    final counts = _statusCounts(tasks);
    final total = tasks.length;
    final succeeded = ValueReaders.intValue(
      counts[TaskRuntimeConstants.statusSucceeded],
    );
    final failed = ValueReaders.intValue(
      counts[TaskRuntimeConstants.statusFailed],
    );
    final waiting = ValueReaders.intValue(
      counts[TaskRuntimeConstants.statusWaitingUser],
    );
    final runnable = _countRunnable(tasks);
    return <String, Object?>{
      'task_count': total,
      'succeeded': succeeded,
      'failed': failed,
      'waiting_user': waiting,
      'runnable': runnable,
      'completed_steps': ValueReaders.intValue(record['completed_steps']),
      'percent': total > 0 ? ((succeeded * 100) ~/ total) : 0,
    };
  }

  JsonMap _statusCounts(List<Object?> tasks) {
    // 中文注释: 运行中心内部也保留一份轻量计数，避免依赖外部调用先算好。
    final counts = <String, Object?>{};
    for (final rawTask in tasks) {
      final task = ValueReaders.mapValue(rawTask);
      var status = ValueReaders.stringValue(task['status']).trim();
      if (status.isEmpty) {
        status = 'unknown';
      }
      counts[status] = ValueReaders.intValue(counts[status]) + 1;
    }
    return counts;
  }

  int _countRunnable(List<Object?> tasks) {
    // 中文注释: runnable 统计用于提示“还剩多少能继续跑”的即时状态。
    var count = 0;
    for (final rawTask in tasks) {
      final task = ValueReaders.mapValue(rawTask);
      if (TaskRuntimeConstants.runnableStatuses.contains(
        ValueReaders.stringValue(task['status']),
      )) {
        count += 1;
      }
    }
    return count;
  }

  JsonMap _activeTaskFromBatchOrTasks(JsonMap batchPlan, List<Object?> tasks) {
    // 中文注释: 活跃任务优先显示本批首任务，否则回退到失败、等待或下一个可运行任务。
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
    // 中文注释: 运行中心只关心首个命中任务即可，不需要完整过滤列表。
    for (final rawTask in tasks) {
      final task = ValueReaders.mapValue(rawTask);
      if (ValueReaders.stringValue(task['status']) == status) {
        return task;
      }
    }
    return <String, Object?>{};
  }

  List<JsonMap> _controlsForState(
    String status,
    String reason,
    JsonMap activeTask,
    JsonMap options,
  ) {
    // 中文注释: 控件启用规则集中维护，避免 GUI/CLI 各自重新实现状态判断。
    final allowDestructive = ValueReaders.boolValue(
      options['allow_destructive_controls'],
      true,
    );
    final running = status == TaskRuntimeConstants.statusRunning;
    final paused =
        status == TaskRuntimeConstants.statusPaused ||
        reason == 'manual_pause' ||
        reason == 'max_steps' ||
        reason == 'max_seconds';
    final failed =
        reason == 'failed_task' ||
        reason == 'step_failed' ||
        ValueReaders.stringValue(activeTask['status']) ==
            TaskRuntimeConstants.statusFailed;
    final waitingUser =
        reason.startsWith('waiting_user') ||
        ValueReaders.stringValue(activeTask['status']) ==
            TaskRuntimeConstants.statusWaitingUser ||
        ValueReaders.stringValue(activeTask['task_type']) == 'checkpoint';
    return <JsonMap>[
      _control(
        'pause',
        '暂停',
        enabled: running,
        hostCommand: 'pause_long_task_run',
        tone: 'warm',
        disabledReason: '只有运行中的长任务可以暂停。',
      ),
      _control(
        'resume',
        '继续',
        enabled: paused && !waitingUser && !failed,
        hostCommand: 'resume_long_task_run',
        tone: 'accent',
        disabledReason: waitingUser ? '请先确认检查点，再继续运行。' : '当前状态不需要继续。',
      ),
      _control(
        'stop',
        '停止',
        enabled: running || paused,
        hostCommand: 'stop_long_task_run',
        tone: 'danger',
        disabledReason: '只有运行中或暂停的长任务可以停止。',
      ),
      _control(
        'confirm_checkpoint',
        '确认检查点',
        enabled: waitingUser,
        hostCommand: 'apply_long_task_revision',
        tone: 'success',
        disabledReason: '当前没有等待确认的检查点。',
        arguments: <String, Object?>{
          ..._taskSelector(activeTask),
          'revision_command': 'confirm_checkpoint',
        },
      ),
      _control(
        'retry_failed',
        '重试失败任务',
        enabled: failed,
        hostCommand: 'long_task_failure_action',
        tone: 'accent',
        disabledReason: '当前没有失败任务。',
        arguments: <String, Object?>{
          ..._taskSelector(activeTask),
          'failure_command': 'retry',
        },
      ),
      _control(
        'skip_failed',
        '跳过失败任务',
        enabled: failed && allowDestructive,
        hostCommand: 'long_task_failure_action',
        tone: 'warm',
        disabledReason: failed ? '跳过属于高风险动作，当前策略未开放。' : '当前没有失败任务。',
        arguments: <String, Object?>{
          ..._taskSelector(activeTask),
          'failure_command': 'skip',
        },
      ),
    ];
  }

  JsonMap _control(
    String id,
    String label, {
    required bool enabled,
    required String hostCommand,
    required String tone,
    String disabledReason = '',
    JsonMap arguments = const <String, Object?>{},
  }) {
    // 中文注释: 控件合同统一结构，方便上层直接映射成按钮、菜单或命令。
    return <String, Object?>{
      'id': id,
      'label': label,
      'enabled': enabled,
      'host_command': hostCommand,
      'tone': tone,
      'disabled_reason': enabled ? '' : disabledReason,
      'arguments': arguments,
    };
  }

  JsonMap _taskSelector(JsonMap task) {
    // 中文注释: 这里只暴露任务定位所需最小字段，避免把完整任务对象挂到按钮参数里。
    final result = <String, Object?>{};
    final path = ValueReaders.stringValue(task['relative_path']).trim();
    final id = ValueReaders.stringValue(task['id']).trim();
    if (path.isNotEmpty) {
      result['relative_path'] = path;
    }
    if (id.isNotEmpty) {
      result['task_id'] = id;
    }
    return result;
  }

  String _noteFromBatch(JsonMap batchPlan, String status) {
    // 中文注释: 运行中心说明优先用批次规划给出的 note，再回退到通用状态文案。
    final note = ValueReaders.stringValue(batchPlan['note']).trim();
    if (note.isNotEmpty) {
      return note;
    }
    if (status == TaskRuntimeConstants.statusRunning) {
      return '长任务可以继续按批次推进。';
    }
    if (status == TaskRuntimeConstants.statusPaused) {
      return '长任务已暂停，等待用户恢复或处理检查点。';
    }
    return '长任务当前没有新的提示。';
  }

  String _controlSummary(List<JsonMap> controls) {
    // 中文注释: 可用操作摘要方便 CLI 和紧凑布局直接展示。
    final enabled = <String>[];
    for (final item in controls) {
      if (ValueReaders.boolValue(item['enabled'])) {
        enabled.add(ValueReaders.stringValue(item['label']));
      }
    }
    return enabled.isEmpty ? '暂无可用操作' : '可操作：${enabled.join('、')}';
  }
}
