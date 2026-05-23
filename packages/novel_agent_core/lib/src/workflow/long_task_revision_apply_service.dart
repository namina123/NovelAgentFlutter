import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'long_task_run_path_service.dart';
import 'task_definition_service.dart';
import 'task_transition_service.dart';
import 'task_runtime_constants.dart';

class LongTaskRevisionApplyService {
  LongTaskRevisionApplyService({
    required LongTaskRunPathService runPathService,
    required TaskTransitionService transitionService,
    required TaskDefinitionService taskDefinitionService,
  }) : _runPathService = runPathService,
       _transitionService = transitionService,
       _taskDefinitionService = taskDefinitionService;

  final LongTaskRunPathService _runPathService;
  final TaskTransitionService _transitionService;
  final TaskDefinitionService _taskDefinitionService;

  JsonMap applyRevisionPlan(
    List<Object?> tasks,
    JsonMap revision, {
    String createdAt = '',
  }) {
    // 中文注释: 修订应用在 core 里只改内存任务列表，宿主后续如何落盘由 adapter 或 app 自己决定。
    if (!ValueReaders.boolValue(revision['ok'])) {
      return <String, Object?>{
        'ok': false,
        'error': ValueReaders.stringValue(
          revision['error'],
          'Revision plan is not valid.',
        ),
        'tasks': ValueReaders.deepCopyList(ValueReaders.objectList(tasks)),
        'changed_paths': <Object?>[],
        'applied_update_count': 0,
      };
    }
    final nextTasks = ValueReaders.mapList(tasks)
        .map(_taskDefinitionService.normalizeTask)
        .map(ValueReaders.deepCopyMap)
        .toList(growable: true);
    final changedPaths = <String>[];
    final changedTaskIds = <String>[];
    final errors = <String>[];
    final now = createdAt.isEmpty
        ? DateTime.now().toIso8601String()
        : createdAt;

    for (final rawUpdate in ValueReaders.objectList(revision['task_updates'])) {
      final update = ValueReaders.mapValue(rawUpdate);
      if (update.isEmpty) {
        continue;
      }
      final index = _indexFromSelector(nextTasks, update);
      if (index < 0) {
        errors.add('Task update target not found.');
        continue;
      }
      final updated = _applyUpdate(nextTasks[index], update, now, errors);
      nextTasks[index] = updated;
      _addChangedPath(
        changedPaths,
        ValueReaders.stringValue(updated['relative_path']),
      );
      _addChangedTaskId(
        changedTaskIds,
        ValueReaders.stringValue(updated['id']),
      );
    }

    for (final rawTask in ValueReaders.objectList(revision['new_tasks'])) {
      final task = _taskDefinitionService.normalizeTask(
        ValueReaders.mapValue(rawTask),
      );
      if (task.isEmpty) {
        continue;
      }
      final newTask = ValueReaders.deepCopyMap(task);
      final relativePath = _runPathService.taskPathForNewTask(newTask);
      newTask['relative_path'] = relativePath;
      if (_indexFromSelector(nextTasks, <String, Object?>{
            'relative_path': relativePath,
          }) >=
          0) {
        errors.add('Task already exists: $relativePath');
        continue;
      }
      nextTasks.add(newTask);
      _addChangedPath(changedPaths, relativePath);
      _addChangedTaskId(
        changedTaskIds,
        ValueReaders.stringValue(newTask['id']),
      );
    }

    nextTasks.sort((left, right) {
      final leftOrder = ValueReaders.intValue(
        ValueReaders.mapValue(left['metadata'])['sort_order'],
      );
      final rightOrder = ValueReaders.intValue(
        ValueReaders.mapValue(right['metadata'])['sort_order'],
      );
      if (leftOrder != rightOrder) {
        return leftOrder.compareTo(rightOrder);
      }
      return ValueReaders.stringValue(
        left['id'],
      ).compareTo(ValueReaders.stringValue(right['id']));
    });

    return <String, Object?>{
      'ok': errors.isEmpty,
      'error': errors.join('；'),
      'tasks': nextTasks,
      'changed_paths': changedPaths,
      'changed_task_ids': changedTaskIds,
      'applied_update_count': changedPaths.length,
    };
  }

  int _indexFromSelector(List<JsonMap> tasks, JsonMap selector) {
    // 中文注释: 修订补丁优先按 relative_path 命中，其次按 task_id，和旧宿主逻辑保持一致。
    final relativePath = ValueReaders.stringValue(
      selector['relative_path'],
    ).trim();
    final taskId = ValueReaders.stringValue(
      selector['task_id'],
      ValueReaders.stringValue(selector['id']),
    ).trim();
    for (var index = 0; index < tasks.length; index += 1) {
      final task = tasks[index];
      if (relativePath.isNotEmpty &&
          ValueReaders.stringValue(task['relative_path']).trim() ==
              relativePath) {
        return index;
      }
      if (taskId.isNotEmpty &&
          ValueReaders.stringValue(task['id']).trim() == taskId) {
        return index;
      }
    }
    return -1;
  }

  JsonMap _applyUpdate(
    JsonMap task,
    JsonMap update,
    String createdAt,
    List<String> errors,
  ) {
    // 中文注释: 任务补丁会更新状态、通用字段和 history，但不会擅自改动无关业务数据。
    final next = ValueReaders.deepCopyMap(task);
    final nextStatus = ValueReaders.stringValue(
      update['status'],
      ValueReaders.stringValue(
        task['status'],
        TaskRuntimeConstants.statusQueued,
      ),
    );
    final currentStatus = ValueReaders.stringValue(
      task['status'],
      TaskRuntimeConstants.statusQueued,
    );
    if (!_transitionService.canTransition(currentStatus, nextStatus)) {
      errors.add('Illegal task transition: $currentStatus -> $nextStatus');
    } else {
      next['status'] = nextStatus;
    }

    final fieldUpdates = ValueReaders.mapValue(update['field_updates']);
    for (final field in const <String>[
      'title',
      'goal',
      'brief',
      'tool_hint',
      'source_paths',
      'output_paths',
    ]) {
      if (!fieldUpdates.containsKey(field)) {
        continue;
      }
      next[field] = fieldUpdates[field];
    }

    final note = ValueReaders.stringValue(
      update['note'],
      'Long task revision applied.',
    );
    final history = ValueReaders.objectList(next['history']);
    history.add(<String, Object?>{
      'status': ValueReaders.stringValue(next['status']),
      'note': note,
      'created_at': createdAt,
    });
    next['history'] = history;
    next['updated_at'] = ValueReaders.stringValue(
      update['updated_at'],
      createdAt,
    );
    return next;
  }

  void _addChangedPath(List<String> changedPaths, String path) {
    // 中文注释: 变更路径去重后返回，便于宿主只写或刷新真正受影响的文件。
    final clean = path.trim();
    if (clean.isNotEmpty && !changedPaths.contains(clean)) {
      changedPaths.add(clean);
    }
  }

  void _addChangedTaskId(List<String> changedTaskIds, String taskId) {
    // 中文注释: 变更任务 id 供上层做列表刷新或聚焦定位。
    final clean = taskId.trim();
    if (clean.isNotEmpty && !changedTaskIds.contains(clean)) {
      changedTaskIds.add(clean);
    }
  }
}
