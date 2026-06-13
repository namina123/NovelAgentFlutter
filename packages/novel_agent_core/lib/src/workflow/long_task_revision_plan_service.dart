import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'long_task_dynamic_task_factory_service.dart';
import 'task_runtime_constants.dart';

class LongTaskRevisionPlanService {
  LongTaskRevisionPlanService({
    required LongTaskDynamicTaskFactoryService dynamicTaskFactoryService,
  }) : _dynamicTaskFactoryService = dynamicTaskFactoryService;

  final LongTaskDynamicTaskFactoryService _dynamicTaskFactoryService;

  JsonMap buildRevisionPlan(
    JsonMap record,
    List<Object?> tasks,
    String command, {
    JsonMap arguments = const <String, Object?>{},
    String createdAt = '',
  }) {
    // 中文注释: 长任务修订计划只输出补丁和新增任务建议，不直接改写任务列表或运行记录。
    final cleanCommand = command.trim().toLowerCase();
    final now = createdAt.isEmpty
        ? DateTime.now().toIso8601String()
        : createdAt;
    if (cleanCommand.isEmpty) {
      return _invalidResult('', '缺少长任务修订命令。', now);
    }
    final result = _resultBase(cleanCommand, now);
    final updates = <Object?>[];
    final newTasks = <Object?>[];

    if (cleanCommand == 'confirm_checkpoint') {
      final taskId = ValueReaders.stringValue(arguments['task_id']).trim();
      final target = taskId.isEmpty
          ? _firstReadyCheckpoint(tasks)
          : _taskAt(tasks, _indexById(tasks, taskId));
      if (target.isEmpty || !_isReadyCheckpoint(target, tasks)) {
        return _invalidResult(cleanCommand, '没有找到可确认的检查点任务。', now);
      }
      updates.add(
        _updatePatch(
          target,
          TaskRuntimeConstants.statusSucceeded,
          ValueReaders.stringValue(arguments['note'], '用户确认检查点，长任务可继续。'),
          now,
        ),
      );
    } else if (cleanCommand == 'revise_task') {
      final taskId = ValueReaders.stringValue(
        arguments['task_id'],
        ValueReaders.stringValue(record['last_task_id']),
      ).trim();
      final target = _taskAt(tasks, _indexById(tasks, taskId));
      if (target.isEmpty) {
        return _invalidResult(cleanCommand, '没有找到需要修订的任务。', now);
      }
      final patch = _updatePatch(
        target,
        ValueReaders.stringValue(
          arguments['status'],
          TaskRuntimeConstants.statusQueued,
        ),
        ValueReaders.stringValue(arguments['note'], '用户要求修订该任务后重试。'),
        now,
      );
      final fieldUpdates = <String, Object?>{};
      for (final field in const <String>[
        'title',
        'goal',
        'brief',
        'tool_hint',
        'source_paths',
        'output_paths',
      ]) {
        if (arguments.containsKey(field)) {
          fieldUpdates[field] = arguments[field];
        }
      }
      if (fieldUpdates.isNotEmpty) {
        patch['field_updates'] = fieldUpdates;
      }
      updates.add(patch);
    } else if (cleanCommand == 'insert_checkpoint') {
      newTasks.add(
        _dynamicTaskFactoryService.buildCheckpointTask(
          record,
          tasks,
          arguments,
          createdAt: now,
        ),
      );
    } else if (cleanCommand == 'append_chapter') {
      newTasks.add(
        _dynamicTaskFactoryService.buildChapterTask(
          record,
          tasks,
          arguments,
          createdAt: now,
        ),
      );
    } else if (cleanCommand == 'pause_only') {
      result['host_action'] = 'pause_run';
      result['note'] = ValueReaders.stringValue(
        arguments['note'],
        '用户要求暂停长任务。',
      );
    } else {
      return _invalidResult(cleanCommand, '未知长任务修订命令。', now);
    }

    result['task_updates'] = updates;
    result['new_tasks'] = newTasks;
    result['note'] = ValueReaders.stringValue(
      arguments['note'],
      ValueReaders.stringValue(result['note'], '长任务修订计划已生成。'),
    );
    result['changed_task_count'] = updates.length + newTasks.length;
    return result;
  }

  JsonMap _resultBase(String command, String createdAt) {
    // 中文注释: 修订计划的通用合同在这里集中，避免不同命令返回不同结构。
    return <String, Object?>{
      'ok': true,
      'command': command,
      'created_at': createdAt,
      'task_updates': <Object?>[],
      'new_tasks': <Object?>[],
      'warnings': <Object?>[],
      'host_action': 'apply_task_patches',
    };
  }

  JsonMap _invalidResult(String command, String message, String createdAt) {
    // 中文注释: 非法命令或目标缺失时返回统一错误合同，宿主无需猜错误字段。
    return <String, Object?>{
      ..._resultBase(command, createdAt),
      'ok': false,
      'error': message,
      'host_action': 'none',
    };
  }

  JsonMap _updatePatch(
    JsonMap task,
    String status,
    String note,
    String createdAt,
  ) {
    // 中文注释: 任务更新补丁只表达需要修改的字段，不携带完整任务实体。
    return <String, Object?>{
      'task_id': ValueReaders.stringValue(task['id']),
      'relative_path': ValueReaders.stringValue(task['relative_path']),
      'status': status,
      'note': note,
      'updated_at': createdAt,
    };
  }

  JsonMap _taskAt(List<Object?> tasks, int index) {
    // 中文注释: 按索引读取是 revision 场景的最小足够能力。
    if (index < 0 || index >= tasks.length) {
      return <String, Object?>{};
    }
    return ValueReaders.mapValue(tasks[index]);
  }

  int _indexById(List<Object?> tasks, String taskId) {
    // 中文注释: 当前任务规模下线性查找足够稳定，也更便于保持纯规则实现。
    for (var index = 0; index < tasks.length; index += 1) {
      final task = ValueReaders.mapValue(tasks[index]);
      if (task.isNotEmpty && ValueReaders.stringValue(task['id']) == taskId) {
        return index;
      }
    }
    return -1;
  }

  JsonMap _firstReadyCheckpoint(List<Object?> tasks) {
    // 中文注释: confirm_checkpoint 只能命中依赖已满足的检查点，避免前序章节仍在运行时被提前确认。
    for (final rawTask in tasks) {
      final task = ValueReaders.mapValue(rawTask);
      if (_isReadyCheckpoint(task, tasks)) {
        return task;
      }
    }
    return <String, Object?>{};
  }

  bool _isReadyCheckpoint(JsonMap task, List<Object?> tasks) {
    if (ValueReaders.stringValue(task['task_type']) != 'checkpoint') {
      return false;
    }
    final status = ValueReaders.stringValue(task['status']);
    if (!<String>{
      TaskRuntimeConstants.statusQueued,
      TaskRuntimeConstants.statusWaitingUser,
    }.contains(status)) {
      return false;
    }
    final succeeded = _succeededMap(tasks);
    for (final dependency in ValueReaders.stringList(task['depends_on'])) {
      if (dependency.isNotEmpty && !(succeeded[dependency] ?? false)) {
        return false;
      }
    }
    return true;
  }

  Map<String, bool> _succeededMap(List<Object?> tasks) {
    final result = <String, bool>{};
    for (final rawTask in tasks) {
      final task = ValueReaders.mapValue(rawTask);
      if (ValueReaders.stringValue(task['status']) ==
          TaskRuntimeConstants.statusSucceeded) {
        final taskId = ValueReaders.stringValue(task['id']).trim();
        if (taskId.isNotEmpty) {
          result[taskId] = true;
        }
      }
    }
    return result;
  }
}
