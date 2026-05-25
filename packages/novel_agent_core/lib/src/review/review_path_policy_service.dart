import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../project/project_workspace_catalog.dart';

class ReviewPathPolicyService {
  String reviewJsonPath(String markdownOrJsonPath) {
    // 中文注释: 这里限制 reports 路径只能落在 reviews/ 下，避免上层误把任意路径塞进修复流程。
    var path = markdownOrJsonPath.trim().replaceAll('\\', '/');
    while (path.startsWith('/')) {
      path = path.substring(1);
    }
    if (path.isEmpty || path.contains('..') || !path.startsWith('reviews/')) {
      return '';
    }
    if (path.endsWith('.md')) {
      return '${path.substring(0, path.length - 3)}.json';
    }
    if (!path.endsWith('.json')) {
      return '';
    }
    return path;
  }

  String reviewMarkdownPath(String markdownOrJsonPath) {
    // 中文注释: 兄弟 Markdown 路径转换集中在这里，避免各宿主重复写 .json/.md 规则再踩错。
    var path = markdownOrJsonPath.trim().replaceAll('\\', '/');
    while (path.startsWith('/')) {
      path = path.substring(1);
    }
    if (path.isEmpty || path.contains('..') || !path.startsWith('reviews/')) {
      return '';
    }
    if (path.endsWith('.json')) {
      return '${path.substring(0, path.length - 5)}.md';
    }
    if (!path.endsWith('.md')) {
      return '';
    }
    return path;
  }

  bool isEditableProjectPath(String path) {
    // 中文注释: 修订默认只允许指向真正的项目正文/资料路径，不把运行记录和备份当写回目标。
    final clean = path.trim().replaceAll('\\', '/');
    if (clean.isEmpty || clean.contains('..') || !clean.contains('/')) {
      return false;
    }
    final root = clean.split('/').first;
    if (const <String>{
      'reviews',
      'tracking',
      'runs',
      'tasks',
      'backups',
      'exports',
      'sessions',
    }.contains(root)) {
      return false;
    }
    final allowedRoots = ProjectWorkspaceCatalog.userWorkspaceDirs
        .map((item) => item.path.replaceAll('/', ''))
        .toSet();
    return allowedRoots.contains(root);
  }

  List<String> editableSourcePaths(JsonMap report) {
    // 中文注释: 修订候选路径从 source_paths、scope 和 issue.source_path 中合并并过滤。
    final candidates = <String>[
      ...ValueReaders.stringList(report['source_paths']),
    ];
    final scope = ValueReaders.stringValue(report['scope']).trim();
    if (scope.isNotEmpty && !candidates.contains(scope)) {
      candidates.add(scope);
    }
    for (final issue in ValueReaders.mapList(report['issues'])) {
      final issuePath = ValueReaders.stringValue(issue['source_path']).trim();
      if (issuePath.isNotEmpty && !candidates.contains(issuePath)) {
        candidates.add(issuePath);
      }
    }
    final result = <String>[];
    for (final candidate in candidates) {
      final clean = candidate.trim().replaceAll('\\', '/');
      if (isEditableProjectPath(clean) && !result.contains(clean)) {
        result.add(clean);
      }
    }
    return result;
  }

  List<String> reviewReferencePaths(JsonMap report, String reportPath) {
    // 中文注释: 报告自身路径只作为上下文来源，不进入默认写回目标。
    final result = <String>[];
    for (final rawPath in <Object?>[
      reportPath,
      report['markdown_path'],
      report['json_path'],
    ]) {
      final clean = ValueReaders.stringValue(
        rawPath,
      ).trim().replaceAll('\\', '/');
      if (clean.startsWith('reviews/') &&
          !clean.contains('..') &&
          !result.contains(clean)) {
        result.add(clean);
      }
    }
    return result;
  }

  List<String> mergeStringArrays(List<Object?> left, List<Object?> right) {
    // 中文注释: 合并路径时保持左侧优先顺序，方便上层把“真正要修的文件”放在更前面。
    final result = <String>[];
    for (final values in <List<Object?>>[left, right]) {
      for (final rawValue in values) {
        final text = ValueReaders.stringValue(rawValue).trim();
        if (text.isNotEmpty && !result.contains(text)) {
          result.add(text);
        }
      }
    }
    return result;
  }
}
