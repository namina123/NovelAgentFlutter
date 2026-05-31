import 'package:novel_agent_core/novel_agent_core.dart';

class ProjectToolPathPolicy {
  ProjectToolPathPolicy({
    ProjectContentPathPolicyService? contentPathPolicyService,
  }) : _contentPathPolicyService =
           contentPathPolicyService ?? const ProjectContentPathPolicyService();

  final ProjectContentPathPolicyService _contentPathPolicyService;

  List<String> allowedRoots() {
    // 中文注释: 可访问根目录统一来自核心工作空间目录约定，避免宿主自己发明另一套规则。
    return <String>[
      ...ProjectWorkspaceCatalog.userWorkspaceDirs.map(
        (item) => item.path.replaceAll(RegExp(r'/$'), ''),
      ),
      ...ProjectWorkspaceCatalog.advancedWorkspaceDirs.map(
        (item) => item.path.replaceAll(RegExp(r'/$'), ''),
      ),
      ..._compatibilityRoots,
      'sessions',
      'backups',
    ].toSet().toList(growable: false);
  }

  String cleanRelativePath(String value) {
    // 中文注释: 所有项目工具路径先在这里清洗，统一拦截绝对路径、盘符和父级跳转。
    var result = value.trim().replaceAll('\\', '/');
    while (result.startsWith('/')) {
      result = result.substring(1);
    }
    if (result.contains('..') || result.contains(':')) {
      return '';
    }
    return result;
  }

  bool isSafeFilePath(String relativePath, {bool allowSessions = false}) {
    // 中文注释: 文件路径必须落在允许根目录内，并且需要明确文件名。
    final clean = cleanRelativePath(relativePath);
    if (clean.isEmpty || clean.split('/').last.trim().isEmpty) {
      return false;
    }
    final root = clean.split('/').first;
    if (!allowedRoots().contains(root)) {
      return false;
    }
    if (!allowSessions && root == 'sessions') {
      return false;
    }
    return true;
  }

  bool isSafeScopePath(String relativePath, {bool allowSessions = false}) {
    // 中文注释: 搜索范围既可以是目录也可以是空路径，因此只校验根目录边界。
    final clean = cleanRelativePath(relativePath);
    if (clean.isEmpty) {
      return true;
    }
    final root = clean.split('/').first;
    if (!allowedRoots().contains(root)) {
      return false;
    }
    if (!allowSessions && root == 'sessions') {
      return false;
    }
    return true;
  }

  bool isHiddenProjectTreeEntry(String relativePath, bool isDir) {
    // 中文注释: 资源树默认隐藏内部会话与索引 JSON，工具读取时可按需放开。
    final clean = cleanRelativePath(relativePath);
    if (clean.isEmpty) {
      return false;
    }
    final name = clean.split('/').last;
    final root = clean.split('/').first;
    if (name.startsWith('.')) {
      return true;
    }
    if (isDir) {
      return root == 'sessions';
    }
    final lowerName = name.toLowerCase();
    return lowerName.endsWith('.meta.json') ||
        root == 'sessions' ||
        lowerName.endsWith('.jsonl');
  }

  bool shouldSearchFile(String relativePath, {required bool includeJson}) {
    // 中文注释: 搜索默认只扫文本类文件，避免无意义地把内部 JSON 记录塞回模型上下文。
    final lower = relativePath.toLowerCase();
    return lower.endsWith('.md') ||
        lower.endsWith('.markdown') ||
        lower.endsWith('.txt') ||
        (includeJson && (lower.endsWith('.json') || lower.endsWith('.jsonl')));
  }

  String normalizeContentType(String value) {
    // 中文注释: 内容类型正式归一化委托给 core，避免适配器层长期维护一份几乎重复的映射表。
    return _contentPathPolicyService.normalizeContentType(value);
  }

  String contentTypeDir(String contentType) {
    // 中文注释: 正式目录映射以 core 为唯一事实源，适配器这里只做工具层转发。
    return _contentPathPolicyService.directoryForContentType(contentType);
  }

  String inferContentTypeFromPath(String relativePath) {
    // 中文注释: 路径反推内容类型也统一复用 core，保持工具展示与宿主默认目录语义一致。
    return _contentPathPolicyService.inferContentTypeFromPath(
      cleanRelativePath(relativePath),
    );
  }

  String safeFileName(
    String value, {
    String fallback = 'untitled',
    int maxLength = 64,
  }) {
    // 中文注释: 统一文件名清洗规则后，结构化记忆、备份和任务文件才能稳定复用。
    var result = value.trim();
    for (final token in const <String>[
      '\\',
      '/',
      ':',
      '*',
      '?',
      '"',
      '<',
      '>',
      '|',
    ]) {
      result = result.replaceAll(token, '_');
    }
    result = result.replaceAll(RegExp(r'\s+'), '_');
    result = result.replaceAll(RegExp(r'_+'), '_');
    result = result.replaceAll(RegExp(r'^_+|_+$'), '');
    if (result.isEmpty) {
      result = fallback;
    }
    return result.length > maxLength ? result.substring(0, maxLength) : result;
  }

  Future<String> uniqueRelativePath({
    required ProjectToolHostPort hostPort,
    required String rootPath,
    required String relativePath,
  }) async {
    // 中文注释: 自动生成唯一文件名的逻辑集中在这里，避免多个写入工具各自实现后细节不一致。
    final cleanPath = cleanRelativePath(relativePath);
    if (cleanPath.isEmpty) {
      return cleanPath;
    }
    final slashIndex = cleanPath.lastIndexOf('/');
    final baseDir = slashIndex >= 0 ? cleanPath.substring(0, slashIndex) : '';
    final fileName = slashIndex >= 0
        ? cleanPath.substring(slashIndex + 1)
        : cleanPath;
    final dotIndex = fileName.lastIndexOf('.');
    final baseName = dotIndex > 0 ? fileName.substring(0, dotIndex) : fileName;
    final extension = dotIndex > 0 ? fileName.substring(dotIndex) : '';
    var candidate = cleanPath;
    var index = 2;
    while (await hostPort.entryExists(rootPath, candidate)) {
      final nextName = '${baseName}_$index$extension';
      candidate = baseDir.isEmpty ? nextName : '$baseDir/$nextName';
      index += 1;
    }
    return candidate;
  }

  String backupTargetFromPath(String backupPath) {
    // 中文注释: 恢复备份时优先从备份路径推断原始目标，作为缺省恢复位置。
    final clean = cleanRelativePath(backupPath);
    if (!clean.startsWith('backups/')) {
      return '';
    }
    final withoutRoot = clean.substring('backups/'.length);
    final slashIndex = withoutRoot.lastIndexOf('/');
    final directory = slashIndex >= 0
        ? withoutRoot.substring(0, slashIndex)
        : '';
    var fileName = slashIndex >= 0
        ? withoutRoot.substring(slashIndex + 1)
        : withoutRoot;
    final marker = fileName.lastIndexOf('.20');
    if (marker > 0) {
      fileName = fileName.substring(0, marker);
    }
    if (fileName.endsWith('.bak')) {
      fileName = fileName.substring(0, fileName.length - 4);
    }
    return directory.isEmpty ? fileName : '$directory/$fileName';
  }

  static const List<String> _compatibilityRoots = <String>[
    'specs',
    'outline',
    'volume_outlines',
    'chapter_outlines',
    'world',
    'characters',
    'styles',
    'summaries',
    'knowledge',
    'inspiration',
    'reviews',
    'tracking',
    'runs',
  ];
}
