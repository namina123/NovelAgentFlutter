import '../ports/project_tool_host_port.dart';

class ProjectEntryPathService {
  const ProjectEntryPathService();

  String cleanRelativePath(String value) {
    // 中文注释: 项目相对路径统一在这里做轻量清洗，避免各个入口分别处理分隔符与空白。
    final normalized = value.replaceAll('\\', '/').trim();
    if (normalized.isEmpty) {
      return '';
    }
    final segments = <String>[];
    for (final segment in normalized.split('/')) {
      final clean = segment.trim();
      if (clean.isEmpty || clean == '.') {
        continue;
      }
      if (clean == '..') {
        return '';
      }
      segments.add(clean);
    }
    return segments.join('/');
  }

  bool isSafeScopePath(String relativePath) {
    // 中文注释: 目录路径只允许项目内相对路径，不允许绝对路径和父级逃逸。
    final clean = cleanRelativePath(relativePath);
    if (clean.isEmpty) {
      return false;
    }
    if (clean.startsWith('/') || RegExp(r'^[A-Za-z]:').hasMatch(clean)) {
      return false;
    }
    return !clean.contains('..');
  }

  bool isSafeFilePath(String relativePath) {
    // 中文注释: 文件路径除了基础边界外，还要求最终包含一个文件名片段。
    if (!isSafeScopePath(relativePath)) {
      return false;
    }
    final clean = cleanRelativePath(relativePath);
    return clean.isNotEmpty && clean.split('/').last.trim().isNotEmpty;
  }

  String safeFileName(String value, {String fallback = 'untitled'}) {
    // 中文注释: 文件名清洗保持跨平台兼容，但尽量保留用户输入的可读性。
    var result = value.trim();
    result = result.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    result = result.replaceAll(RegExp(r'\s+'), '_');
    result = result.replaceAll(RegExp(r'_+'), '_');
    result = result.replaceAll(RegExp(r'^_+|_+$'), '');
    return result.isEmpty ? fallback : result;
  }

  Future<String> uniqueRelativePath({
    required ProjectToolHostPort hostPort,
    required String rootPath,
    required String relativePath,
  }) async {
    // 中文注释: 冲突去重策略统一在这里，GUI、CLI 和工具写入都使用同一命名口径。
    final clean = cleanRelativePath(relativePath);
    if (clean.isEmpty) {
      return '';
    }
    if (!await hostPort.entryExists(rootPath, clean)) {
      return clean;
    }
    final slashIndex = clean.lastIndexOf('/');
    final directory = slashIndex >= 0 ? clean.substring(0, slashIndex) : '';
    final fileName = slashIndex >= 0 ? clean.substring(slashIndex + 1) : clean;
    final dotIndex = fileName.lastIndexOf('.');
    final baseName = dotIndex > 0 ? fileName.substring(0, dotIndex) : fileName;
    final extension = dotIndex > 0 ? fileName.substring(dotIndex) : '';
    var index = 2;
    while (true) {
      final nextName = '${baseName}_$index$extension';
      final candidate = directory.isEmpty ? nextName : '$directory/$nextName';
      if (!await hostPort.entryExists(rootPath, candidate)) {
        return candidate;
      }
      index += 1;
    }
  }
}
