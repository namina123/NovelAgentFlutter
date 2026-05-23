import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'long_task_mode_strategy_service.dart';
import 'task_runtime_constants.dart';

class LongTaskRunActionService {
  LongTaskRunActionService({
    required LongTaskModeStrategyService strategyService,
  }) : _strategyService = strategyService;

  final LongTaskModeStrategyService _strategyService;

  JsonMap nextAction(
    JsonMap record,
    List<Object?> tasks, {
    JsonMap options = const <String, Object?>{},
  }) {
    // 中文注释: 下一步动作只依赖运行记录、任务状态和运行选项，是纯调度规则。
    final status = ValueReaders.stringValue(
      record['status'],
      TaskRuntimeConstants.statusRunning,
    );
    if (ValueReaders.boolValue(options['stop_requested'])) {
      return _actionResult('stop', 'manual_stop', '用户请求停止长任务。');
    }
    if (ValueReaders.boolValue(record['pause_requested']) ||
        ValueReaders.boolValue(options['pause_requested']) ||
        status == TaskRuntimeConstants.statusPaused) {
      return _actionResult('pause', 'manual_pause', '长任务已暂停，可稍后从运行记录恢复。');
    }
    if (<String>[
      TaskRuntimeConstants.statusCancelled,
      TaskRuntimeConstants.statusFailed,
      TaskRuntimeConstants.statusSucceeded,
    ].contains(status)) {
      return _actionResult('finish', 'terminal_record', '运行记录已经处于终态。');
    }
    if (tasks.isEmpty) {
      return _actionResult('wait_user', 'no_tasks', '当前长任务没有可调度任务。');
    }

    final cleanOptions = ValueReaders.mapValue(
      record['options'].runtimeType == Map ? record['options'] : options,
    );
    final failed = _firstTaskWithStatus(
      tasks,
      TaskRuntimeConstants.statusFailed,
    );
    if (failed.isNotEmpty &&
        ValueReaders.boolValue(cleanOptions['stop_on_failed_task'], true)) {
      return _actionResult(
        'pause',
        'failed_task',
        '检测到失败任务，暂停等待重试、跳过或人工修复。',
        task: failed,
      );
    }
    final waiting = _firstDependencyReadyTaskWithStatus(
      tasks,
      TaskRuntimeConstants.statusWaitingUser,
    );
    if (waiting.isNotEmpty &&
        ValueReaders.boolValue(cleanOptions['stop_on_user_checkpoint'], true)) {
      return _actionResult(
        'wait_user',
        'waiting_user_checkpoint',
        '长任务到达人工检查点，等待用户确认后继续。',
        task: waiting,
      );
    }
    final task = _firstRunnableTask(tasks);
    if (task.isEmpty) {
      if (_allTasksTerminal(tasks)) {
        return _actionResult('finish', 'all_tasks_terminal', '长任务队列已全部进入终态。');
      }
      return _actionResult(
        'wait_user',
        'blocked_dependencies',
        '当前没有依赖满足的可运行任务。',
      );
    }

    final action = _actionForTask(task);
    return <String, Object?>{
      ..._actionResult(
        action,
        action == 'wait_user' ? 'checkpoint_task' : 'next_runnable_task',
        action == 'wait_user' ? '下一任务是人工检查点。' : '下一任务可交给模型执行。',
        task: task,
      ),
      'agent_role': _agentRoleForTask(
        task,
        ValueReaders.stringValue(record['mode']),
      ),
      'strategy': _strategyService.modeStrategy(
        ValueReaders.stringValue(record['mode']),
      ),
      'should_consume_guidance_before_tool':
          action == 'call_model' &&
          ValueReaders.boolValue(cleanOptions['allow_stream_guidance'], true),
    };
  }

  JsonMap _actionResult(
    String action,
    String reason,
    String note, {
    JsonMap task = const <String, Object?>{},
  }) {
    // 中文注释: 调度结果统一包装成同一合同，避免宿主层分支判断字段不一致。
    return <String, Object?>{
      'ok': true,
      'action': action,
      'reason': reason,
      'note': note,
      'task': <String, Object?>{
        'id': ValueReaders.stringValue(task['id']),
        'title': ValueReaders.stringValue(task['title']),
        'task_type': ValueReaders.stringValue(task['task_type']),
        'status': ValueReaders.stringValue(task['status']),
        'relative_path': ValueReaders.stringValue(task['relative_path']),
      },
    };
  }

  JsonMap _firstTaskWithStatus(List<Object?> tasks, String status) {
    // 中文注释: 这个查找是长任务调度的基础操作，保持为纯状态扫描即可。
    for (final rawTask in tasks) {
      final task = ValueReaders.mapValue(rawTask);
      if (ValueReaders.stringValue(task['status']) == status) {
        return task;
      }
    }
    return <String, Object?>{};
  }

  JsonMap _firstDependencyReadyTaskWithStatus(
    List<Object?> tasks,
    String status,
  ) {
    // 中文注释: waiting_user 任务也要先确认依赖满足，避免未完成前置节点就提前展示检查点。
    final succeeded = _succeededMap(tasks);
    for (final rawTask in tasks) {
      final task = ValueReaders.mapValue(rawTask);
      if (ValueReaders.stringValue(task['status']) == status &&
          _missingDependencies(task, succeeded).isEmpty) {
        return task;
      }
    }
    return <String, Object?>{};
  }

  JsonMap _firstRunnableTask(List<Object?> tasks) {
    // 中文注释: 可执行任务必须同时满足状态可运行且依赖全部完成。
    final succeeded = _succeededMap(tasks);
    for (final rawTask in tasks) {
      final task = ValueReaders.mapValue(rawTask);
      if (!<String>[
        TaskRuntimeConstants.statusQueued,
        TaskRuntimeConstants.statusRetrying,
      ].contains(ValueReaders.stringValue(task['status']))) {
        continue;
      }
      if (_missingDependencies(task, succeeded).isEmpty) {
        return task;
      }
    }
    return <String, Object?>{};
  }

  Map<String, bool> _succeededMap(List<Object?> tasks) {
    // 中文注释: 依赖判断只关心成功任务集合，这里先建一个轻量索引。
    final result = <String, bool>{};
    for (final rawTask in tasks) {
      final task = ValueReaders.mapValue(rawTask);
      if (ValueReaders.stringValue(task['status']) ==
          TaskRuntimeConstants.statusSucceeded) {
        result[ValueReaders.stringValue(task['id'])] = true;
      }
    }
    return result;
  }

  List<String> _missingDependencies(JsonMap task, Map<String, bool> succeeded) {
    // 中文注释: 缺失依赖列表可以被上层继续复用做解释和预检。
    final result = <String>[];
    for (final dependency in ValueReaders.stringList(task['depends_on'])) {
      if (dependency.isNotEmpty && !(succeeded[dependency] ?? false)) {
        result.add(dependency);
      }
    }
    return result;
  }

  bool _allTasksTerminal(List<Object?> tasks) {
    // 中文注释: 当所有任务都终态时，调度器就可以给宿主 finish 信号。
    if (tasks.isEmpty) {
      return false;
    }
    for (final rawTask in tasks) {
      final task = ValueReaders.mapValue(rawTask);
      if (!<String>[
        TaskRuntimeConstants.statusSucceeded,
        TaskRuntimeConstants.statusCancelled,
      ].contains(ValueReaders.stringValue(task['status']))) {
        return false;
      }
    }
    return true;
  }

  String _actionForTask(JsonMap task) {
    // 中文注释: checkpoint 和 waiting_user 任务都只会触发 wait_user，不直接调用模型。
    final taskType = ValueReaders.stringValue(task['task_type'], 'chapter');
    final status = ValueReaders.stringValue(task['status']);
    if (status == TaskRuntimeConstants.statusWaitingUser ||
        taskType == 'checkpoint') {
      return 'wait_user';
    }
    return 'call_model';
  }

  String _agentRoleForTask(JsonMap task, String mode) {
    // 中文注释: 这里给运行层一个轻量角色标签，供提示事务和运行中心直接消费。
    final taskType = ValueReaders.stringValue(task['task_type'], 'chapter');
    final metadata = ValueReaders.mapValue(task['metadata']);
    if (taskType == 'planning') {
      return 'planner';
    }
    if (taskType == 'review') {
      return 'reviewer';
    }
    if (taskType == 'revision') {
      return 'editor';
    }
    if (mode == TaskRuntimeConstants.modeSeedToFullNovel &&
        ValueReaders.stringValue(metadata['stage']) == 'sample') {
      return 'sample_writer';
    }
    return 'chapter_writer';
  }
}
