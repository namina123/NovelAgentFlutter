import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'task_definition_service.dart';
import 'task_queue_option_service.dart';
import 'task_runtime_constants.dart';
import 'task_selection_service.dart';

class TaskQueuePreflightService {
  TaskQueuePreflightService({
    required TaskQueueOptionService optionService,
    required TaskSelectionService taskSelectionService,
    required TaskDefinitionService taskDefinitionService,
  }) : _optionService = optionService,
       _taskSelectionService = taskSelectionService,
       _taskDefinitionService = taskDefinitionService;

  final TaskQueueOptionService _optionService;
  final TaskSelectionService _taskSelectionService;
  final TaskDefinitionService _taskDefinitionService;

  JsonMap preflightFromTasks(
    List<Object?> tasks, {
    JsonMap options = const <String, Object?>{},
    JsonMap filters = const <String, Object?>{},
    List<Object?> recentRuns = const <Object?>[],
  }) {
    // 中文注释: 队列预检只读任务池和近期运行摘要，目的是回答“能不能跑、为什么会停”。
    final cleanOptions = _optionService.normalizeOptions(options);
    final sortedTasks = _taskSelectionService.sortTasks(
      tasks,
      filters: filters,
    );
    final nextTask = _taskSelectionService.nextRunnableTaskFromTasks(
      sortedTasks,
      filters: filters,
    );
    final nextPostprocess = _taskSelectionService.nextPostprocessTaskFromTasks(
      sortedTasks,
      filters: filters,
    );
    final blockers = queueBlockers(sortedTasks);
    final canRun = nextTask.isNotEmpty;
    return <String, Object?>{
      'ok': true,
      'schema_version': 1,
      'can_run': canRun,
      'options': cleanOptions,
      'task_count': sortedTasks.length,
      'status_counts': statusCounts(sortedTasks),
      'next_task': _taskDefinitionService.taskSummary(nextTask),
      'next_postprocess_task': _taskDefinitionService.taskSummary(
        nextPostprocess,
      ),
      'primary_blocker': canRun ? '' : primaryBlocker(sortedTasks, blockers),
      'blockers': blockers,
      'recent_runs': recentRuns
          .map(ValueReaders.mapValue)
          .toList(growable: false),
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  JsonMap statusCounts(List<Object?> tasks) {
    // 中文注释: 状态统计帮助 UI 快速解释当前任务池结构，不需要读取完整运行记录。
    final counts = <String, Object?>{};
    for (final rawTask in tasks) {
      final task = ValueReaders.mapValue(rawTask);
      var status = ValueReaders.stringValue(task['status']);
      if (status.isEmpty) {
        status = 'unknown';
      }
      counts[status] = ValueReaders.intValue(counts[status]) + 1;
    }
    return counts;
  }

  List<JsonMap> queueBlockers(List<Object?> tasks) {
    // 中文注释: 阻塞项只做解释，不修改任务状态，让宿主可以安全展示“为什么跑不动”。
    final blockers = <JsonMap>[];
    final succeeded = <String, bool>{};
    for (final rawTask in tasks) {
      final task = ValueReaders.mapValue(rawTask);
      if (ValueReaders.stringValue(task['status']) ==
          TaskRuntimeConstants.statusSucceeded) {
        succeeded[ValueReaders.stringValue(task['id'])] = true;
      }
    }
    for (final rawTask in tasks) {
      final task = ValueReaders.mapValue(rawTask);
      final status = ValueReaders.stringValue(task['status']);
      if (status == TaskRuntimeConstants.statusWaitingUser) {
        blockers.add(_blocker('waiting_user', task, '任务正在等待用户确认。'));
      } else if (status == TaskRuntimeConstants.statusPaused) {
        blockers.add(_blocker('paused', task, '任务已暂停，需要用户恢复。'));
      } else if (status == TaskRuntimeConstants.statusFailed) {
        blockers.add(_blocker('failed', task, '任务失败，需要重试或取消。'));
      } else if (TaskRuntimeConstants.runnableStatuses.contains(status)) {
        final missing = _missingDependencies(task, succeeded);
        if (missing.isNotEmpty) {
          final item = _blocker(
            'blocked_dependencies',
            task,
            '任务依赖尚未完成：${missing.join('、')}',
          );
          item['missing_dependencies'] = missing;
          blockers.add(item);
        }
      }
    }
    return blockers;
  }

  String primaryBlocker(List<Object?> tasks, List<Object?> blockers) {
    // 中文注释: 主阻塞原因供短提示使用，优先返回对用户最有行动意义的那一类原因。
    if (tasks.isEmpty) {
      return 'no_tasks';
    }
    for (final reason in <String>[
      'waiting_user',
      'paused',
      'failed',
      'blocked_dependencies',
    ]) {
      for (final raw in blockers) {
        final blocker = ValueReaders.mapValue(raw);
        if (ValueReaders.stringValue(blocker['reason']) == reason) {
          return reason;
        }
      }
    }
    return 'no_runnable_task';
  }

  JsonMap _blocker(String reason, JsonMap task, String note) {
    // 中文注释: 阻塞摘要统一只保留任务定位与一句解释，避免预检结果变得过重。
    return <String, Object?>{
      'reason': reason,
      'note': note,
      'task': _taskDefinitionService.taskSummary(task),
    };
  }

  List<String> _missingDependencies(JsonMap task, Map<String, bool> succeeded) {
    // 中文注释: 依赖缺口单独提取成列表，便于 UI 做高亮或跳转。
    final missing = <String>[];
    for (final dependency in _taskDefinitionService.stringList(
      task['depends_on'],
    )) {
      if (!(succeeded[dependency] ?? false)) {
        missing.add(dependency);
      }
    }
    return missing;
  }
}
