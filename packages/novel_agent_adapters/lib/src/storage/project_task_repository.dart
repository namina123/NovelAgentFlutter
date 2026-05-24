import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_json_document_service.dart';

class ProjectTaskRepository {
  ProjectTaskRepository({
    required ProjectWorkspacePort workspacePort,
    ProjectJsonDocumentService? jsonDocumentService,
    TaskDefinitionService? taskDefinitionService,
    LongTaskPathPolicyService? pathPolicyService,
    TaskTransitionService? taskTransitionService,
  }) : _workspacePort = workspacePort,
       _jsonDocumentService =
           jsonDocumentService ??
           ProjectJsonDocumentService(workspacePort: workspacePort),
       _taskDefinitionService =
           taskDefinitionService ?? TaskDefinitionService(),
       _pathPolicyService = pathPolicyService ?? LongTaskPathPolicyService(),
       _taskTransitionService =
           taskTransitionService ?? TaskTransitionService();

  final ProjectWorkspacePort _workspacePort;
  final ProjectJsonDocumentService _jsonDocumentService;
  final TaskDefinitionService _taskDefinitionService;
  final LongTaskPathPolicyService _pathPolicyService;
  final TaskTransitionService _taskTransitionService;

  ProjectWorkspacePort get workspacePort => _workspacePort;

  Future<List<JsonMap>> listTasks(
    ProjectDescriptor project, {
    JsonMap filters = const <String, Object?>{},
  }) async {
    // 中文注释: 仓储层负责把 tasks/ 文件还原成规范任务列表，过滤仍复用 core 规则。
    final paths = await _jsonDocumentService.listPaths(
      project.rootPath,
      prefix: 'tasks/',
      suffix: '.json',
    );
    final result = <JsonMap>[];
    for (final path in paths) {
      final document = await _jsonDocumentService.readJsonMap(
        project.rootPath,
        path,
      );
      if (document.isEmpty) {
        continue;
      }
      final task = _taskDefinitionService.normalizeTask(document)
        ..['relative_path'] = path;
      if (_taskDefinitionService.stringList(filters.keys).isNotEmpty &&
          !_matchesFilters(task, filters)) {
        continue;
      }
      result.add(task);
    }
    return result;
  }

  Future<JsonMap> loadTask(ProjectDescriptor project, JsonMap selector) async {
    // 中文注释: 任务定位优先走 relative_path，其次按 id 扫描，兼容旧项目的两种选择方式。
    final relativePath = _pathPolicyService.safeProjectPath(
      ValueReaders.stringValue(selector['relative_path']),
    );
    if (relativePath.isNotEmpty) {
      final document = await _jsonDocumentService.readJsonMap(
        project.rootPath,
        relativePath,
      );
      if (document.isEmpty) {
        return <String, Object?>{};
      }
      final task = _taskDefinitionService.normalizeTask(document)
        ..['relative_path'] = relativePath;
      return task;
    }
    final taskId = ValueReaders.stringValue(
      selector['task_id'],
      ValueReaders.stringValue(selector['id']),
    ).trim();
    if (taskId.isEmpty) {
      return <String, Object?>{};
    }
    final tasks = await listTasks(project);
    for (final task in tasks) {
      if (ValueReaders.stringValue(task['id']) == taskId) {
        return task;
      }
    }
    return <String, Object?>{};
  }

  Future<JsonMap> saveTask(ProjectDescriptor project, JsonMap task) async {
    // 中文注释: 单任务保存统一补齐 relative_path 和时间戳，避免上层手写文件名规则。
    final normalized = _taskDefinitionService.normalizeTask(task);
    final relativePath = _resolvedRelativePath(normalized);
    final now = DateTime.now().toIso8601String();
    final document = ValueReaders.deepCopyMap(normalized)
      ..['relative_path'] = relativePath
      ..['updated_at'] = ValueReaders.stringValue(
        normalized['updated_at'],
        now,
      );
    if (ValueReaders.stringValue(document['created_at']).trim().isEmpty) {
      document['created_at'] = now;
    }
    await _jsonDocumentService.writeJsonMap(
      project.rootPath,
      relativePath,
      document,
    );
    return document;
  }

  Future<List<JsonMap>> saveTasks(
    ProjectDescriptor project,
    List<Object?> tasks,
  ) async {
    // 中文注释: 批量保存保留输入顺序，方便计划生成后直接把返回列表继续交给上层展示。
    final result = <JsonMap>[];
    for (final rawTask in tasks) {
      final saved = await saveTask(project, ValueReaders.mapValue(rawTask));
      if (saved.isNotEmpty) {
        result.add(saved);
      }
    }
    return result;
  }

  Future<JsonMap> transitionTask(
    ProjectDescriptor project,
    JsonMap selector,
    String status, {
    String note = '',
    JsonMap extra = const <String, Object?>{},
  }) async {
    // 中文注释: 状态迁移在仓储层只负责读改写，具体状态机合法性仍由 core 判断。
    final task = await loadTask(project, selector);
    if (task.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Task not found.',
        'relative_path': '',
      };
    }
    final currentStatus = ValueReaders.stringValue(
      task['status'],
      TaskRuntimeConstants.statusQueued,
    );
    if (!_taskTransitionService.canTransition(currentStatus, status)) {
      return <String, Object?>{
        'ok': false,
        'error': 'Illegal task transition: $currentStatus -> $status',
        'relative_path': ValueReaders.stringValue(task['relative_path']),
      };
    }
    final next = ValueReaders.deepCopyMap(task)
      ..['status'] = status
      ..['updated_at'] = DateTime.now().toIso8601String();
    final history = ValueReaders.objectList(next['history']);
    history.add(<String, Object?>{
      'status': status,
      'note': note.trim(),
      'created_at': ValueReaders.stringValue(next['updated_at']),
    });
    next['history'] = history;
    for (final entry in extra.entries) {
      next[entry.key] = entry.value;
    }
    final saved = await saveTask(project, next);
    return <String, Object?>{
      'ok': true,
      'relative_path': ValueReaders.stringValue(saved['relative_path']),
      'task': saved,
    };
  }

  Future<List<JsonMap>> listRunRecords(
    ProjectDescriptor project, {
    required String prefix,
    int limit = 10,
  }) async {
    // 中文注释: 运行记录列表统一按 updated_at 倒序输出，供任务页和 CLI 最近记录共用。
    final paths = await _jsonDocumentService.listPaths(
      project.rootPath,
      prefix: prefix,
      suffix: '.json',
    );
    final records = <JsonMap>[];
    for (final path in paths) {
      final document = await _jsonDocumentService.readJsonMap(
        project.rootPath,
        path,
      );
      if (document.isEmpty) {
        continue;
      }
      records.add(ValueReaders.deepCopyMap(document)..['relative_path'] = path);
    }
    records.sort((left, right) {
      final leftUpdated = ValueReaders.stringValue(left['updated_at']);
      final rightUpdated = ValueReaders.stringValue(right['updated_at']);
      return rightUpdated.compareTo(leftUpdated);
    });
    if (records.length <= limit) {
      return records;
    }
    return records.take(limit).toList(growable: false);
  }

  Future<JsonMap> loadRecord(
    ProjectDescriptor project,
    String relativePath,
  ) async {
    // 中文注释: 运行记录和执行包详情都走同一 JSON 读取入口，避免再生一套 record 仓储。
    final document = await _jsonDocumentService.readJsonMap(
      project.rootPath,
      relativePath,
    );
    if (document.isEmpty) {
      return <String, Object?>{};
    }
    return ValueReaders.deepCopyMap(document)..['relative_path'] = relativePath;
  }

  Future<JsonMap> saveRecord(
    ProjectDescriptor project,
    String relativePath,
    JsonMap record,
  ) async {
    // 中文注释: 通用运行记录保存给 task queue 和 long task run 复用，避免新增第二套 JSON 写法。
    await _jsonDocumentService.writeJsonMap(
      project.rootPath,
      relativePath,
      record,
    );
    return ValueReaders.deepCopyMap(record)..['relative_path'] = relativePath;
  }

  Future<String?> readTextFile(ProjectDescriptor project, String relativePath) {
    // 中文注释: 任务仓储偶尔需要读取备份或 diff 相关正文，这里透传工作区读取即可。
    return _workspacePort.readTextFile(project.rootPath, relativePath);
  }

  Future<void> writeTextFile(
    ProjectDescriptor project,
    String relativePath,
    String content,
  ) {
    // 中文注释: Markdown 摘要类产物由仓储层统一落盘，和 JSON 记录保持同一个项目边界。
    return _workspacePort.writeTextFile(
      project.rootPath,
      relativePath,
      content,
    );
  }

  bool _matchesFilters(JsonMap task, JsonMap filters) {
    // 中文注释: 仓储层过滤保持极轻，只承担文件读取后的初筛。
    for (final entry in filters.entries) {
      final expected = ValueReaders.stringValue(entry.value).trim();
      if (expected.isEmpty) {
        continue;
      }
      if (ValueReaders.stringValue(task[entry.key]) != expected) {
        return false;
      }
    }
    return true;
  }

  String _resolvedRelativePath(JsonMap task) {
    // 中文注释: 任务路径统一按 id 落到 tasks/，让运行期新增任务与初始计划任务命名一致。
    final current = _pathPolicyService.safeProjectPath(
      ValueReaders.stringValue(task['relative_path']),
    );
    if (current.startsWith('tasks/') &&
        current.toLowerCase().endsWith('.json')) {
      return current;
    }
    final taskId = _pathPolicyService.safeId(
      ValueReaders.stringValue(
        task['id'],
        'task_${DateTime.now().microsecondsSinceEpoch}',
      ),
      fallbackPrefix: 'task',
    );
    return 'tasks/$taskId.json';
  }
}
