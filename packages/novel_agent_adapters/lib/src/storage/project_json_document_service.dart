import 'dart:convert';

import 'package:novel_agent_core/novel_agent_core.dart';

class ProjectJsonDocumentService {
  const ProjectJsonDocumentService({
    required ProjectWorkspacePort workspacePort,
  }) : _workspacePort = workspacePort;

  final ProjectWorkspacePort _workspacePort;

  Future<List<String>> listPaths(
    String rootPath, {
    required String prefix,
    String suffix = '.json',
  }) async {
    // 中文注释: JSON 文档扫描统一收口，避免 tasks/reviews/prompts 各自重复遍历项目文件树。
    final entries = await _workspacePort.listEntries(rootPath);
    final result = <String>[];
    for (final entry in entries) {
      final relativePath = ValueReaders.stringValue(entry['relative_path']);
      final isDir = ValueReaders.boolValue(entry['is_dir']);
      if (isDir || !relativePath.startsWith(prefix)) {
        continue;
      }
      if (suffix.isNotEmpty &&
          !relativePath.toLowerCase().endsWith(suffix.toLowerCase())) {
        continue;
      }
      result.add(relativePath);
    }
    result.sort();
    return result;
  }

  Future<JsonMap> readJsonMap(String rootPath, String relativePath) async {
    // 中文注释: JSON 读取失败时回空字典，让上层自行决定是否跳过损坏文档。
    final content = await _workspacePort.readTextFile(rootPath, relativePath);
    if (content == null || content.trim().isEmpty) {
      return <String, Object?>{};
    }
    try {
      return ValueReaders.mapValue(jsonDecode(content));
    } catch (_) {
      return <String, Object?>{};
    }
  }

  Future<void> writeJsonMap(
    String rootPath,
    String relativePath,
    JsonMap document,
  ) {
    // 中文注释: JSON 写回统一使用缩进格式，方便人工排查运行记录和任务文件。
    return _workspacePort.writeTextFile(
      rootPath,
      relativePath,
      const JsonEncoder.withIndent('  ').convert(document),
    );
  }
}
