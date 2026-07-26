import 'dart:convert';

import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_tool_path_policy.dart';
import 'project_tool_result_factory.dart';

class ProjectTaskToolExecutor {
  ProjectTaskToolExecutor({
    required ProjectToolHostPort hostPort,
    ProjectToolPathPolicy? pathPolicy,
    ProjectToolResultFactory? resultFactory,
    TaskDefinitionService? taskDefinitionService,
  }) : _hostPort = hostPort,
       _pathPolicy = pathPolicy ?? ProjectToolPathPolicy(),
       _resultFactory = resultFactory ?? ProjectToolResultFactory(),
       _taskDefinitionService =
           taskDefinitionService ?? TaskDefinitionService();

  final ProjectToolHostPort _hostPort;
  final ProjectToolPathPolicy _pathPolicy;
  final ProjectToolResultFactory _resultFactory;
  final TaskDefinitionService _taskDefinitionService;

  Future<JsonMap> setAgentTasks(
    ProjectDescriptor project,
    JsonMap arguments,
  ) async {
    // 中文注释: 计划型任务也要落成真实任务文件，这样 mark_task_status、GUI 和 CLI 才能看到同一批任务实体。
    final goal = ValueReaders.stringValue(arguments['goal']);
    final workflowTaskContext = ValueReaders.mapValue(
      arguments['_workflow_task_context'],
    );
    final tasks = ValueReaders.objectList(arguments['tasks'])
        .map(ValueReaders.mapValue)
        .where((task) => task.isNotEmpty)
        .toList(growable: false);
    final changedPaths = <Object?>[];
    final normalizedTasks = <Object?>[];
    for (final task in tasks) {
      final enrichedTask =
          workflowTaskContext.isEmpty ||
              ValueReaders.mapValue(task['_workflow_task_context']).isNotEmpty
          ? task
          : <String, Object?>{
              ...ValueReaders.deepCopyMap(task),
              '_workflow_task_context': ValueReaders.deepCopyMap(
                workflowTaskContext,
              ),
            };
      final record = await _upsertAgentTaskRecord(project, goal, enrichedTask);
      final relativePath = ValueReaders.stringValue(record['relative_path']);
      if (relativePath.isNotEmpty) {
        changedPaths.add(relativePath);
      }
      normalizedTasks.add(ValueReaders.mapValue(record['task']));
    }
    return _resultFactory.success(
      '已更新任务清单：${normalizedTasks.length} 项',
      data: <String, Object?>{
        'goal': goal,
        'tasks': normalizedTasks,
        'changed_paths': changedPaths,
      },
    );
  }

  Future<JsonMap> createChapterTask(
    ProjectDescriptor project,
    JsonMap arguments,
  ) async {
    // 中文注释: 章节任务采用独立 JSON 文件承载，方便后续长任务调度继续复用。
    final title = ValueReaders.stringValue(arguments['title'], '未命名任务');
    final taskId = _taskId(title);
    final record = <String, Object?>{
      'id': taskId,
      'title': title,
      'goal': ValueReaders.stringValue(arguments['goal']),
      'task_type': ValueReaders.stringValue(arguments['task_type'], 'chapter'),
      'chapter_index': ValueReaders.intValue(arguments['chapter_index']),
      'notes': ValueReaders.stringValue(arguments['notes']),
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    final relativePath = await _pathPolicy.uniqueRelativePath(
      hostPort: _hostPort,
      rootPath: project.rootPath,
      relativePath: 'tasks/${_pathPolicy.safeFileName(title)}.task.json',
    );
    await _hostPort.writeTextFile(
      project.rootPath,
      relativePath,
      const JsonEncoder.withIndent('  ').convert(record),
    );
    return _resultFactory.success(
      '已创建章节任务：$relativePath',
      data: <String, Object?>{
        'relative_path': relativePath,
        'task': record,
        'changed_paths': <Object?>[relativePath],
      },
    );
  }

  Future<JsonMap> markTaskStatus(
    ProjectDescriptor project,
    JsonMap arguments,
  ) async {
    // 中文注释: 任务状态更新优先按 task_id 定位文件，没有 task_id 时才退回显式路径。
    final explicitPath = _pathPolicy.cleanRelativePath(
      ValueReaders.stringValue(arguments['relative_path']),
    );
    final taskId = ValueReaders.stringValue(arguments['task_id']).trim();
    String relativePath = explicitPath;
    if (relativePath.isEmpty && taskId.isNotEmpty) {
      relativePath = await _taskPathById(project, taskId);
    }
    if (!_pathPolicy.isSafeFilePath(relativePath)) {
      return _resultFactory.error(
        'Task file not found.',
        data: <String, Object?>{
          'task_id': taskId,
          'relative_path': relativePath,
        },
      );
    }
    final content = await _hostPort.readTextFile(
      project.rootPath,
      relativePath,
    );
    if (content == null || content.trim().isEmpty) {
      return _resultFactory.error(
        'Task file not found.',
        data: <String, Object?>{
          'task_id': taskId,
          'relative_path': relativePath,
        },
      );
    }
    JsonMap record;
    try {
      record = ValueReaders.mapValue(jsonDecode(content));
    } catch (_) {
      return _resultFactory.error(
        'Task file is not valid JSON.',
        data: <String, Object?>{'relative_path': relativePath},
      );
    }
    if (ValueReaders.stringValue(arguments['status']).trim().isNotEmpty) {
      record['status'] = ValueReaders.stringValue(arguments['status']);
    }
    if (ValueReaders.stringValue(arguments['note']).trim().isNotEmpty) {
      record['note'] = ValueReaders.stringValue(arguments['note']);
    }
    if (ValueReaders.stringValue(arguments['output_path']).trim().isNotEmpty) {
      record['output_path'] = ValueReaders.stringValue(
        arguments['output_path'],
      );
    }
    record['updated_at'] = DateTime.now().toIso8601String();
    await _hostPort.writeTextFile(
      project.rootPath,
      relativePath,
      const JsonEncoder.withIndent('  ').convert(record),
    );
    return _resultFactory.success(
      '已更新任务状态：$relativePath',
      data: <String, Object?>{
        'relative_path': relativePath,
        'task': record,
        'changed_paths': <Object?>[relativePath],
      },
    );
  }

  Future<String> _taskPathById(ProjectDescriptor project, String taskId) async {
    // 中文注释: 任务 ID 到文件路径的查找统一放在这里，避免调用方自己扫 tasks/ 目录。
    final entries = await _hostPort.listEntries(project.rootPath);
    for (final entry in entries) {
      final path = ValueReaders.stringValue(entry['relative_path']);
      final isDir = ValueReaders.boolValue(entry['is_dir']);
      if (isDir || !path.startsWith('tasks/') || !path.endsWith('.json')) {
        continue;
      }
      final content = await _hostPort.readTextFile(project.rootPath, path);
      if (content == null || content.trim().isEmpty) {
        continue;
      }
      try {
        final record = ValueReaders.mapValue(jsonDecode(content));
        if (ValueReaders.stringValue(record['id']) == taskId) {
          return path;
        }
      } catch (_) {}
    }
    return '';
  }

  Future<JsonMap> _upsertAgentTaskRecord(
    ProjectDescriptor project,
    String goal,
    JsonMap task,
  ) async {
    final providedId = ValueReaders.stringValue(task['id']).trim();
    final title = ValueReaders.stringValue(task['title'], '未命名计划任务');
    final taskId = providedId.isEmpty ? _taskId(title) : providedId;
    final relativePath = await _resolveTaskRecordPath(
      project,
      taskId,
      title,
      task,
    );
    final existingRecord = await _readTaskRecord(project, relativePath);
    final createdAt = ValueReaders.stringValue(
      existingRecord['created_at'],
      DateTime.now().toIso8601String(),
    );
    final seeded = _seedTaskRecord(
      goal: goal,
      taskId: taskId,
      title: title,
      task: task,
      existingRecord: existingRecord,
      createdAt: createdAt,
    );
    final record = _taskDefinitionService.normalizeTask(seeded)
      ..['relative_path'] = relativePath;
    await _hostPort.writeTextFile(
      project.rootPath,
      relativePath,
      const JsonEncoder.withIndent('  ').convert(record),
    );
    return <String, Object?>{'relative_path': relativePath, 'task': record};
  }

  JsonMap _seedTaskRecord({
    required String goal,
    required String taskId,
    required String title,
    required JsonMap task,
    required JsonMap existingRecord,
    required String createdAt,
  }) {
    final mergedMetadata =
        ValueReaders.deepCopyMap(
          ValueReaders.mapValue(existingRecord['metadata']),
        )..addAll(
          ValueReaders.deepCopyMap(ValueReaders.mapValue(task['metadata'])),
        );
    final workflowTaskContext = ValueReaders.mapValue(
      task['_workflow_task_context'],
    );
    final workflowTaskMetadata = ValueReaders.mapValue(
      workflowTaskContext['metadata'],
    );
    final inheritedMetadata = <String, Object?>{
      if (ValueReaders.stringValue(
        workflowTaskMetadata['plan_id'],
      ).trim().isNotEmpty)
        'plan_id': ValueReaders.stringValue(workflowTaskMetadata['plan_id']),
      if (ValueReaders.stringValue(
        workflowTaskMetadata['generated_by'],
      ).trim().isNotEmpty)
        'generated_by': ValueReaders.stringValue(
          workflowTaskMetadata['generated_by'],
        ),
      if (ValueReaders.stringValue(
        workflowTaskMetadata['runtime_baseline_id'],
      ).trim().isNotEmpty)
        'runtime_baseline_id': ValueReaders.stringValue(
          workflowTaskMetadata['runtime_baseline_id'],
        ),
      if (ValueReaders.stringValue(
        workflowTaskMetadata['workflow_mode'],
      ).trim().isNotEmpty)
        'workflow_mode': ValueReaders.stringValue(
          workflowTaskMetadata['workflow_mode'],
        ),
      if (ValueReaders.stringValue(
        workflowTaskMetadata['stage'],
      ).trim().isNotEmpty)
        'stage': ValueReaders.stringValue(workflowTaskMetadata['stage']),
    };
    if (inheritedMetadata.isNotEmpty) {
      inheritedMetadata.addAll(mergedMetadata);
      mergedMetadata
        ..clear()
        ..addAll(inheritedMetadata);
    }
    final rawStatus = ValueReaders.stringValue(
      task['status'],
      ValueReaders.stringValue(existingRecord['status']),
    );
    final history = ValueReaders.objectList(existingRecord['history']);
    if (history.isEmpty) {
      history.add(<String, Object?>{
        'status': rawStatus.trim().isEmpty
            ? TaskRuntimeConstants.statusQueued
            : rawStatus,
        'note': 'created',
        'created_at': createdAt,
      });
    }
    return <String, Object?>{
      'id': taskId,
      'title': title,
      'goal': ValueReaders.stringValue(task['goal'], goal),
      'description': ValueReaders.stringValue(task['description']),
      'brief': ValueReaders.stringValue(
        task['brief'],
        ValueReaders.stringValue(existingRecord['brief']),
      ),
      'task_type': ValueReaders.stringValue(
        task['task_type'],
        ValueReaders.stringValue(existingRecord['task_type'], 'agent_task'),
      ),
      'mode': ValueReaders.stringValue(
        task['mode'],
        ValueReaders.stringValue(
          existingRecord['mode'],
          ValueReaders.stringValue(
            workflowTaskContext['mode'],
            ValueReaders.stringValue(
              workflowTaskMetadata['workflow_mode'],
              ValueReaders.stringValue(workflowTaskContext['workflow_mode']),
            ),
          ),
        ),
      ),
      'status': rawStatus,
      'note': ValueReaders.stringValue(
        task['note'],
        ValueReaders.stringValue(existingRecord['note']),
      ),
      'chapter': ValueReaders.stringValue(
        task['chapter'],
        ValueReaders.stringValue(existingRecord['chapter']),
      ),
      'depends_on': _mergedStringList(
        existingRecord['depends_on'],
        task['depends_on'],
      ),
      'source_paths': _mergedStringList(
        existingRecord['source_paths'],
        task['source_paths'],
      ),
      'output_paths': _mergedStringList(
        existingRecord['output_paths'],
        task['output_paths'],
      ),
      'tool_hint': ValueReaders.stringValue(
        task['tool_hint'],
        ValueReaders.stringValue(existingRecord['tool_hint']),
      ),
      'metadata': mergedMetadata,
      'parent_goal': goal,
      'created_at': createdAt,
      'updated_at': DateTime.now().toIso8601String(),
      'history': history,
    };
  }

  Future<String> _resolveTaskRecordPath(
    ProjectDescriptor project,
    String taskId,
    String title,
    JsonMap task,
  ) async {
    final explicitPath = _pathPolicy.cleanRelativePath(
      ValueReaders.stringValue(task['relative_path']),
    );
    if (_pathPolicy.isSafeFilePath(explicitPath)) {
      return explicitPath;
    }
    final existingPath = await _taskPathById(project, taskId);
    if (existingPath.isNotEmpty) {
      return existingPath;
    }
    return _pathPolicy.uniqueRelativePath(
      hostPort: _hostPort,
      rootPath: project.rootPath,
      relativePath: 'tasks/${_pathPolicy.safeFileName(title)}.task.json',
    );
  }

  Future<JsonMap> _readTaskRecord(
    ProjectDescriptor project,
    String relativePath,
  ) async {
    final content = await _hostPort.readTextFile(
      project.rootPath,
      relativePath,
    );
    if (content == null || content.trim().isEmpty) {
      return const <String, Object?>{};
    }
    try {
      return ValueReaders.mapValue(jsonDecode(content));
    } catch (_) {
      return const <String, Object?>{};
    }
  }

  String _taskId(String title) {
    // 中文注释: 任务 ID 既需要稳定可读，也需要避免文件系统不安全字符。
    return 'task_${_pathPolicy.safeFileName(title)}_${DateTime.now().microsecondsSinceEpoch}';
  }

  List<String> _mergedStringList(Object? left, Object? right) {
    final result = <String>[...ValueReaders.stringList(left)];
    for (final item in ValueReaders.stringList(right)) {
      if (!result.contains(item)) {
        result.add(item);
      }
    }
    return result;
  }
}
