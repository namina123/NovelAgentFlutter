import 'package:novel_agent_core/novel_agent_core.dart';

class WorkspaceInformationScanResult {
  const WorkspaceInformationScanResult({
    required this.projectRootPath,
    required this.workspaceEntries,
    required this.fileContents,
    required this.sourcePaths,
  });

  final String projectRootPath;
  final List<JsonMap> workspaceEntries;
  final Map<String, String> fileContents;
  final List<String> sourcePaths;

  bool get hasSourceFiles => sourcePaths.isNotEmpty;

  factory WorkspaceInformationScanResult.empty(String projectRootPath) {
    // 中文注释: 空结果用于项目缺失或扫描失败时的安全回退，不让控制器继续依赖过期缓存。
    return WorkspaceInformationScanResult(
      projectRootPath: projectRootPath.trim(),
      workspaceEntries: const <JsonMap>[],
      fileContents: const <String, String>{},
      sourcePaths: const <String>[],
    );
  }

  factory WorkspaceInformationScanResult.fromJson(JsonMap payload) {
    // 中文注释: isolate 侧只回传基础类型，这里负责把扫描快照还原成可消费的领域模型。
    return WorkspaceInformationScanResult(
      projectRootPath: ValueReaders.stringValue(payload['project_root_path']),
      workspaceEntries: ValueReaders.mapList(payload['workspace_entries'])
          .map(ValueReaders.deepCopyMap)
          .toList(growable: false),
      fileContents: _stringMap(payload['file_contents']),
      sourcePaths: ValueReaders.stringList(payload['source_paths']),
    );
  }
}

Map<String, String> _stringMap(Object? value) {
  // 中文注释: 文件内容只接受字符串映射，避免 isolate payload 带进来其他非文本类型。
  final result = <String, String>{};
  if (value is Map) {
    value.forEach((key, entry) {
      final text = entry?.toString() ?? '';
      result[key.toString()] = text;
    });
  }
  return result;
}
