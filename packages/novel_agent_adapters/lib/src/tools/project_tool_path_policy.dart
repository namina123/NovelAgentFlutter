import 'package:novel_agent_core/novel_agent_core.dart';

class ProjectToolPathPolicy {
  List<String> allowedRoots() {
    // 中文注释: 可访问根目录统一来自核心工作空间目录约定，避免宿主自己发明另一套规则。
    return <String>[
      ...ProjectWorkspaceCatalog.userWorkspaceDirs.map(
        (item) => item.path.replaceAll(RegExp(r'/$'), ''),
      ),
      ...ProjectWorkspaceCatalog.advancedWorkspaceDirs.map(
        (item) => item.path.replaceAll(RegExp(r'/$'), ''),
      ),
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
    // 中文注释: 内容类型归一化统一在这里完成，保证写入工具和结构化记忆工具口径一致。
    final clean = value.trim().toLowerCase();
    switch (clean) {
      case '大纲':
        return 'outline';
      case '卷纲':
      case '卷钢':
        return 'volume_outline';
      case '章纲':
        return 'chapter_outline';
      case '草稿':
      case '正文草稿':
      case 'working_draft':
        return 'draft';
      case '正文':
      case '正式正文':
      case 'final_chapter':
        return 'chapter';
      case '设定':
      case 'world':
        return 'setting';
      case '角色':
        return 'character';
      case '风格':
        return 'style';
      case '摘要':
      case '概括':
        return 'summary';
      case '知识库':
        return 'knowledge';
      default:
        return clean.isEmpty ? 'draft' : clean;
    }
  }

  String contentTypeDir(String contentType) {
    // 中文注释: 内容类型到目录的映射只保留一份，避免写入工具和结构化工具逐渐分叉。
    switch (normalizeContentType(contentType)) {
      case 'outline':
        return 'outline';
      case 'volume_outline':
        return 'volume_outlines';
      case 'chapter_outline':
        return 'chapter_outlines';
      case 'chapter':
        return 'chapters';
      case 'setting':
        return 'world';
      case 'character':
        return 'characters';
      case 'style':
        return 'styles';
      case 'summary':
        return 'summaries';
      case 'knowledge':
        return 'knowledge';
      default:
        return 'drafts';
    }
  }

  String inferContentTypeFromPath(String relativePath) {
    // 中文注释: 从相对路径推断内容类型，方便编辑类工具补足权限语义和展示文案。
    final clean = cleanRelativePath(relativePath);
    final root = clean.split('/').first;
    switch (root) {
      case 'outline':
        return 'outline';
      case 'volume_outlines':
        return 'volume_outline';
      case 'chapter_outlines':
        return 'chapter_outline';
      case 'chapters':
        return 'chapter';
      case 'world':
        return 'setting';
      case 'characters':
        return 'character';
      case 'styles':
        return 'style';
      case 'summaries':
        return 'summary';
      case 'knowledge':
        return 'knowledge';
      default:
        return 'draft';
    }
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
}
