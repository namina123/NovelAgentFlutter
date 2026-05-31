import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_tool_path_policy.dart';

class ProjectToolRelativePathResolver {
  ProjectToolRelativePathResolver({
    required ProjectToolHostPort hostPort,
    ProjectToolPathPolicy? pathPolicy,
  }) : _hostPort = hostPort,
       _pathPolicy = pathPolicy ?? ProjectToolPathPolicy();

  final ProjectToolHostPort _hostPort;
  final ProjectToolPathPolicy _pathPolicy;

  Future<String> resolveFilePath(
    ProjectDescriptor project,
    JsonMap arguments, {
    bool allowSessions = false,
  }) async {
    // 中文注释: 文件路径兼容只保留在适配器入口层，统一兼容英文相对路径、中文目录标签和展示名。
    final candidates = _argumentCandidates(arguments);
    for (final candidate in candidates) {
      final normalized = _normalizedCandidate(candidate);
      if (_pathPolicy.isSafeFilePath(
        normalized,
        allowSessions: allowSessions,
      )) {
        return normalized;
      }
    }
    final entries = await _hostPort.listEntries(project.rootPath);
    for (final candidate in candidates) {
      final matched = _matchEntryPath(entries, candidate, fileOnly: true);
      if (_pathPolicy.isSafeFilePath(matched, allowSessions: allowSessions)) {
        return matched;
      }
    }
    return '';
  }

  Future<String> resolveScopePath(
    ProjectDescriptor project,
    JsonMap arguments, {
    bool allowSessions = false,
  }) async {
    // 中文注释: 目录范围解析与文件解析共用一套候选来源，但允许返回目录本身。
    final candidates = _argumentCandidates(arguments);
    for (final candidate in candidates) {
      final normalized = _normalizedCandidate(candidate);
      if (_pathPolicy.isSafeScopePath(
        normalized,
        allowSessions: allowSessions,
      )) {
        return normalized;
      }
    }
    final entries = await _hostPort.listEntries(project.rootPath);
    for (final candidate in candidates) {
      final matched = _matchEntryPath(entries, candidate, fileOnly: false);
      if (_pathPolicy.isSafeScopePath(matched, allowSessions: allowSessions)) {
        return matched;
      }
    }
    return '';
  }

  String normalizeProjectPath(String value) {
    // 中文注释: 新建/写入目标路径可能还不存在，这里只在入口边界做显示名映射和安全清洗。
    return _normalizedCandidate(value);
  }

  List<String> _argumentCandidates(JsonMap arguments) {
    final values = <String>[
      ValueReaders.stringValue(arguments['relative_path']),
      ValueReaders.stringValue(arguments['path']),
      ValueReaders.stringValue(arguments['file_path']),
      ValueReaders.stringValue(arguments['filePath']),
      ValueReaders.stringValue(arguments['title']),
      ValueReaders.stringValue(arguments['name']),
      ValueReaders.stringValue(arguments['target_relative_path']),
    ];
    return values
        .where((item) => item.trim().isNotEmpty)
        .toList(growable: false);
  }

  String _normalizedCandidate(String value) {
    var candidate = value.trim().replaceAll('\\', '/');
    candidate = candidate.replaceAll(RegExp(r'\(\d+\)$'), '');
    candidate = candidate.replaceAll(RegExp(r'（\d+）$'), '');
    for (final entry in _directoryLabelMap.entries) {
      final label = entry.key;
      final root = entry.value;
      if (candidate == label) {
        candidate = root;
        break;
      }
      if (candidate.startsWith('$label/')) {
        candidate = '$root/${candidate.substring(label.length + 1)}';
        break;
      }
    }
    return _pathPolicy.cleanRelativePath(candidate);
  }

  String _matchEntryPath(
    List<JsonMap> entries,
    String candidate, {
    required bool fileOnly,
  }) {
    final normalized = _normalizedCandidate(candidate);
    final lowerNormalized = normalized.toLowerCase();
    final matches = <String>[];
    for (final entry in entries) {
      final relativePath = ValueReaders.stringValue(entry['relative_path']);
      final displayName = ValueReaders.stringValue(entry['display_name']);
      final isDir = ValueReaders.boolValue(entry['is_dir']);
      if (fileOnly && isDir) {
        continue;
      }
      final lowerRelativePath = relativePath.toLowerCase();
      final lowerDisplayName = displayName.toLowerCase();
      if (lowerNormalized.isNotEmpty &&
          (lowerRelativePath == lowerNormalized ||
              lowerRelativePath.endsWith('/$lowerNormalized') ||
              lowerDisplayName == lowerNormalized)) {
        matches.add(relativePath);
      }
    }
    if (matches.length == 1) {
      return matches.first;
    }
    return normalized;
  }

  static final Map<String, String> _directoryLabelMap = <String, String>{
    for (final descriptor in ProjectWorkspaceCatalog.userWorkspaceDirs)
      descriptor.name: descriptor.path.replaceAll(RegExp(r'/$'), ''),
    for (final descriptor in ProjectWorkspaceCatalog.advancedWorkspaceDirs)
      descriptor.name: descriptor.path.replaceAll(RegExp(r'/$'), ''),
    '项目规格': 'specs',
    '设定': 'world',
    '总纲': 'outline',
    '卷纲': 'volume_outlines',
    '章纲': 'chapter_outlines',
    '正文': 'chapters',
    '场景': 'scenes',
    '角色': 'assets/characters',
    '风格': 'styles',
    '摘要': 'summaries',
    '知识库': 'knowledge',
    '灵感': 'inspiration',
    '素材': 'assets',
    '任务': 'tasks',
    '审稿': 'reviews',
  };
}
