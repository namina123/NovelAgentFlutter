import 'dart:convert';

import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_tool_path_policy.dart';
import 'project_tool_result_factory.dart';

class ProjectTaskToolExecutor {
  ProjectTaskToolExecutor({
    required ProjectToolHostPort hostPort,
    ProjectToolPathPolicy? pathPolicy,
    ProjectToolResultFactory? resultFactory,
  }) : _hostPort = hostPort,
       _pathPolicy = pathPolicy ?? ProjectToolPathPolicy(),
       _resultFactory = resultFactory ?? ProjectToolResultFactory();

  final ProjectToolHostPort _hostPort;
  final ProjectToolPathPolicy _pathPolicy;
  final ProjectToolResultFactory _resultFactory;

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

  String _taskId(String title) {
    // 中文注释: 任务 ID 既需要稳定可读，也需要避免文件系统不安全字符。
    return 'task_${_pathPolicy.safeFileName(title)}_${DateTime.now().microsecondsSinceEpoch}';
  }
}
