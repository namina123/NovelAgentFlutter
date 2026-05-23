import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'task_definition_service.dart';
import 'task_runtime_constants.dart';

class TaskSelectionService {
  TaskSelectionService({required TaskDefinitionService taskDefinitionService})
    : _taskDefinitionService = taskDefinitionService;

  final TaskDefinitionService _taskDefinitionService;

  List<JsonMap> sortTasks(
    List<Object?> tasks, {
    JsonMap filters = const <String, Object?>{},
  }) {
    // 中文注释: 排序和过滤是纯调度规则，输入任务列表后即可在 core 内完成，不依赖存储。
    final normalized = tasks
        .map(ValueReaders.mapValue)
        .where((item) => item.isNotEmpty)
        .map(_taskDefinitionService.normalizeTask)
        .where((task) => _matchesFilters(task, filters))
        .toList(growable: false);
    final sorted = List<JsonMap>.from(normalized);
    sorted.sort((a, b) {
      final aOrder = _sortOrder(a);
      final bOrder = _sortOrder(b);
      if ((aOrder > 0 || bOrder > 0) && aOrder != bOrder) {
        return aOrder.compareTo(bOrder);
      }
      final aCreated = ValueReaders.stringValue(a['created_at']);
      final bCreated = ValueReaders.stringValue(b['created_at']);
      if (aCreated != bCreated) {
        return aCreated.compareTo(bCreated);
      }
      return ValueReaders.stringValue(
        a['title'],
      ).compareTo(ValueReaders.stringValue(b['title']));
    });
    return sorted;
  }

  JsonMap nextRunnableTaskFromTasks(
    List<Object?> tasks, {
    JsonMap filters = const <String, Object?>{},
  }) {
    // 中文注释: 下一个可执行任务只依赖任务状态和依赖关系，不需要知道任务来自哪个宿主。
    final sortedTasks = sortTasks(tasks, filters: filters);
    final succeededById = <String, bool>{};
    for (final task in sortedTasks) {
      if (ValueReaders.stringValue(task['status']) ==
          TaskRuntimeConstants.statusSucceeded) {
        succeededById[ValueReaders.stringValue(task['id'])] = true;
      }
    }
    for (final task in sortedTasks) {
      if (!TaskRuntimeConstants.runnableStatuses.contains(
        ValueReaders.stringValue(task['status']),
      )) {
        continue;
      }
      if (!dependenciesSatisfied(task, succeededById)) {
        continue;
      }
      return ValueReaders.deepCopyMap(task);
    }
    return <String, Object?>{};
  }

  JsonMap nextPostprocessTaskFromTasks(
    List<Object?> tasks, {
    JsonMap filters = const <String, Object?>{},
  }) {
    // 中文注释: 后处理任务选择规则保持独立，避免和普通调度任务的优先级纠缠在一起。
    final sortedTasks = sortTasks(tasks, filters: filters);
    for (final task in sortedTasks) {
      if (ValueReaders.stringValue(task['status']) !=
          TaskRuntimeConstants.statusWaitingUser) {
        continue;
      }
      final taskType = ValueReaders.stringValue(task['task_type']);
      if (<String>['review', 'planning', 'checkpoint'].contains(taskType)) {
        continue;
      }
      if (ValueReaders.stringValue(
        task['atomic_execution_path'],
      ).trim().isEmpty) {
        continue;
      }
      final outputs = _taskDefinitionService.stringList(task['output_paths']);
      if (outputs.isEmpty) {
        continue;
      }
      return ValueReaders.deepCopyMap(task);
    }
    return <String, Object?>{};
  }

  bool dependenciesSatisfied(JsonMap task, Map<String, bool> succeededById) {
    // 中文注释: 依赖校验只看成功任务集合，防止章节队列越过尚未完成的前置任务。
    for (final dependency in _taskDefinitionService.stringList(
      task['depends_on'],
    )) {
      if (dependency.isEmpty) {
        continue;
      }
      if (!(succeededById[dependency] ?? false)) {
        return false;
      }
    }
    return true;
  }

  bool matchesFilters(JsonMap task, JsonMap filters) {
    // 中文注释: 过滤规则目前只支持 mode/status/task_type，保持简单可演化。
    return _matchesFilters(task, filters);
  }

  int sortOrder(JsonMap task) {
    // 中文注释: sort_order 提取对外暴露为独立方法，方便队列预检和测试共用。
    return _sortOrder(task);
  }

  bool _matchesFilters(JsonMap task, JsonMap filters) {
    // 中文注释: 内部过滤实现集中在这里，避免每个选择函数重复拼相同条件。
    for (final key in <String>['mode', 'status', 'task_type']) {
      if (!filters.containsKey(key)) {
        continue;
      }
      final expected = ValueReaders.stringValue(filters[key]).trim();
      if (expected.isEmpty) {
        continue;
      }
      if (ValueReaders.stringValue(task[key]) != expected) {
        return false;
      }
    }
    return true;
  }

  int _sortOrder(JsonMap task) {
    // 中文注释: 排序字段优先从 metadata.sort_order 读取，没有时回退为 0。
    final metadata = ValueReaders.mapValue(task['metadata']);
    return ValueReaders.intValue(metadata['sort_order']);
  }
}
