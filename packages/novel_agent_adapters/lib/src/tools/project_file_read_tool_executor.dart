import 'dart:convert';

import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_tool_path_policy.dart';
import 'project_tool_result_factory.dart';

class ProjectFileReadToolExecutor {
  ProjectFileReadToolExecutor({
    required ProjectToolHostPort hostPort,
    ProjectToolPathPolicy? pathPolicy,
    ProjectToolResultFactory? resultFactory,
  }) : _hostPort = hostPort,
       _pathPolicy = pathPolicy ?? ProjectToolPathPolicy(),
       _resultFactory = resultFactory ?? ProjectToolResultFactory();

  final ProjectToolHostPort _hostPort;
  final ProjectToolPathPolicy _pathPolicy;
  final ProjectToolResultFactory _resultFactory;

  Future<JsonMap> listProjectFiles(
    ProjectDescriptor project,
    JsonMap arguments,
  ) async {
    // 中文注释: 列目录工具只返回安全可见的项目树，避免内部索引和会话记录直接暴露给模型。
    final scope = _pathPolicy.cleanRelativePath(
      ValueReaders.stringValue(arguments['relative_path']),
    );
    if (!_pathPolicy.isSafeScopePath(scope) &&
        ValueReaders.stringValue(
          arguments['relative_path'],
        ).trim().isNotEmpty) {
      return _resultFactory.error(
        'Unsafe relative_path scope.',
        data: <String, Object?>{
          'relative_path': scope,
          'entries': const <Object?>[],
        },
      );
    }
    final entries = await _hostPort.listEntries(project.rootPath);
    final visible = entries
        .where((entry) {
          final path = ValueReaders.stringValue(entry['relative_path']).trim();
          final isDir = ValueReaders.boolValue(entry['is_dir']);
          if (path.isEmpty ||
              _pathPolicy.isHiddenProjectTreeEntry(path, isDir)) {
            return false;
          }
          if (scope.isEmpty) {
            return true;
          }
          return path == scope || path.startsWith('$scope/');
        })
        .toList(growable: false);
    return _resultFactory.success(
      '已读取项目目录：${visible.length} 项',
      data: <String, Object?>{
        'entries': visible,
        'entry_count': visible.length,
        'entries_preview': _entriesPreview(visible),
      },
    );
  }

  Future<JsonMap> readProjectFile(
    ProjectDescriptor project,
    JsonMap arguments,
  ) async {
    // 中文注释: 读取文件默认返回正文和基础信息，超长文件会截断避免工具结果过重。
    final relativePath = _pathPolicy.cleanRelativePath(
      ValueReaders.stringValue(arguments['relative_path']),
    );
    if (relativePath.isEmpty) {
      return _recoverablePathIssue(
        project,
        message:
            'read_project_file 缺少 relative_path。请先调用 list_project_files，并从返回结果里复制英文 relative_path。',
      );
    }
    if (!_pathPolicy.isSafeFilePath(relativePath)) {
      return _recoverablePathIssue(
        project,
        relativePath: relativePath,
        message:
            'read_project_file 的 relative_path 无效。请使用 list_project_files 返回的英文 relative_path。',
      );
    }
    final content = await _hostPort.readTextFile(
      project.rootPath,
      relativePath,
    );
    if (content == null) {
      return _recoverablePathIssue(
        project,
        relativePath: relativePath,
        message:
            'read_project_file 未找到目标文件。请先调用 list_project_files，再直接复制返回的英文 relative_path。',
      );
    }
    const maxChars = 16000;
    final truncated = content.length > maxChars;
    final safeContent = truncated ? content.substring(0, maxChars) : content;
    return _resultFactory.success(
      '已读取项目文件：$relativePath',
      data: <String, Object?>{
        'relative_path': relativePath,
        'content': safeContent,
        'content_chars': content.length,
        'truncated': truncated,
        'changed_paths': const <Object?>[],
      },
    );
  }

  Future<JsonMap> getProjectFileInfo(
    ProjectDescriptor project,
    JsonMap arguments,
  ) async {
    // 中文注释: 文件信息工具用于小范围定位行号，减少模型为了改一段话整篇回读。
    final relativePath = _pathPolicy.cleanRelativePath(
      ValueReaders.stringValue(arguments['relative_path']),
    );
    if (relativePath.isEmpty) {
      return _recoverablePathIssue(
        project,
        message:
            'get_project_file_info 缺少 relative_path。请先调用 list_project_files，并从返回结果里复制英文 relative_path。',
      );
    }
    if (!_pathPolicy.isSafeFilePath(relativePath)) {
      return _recoverablePathIssue(
        project,
        relativePath: relativePath,
        message:
            'get_project_file_info 的 relative_path 无效。请使用 list_project_files 返回的英文 relative_path。',
      );
    }
    final content = await _hostPort.readTextFile(
      project.rootPath,
      relativePath,
    );
    if (content == null) {
      return _recoverablePathIssue(
        project,
        relativePath: relativePath,
        message:
            'get_project_file_info 未找到目标文件。请先调用 list_project_files，再直接复制返回的英文 relative_path。',
      );
    }
    final lines = content
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n');
    final startLine = _clamp(
      ValueReaders.intValue(
        arguments['start_line'] ?? arguments['startLine'],
        1,
      ),
      1,
      lines.length,
    );
    final endLine = _clamp(
      ValueReaders.intValue(
        arguments['end_line'] ?? arguments['endLine'],
        startLine + 39,
      ),
      startLine,
      lines.length,
    );
    final selected = <Object?>[];
    for (var index = startLine - 1; index < endLine; index++) {
      selected.add(<String, Object?>{'line': index + 1, 'text': lines[index]});
    }
    return _resultFactory.success(
      '已读取文件信息：$relativePath',
      data: <String, Object?>{
        'relative_path': relativePath,
        'line_count': lines.length,
        'content_chars': content.length,
        'selected_start_line': startLine,
        'selected_end_line': endLine,
        'selected_lines': selected,
      },
    );
  }

  Future<JsonMap> searchProjectFiles(
    ProjectDescriptor project,
    JsonMap arguments,
  ) async {
    // 中文注释: 搜索只返回命中行摘要，不把整篇文件重新塞回模型上下文。
    final pattern = ValueReaders.stringValue(arguments['pattern']).trim();
    if (pattern.isEmpty) {
      return _resultFactory.error(
        'pattern is required.',
        data: const <String, Object?>{'matches': <Object?>[]},
      );
    }
    final scope = _pathPolicy.cleanRelativePath(
      ValueReaders.stringValue(arguments['relative_path']),
    );
    if (!_pathPolicy.isSafeScopePath(scope) &&
        ValueReaders.stringValue(
          arguments['relative_path'],
        ).trim().isNotEmpty) {
      return _resultFactory.error(
        'Unsafe relative_path scope.',
        data: const <String, Object?>{'matches': <Object?>[]},
      );
    }
    final limit = _clamp(ValueReaders.intValue(arguments['limit'], 50), 1, 200);
    final caseSensitive = ValueReaders.boolValue(arguments['case_sensitive']);
    final includeJson = ValueReaders.boolValue(arguments['include_json']);
    final needle = caseSensitive ? pattern : pattern.toLowerCase();
    final entries = await _hostPort.listEntries(project.rootPath);
    final matches = <Object?>[];
    for (final entry in entries) {
      final path = ValueReaders.stringValue(entry['relative_path']);
      final isDir = ValueReaders.boolValue(entry['is_dir']);
      if (isDir ||
          path.isEmpty ||
          _pathPolicy.isHiddenProjectTreeEntry(path, false) ||
          !_pathPolicy.shouldSearchFile(path, includeJson: includeJson)) {
        continue;
      }
      if (scope.isNotEmpty && !(path == scope || path.startsWith('$scope/'))) {
        continue;
      }
      final content = await _hostPort.readTextFile(project.rootPath, path);
      if (content == null || content.isEmpty) {
        continue;
      }
      final lines = content
          .replaceAll('\r\n', '\n')
          .replaceAll('\r', '\n')
          .split('\n');
      for (var index = 0; index < lines.length; index++) {
        final line = lines[index];
        final haystack = caseSensitive ? line : line.toLowerCase();
        if (!haystack.contains(needle)) {
          continue;
        }
        matches.add(<String, Object?>{
          'relative_path': path,
          'line': index + 1,
          'text': _excerpt(line, 180),
        });
        if (matches.length >= limit) {
          return _resultFactory.success(
            '已搜索项目文件：${matches.length} 条匹配',
            data: <String, Object?>{
              'pattern': pattern,
              'matches': matches,
              'truncated': true,
            },
          );
        }
      }
    }
    return _resultFactory.success(
      '已搜索项目文件：${matches.length} 条匹配',
      data: <String, Object?>{
        'pattern': pattern,
        'matches': matches,
        'truncated': false,
      },
    );
  }

  Future<JsonMap> listHistorySessions(
    ProjectDescriptor project,
    JsonMap arguments,
  ) async {
    // 中文注释: 历史会话读取优先走 session_index.json，没有索引时再回退扫描 sessions/。
    final start = ValueReaders.intValue(arguments['start'], 0);
    final length = _clamp(
      ValueReaders.intValue(arguments['length'], 12),
      1,
      50,
    );
    final summaries = await _sessionSummaries(project);
    final clampedStart = start < 0 ? 0 : start;
    final sliced = summaries
        .skip(clampedStart)
        .take(length)
        .toList(growable: false);
    return _resultFactory.success(
      '已读取历史会话：${sliced.length} 条',
      data: <String, Object?>{
        'sessions': sliced,
        'total': summaries.length,
        'current_session_id': await _currentSessionId(project),
      },
    );
  }

  Future<List<JsonMap>> _sessionSummaries(ProjectDescriptor project) async {
    // 中文注释: 会话索引优先返回轻量摘要，不把完整消息记录都读进来。
    final indexText = await _hostPort.readTextFile(
      project.rootPath,
      'sessions/session_index.json',
    );
    if (indexText != null && indexText.trim().isNotEmpty) {
      try {
        final decoded = ValueReaders.mapValue(jsonDecode(indexText));
        return ValueReaders.mapList(decoded['sessions']);
      } catch (_) {}
    }
    final entries = await _hostPort.listEntries(project.rootPath);
    final result = <JsonMap>[];
    for (final entry in entries) {
      final path = ValueReaders.stringValue(entry['relative_path']);
      final isDir = ValueReaders.boolValue(entry['is_dir']);
      if (isDir || !path.startsWith('sessions/')) {
        continue;
      }
      if (path.endsWith('.json')) {
        final content = await _hostPort.readTextFile(project.rootPath, path);
        if (content == null || content.trim().isEmpty) {
          continue;
        }
        try {
          final session = ValueReaders.mapValue(jsonDecode(content));
          if (ValueReaders.stringValue(session['id']).trim().isEmpty) {
            continue;
          }
          result.add(_sessionSummary(session));
        } catch (_) {}
      }
      if (path.endsWith('.jsonl')) {
        final content = await _hostPort.readTextFile(project.rootPath, path);
        if (content == null || content.trim().isEmpty) {
          continue;
        }
        final summary = _sessionSummaryFromJsonl(content);
        if (summary.isNotEmpty) {
          result.add(summary);
        }
      }
    }
    result.sort((left, right) {
      final leftTime = ValueReaders.stringValue(left['updated_at']);
      final rightTime = ValueReaders.stringValue(right['updated_at']);
      return rightTime.compareTo(leftTime);
    });
    return result;
  }

  Future<String> _currentSessionId(ProjectDescriptor project) async {
    // 中文注释: 当前会话 ID 只在会话列表工具里暴露，避免外层到处解析索引文件。
    final indexText = await _hostPort.readTextFile(
      project.rootPath,
      'sessions/session_index.json',
    );
    if (indexText == null || indexText.trim().isEmpty) {
      return '';
    }
    try {
      final decoded = ValueReaders.mapValue(jsonDecode(indexText));
      return ValueReaders.stringValue(decoded['current_session_id']);
    } catch (_) {
      return '';
    }
  }

  JsonMap _sessionSummaryFromJsonl(String content) {
    // 中文注释: JSONL 会话读取只提取 meta 与消息计数，不重建完整会话对象。
    JsonMap session = <String, Object?>{};
    var messageCount = 0;
    for (final line in content.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      try {
        final decoded = ValueReaders.mapValue(jsonDecode(trimmed));
        final type = ValueReaders.stringValue(decoded['type']);
        if (type == 'meta') {
          session = ValueReaders.mapValue(decoded['session']);
        }
        if (type == 'message') {
          messageCount += 1;
        }
      } catch (_) {}
    }
    if (session.isEmpty) {
      return <String, Object?>{};
    }
    final summary = _sessionSummary(session);
    summary['message_count'] = messageCount;
    return summary;
  }

  JsonMap _sessionSummary(JsonMap session) {
    // 中文注释: 会话摘要结构与旧项目兼容，方便后续 GUI 历史列表直接复用。
    return <String, Object?>{
      'id': ValueReaders.stringValue(session['id']),
      'title': ValueReaders.stringValue(session['title'], '新会话'),
      'mode': ValueReaders.stringValue(session['mode']),
      'workflow_stage': ValueReaders.stringValue(session['workflow_stage']),
      'public_status': ValueReaders.stringValue(session['public_status']),
      'updated_at': ValueReaders.stringValue(session['updated_at']),
      'message_count': ValueReaders.objectList(
        session['context_messages'],
      ).length,
    };
  }

  int _clamp(int value, int minValue, int maxValue) {
    if (value < minValue) {
      return minValue;
    }
    if (value > maxValue) {
      return maxValue;
    }
    return value;
  }

  String _excerpt(String value, int maxChars) {
    // 中文注释: 搜索结果摘要只保留短片段，避免一次返回大段正文。
    final text = value.trim();
    if (text.length <= maxChars) {
      return text;
    }
    return '${text.substring(0, maxChars - 1)}…';
  }

  Future<List<JsonMap>> _visibleEntries(ProjectDescriptor project) async {
    // 中文注释: 失败回退时也只暴露安全可见的资源树条目，避免内部记录混进模型纠错提示。
    final entries = await _hostPort.listEntries(project.rootPath);
    return entries
        .where((entry) {
          final path = ValueReaders.stringValue(entry['relative_path']).trim();
          final isDir = ValueReaders.boolValue(entry['is_dir']);
          return path.isNotEmpty &&
              !_pathPolicy.isHiddenProjectTreeEntry(path, isDir);
        })
        .map(ValueReaders.deepCopyMap)
        .toList(growable: false);
  }

  Future<JsonMap> _recoverablePathIssue(
    ProjectDescriptor project, {
    required String message,
    String relativePath = '',
  }) async {
    // 中文注释: 路径缺失或匹配失败属于可自纠正问题，不应把整轮工具链硬性打断。
    final visibleEntries = await _visibleEntries(project);
    return _resultFactory.notExecuted(
      message,
      data: <String, Object?>{
        'relative_path': relativePath,
        'entries_preview': _entriesPreview(visibleEntries),
        'suggested_tool': 'list_project_files',
      },
    );
  }

  String _entriesPreview(List<JsonMap> entries, {int maxLines = 80}) {
    // 中文注释: 目录预览转成轻量纯文本，方便模型在失败后直接复制真实英文路径。
    if (entries.isEmpty) {
      return '项目目录为空。';
    }
    final lines = <String>[];
    for (final entry in entries) {
      final path = ValueReaders.stringValue(entry['relative_path']).trim();
      if (path.isEmpty) {
        continue;
      }
      final prefix = ValueReaders.boolValue(entry['is_dir']) ? '[DIR]' : '[FILE]';
      lines.add('$prefix $path');
      if (lines.length >= maxLines) {
        lines.add('... (truncated)');
        break;
      }
    }
    return lines.join('\n');
  }
}
