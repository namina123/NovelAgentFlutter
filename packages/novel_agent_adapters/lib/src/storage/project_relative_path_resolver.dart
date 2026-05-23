import 'dart:io';

class ProjectRelativePathResolver {
  String resolve({required String rootPath, required String relativePath}) {
    // 中文注释: 项目相对路径解析统一在这里完成，避免不同适配器各自处理导致越界或分隔符不一致。
    final cleanRelative = relativePath.replaceAll('\\', '/').trim();
    if (cleanRelative.isEmpty) {
      throw ArgumentError.value(relativePath, 'relativePath', '相对路径不能为空。');
    }
    if (cleanRelative.startsWith('/') ||
        RegExp(r'^[A-Za-z]:').hasMatch(cleanRelative)) {
      throw ArgumentError.value(relativePath, 'relativePath', '只允许项目内相对路径。');
    }
    final segments = <String>[];
    for (final segment in cleanRelative.split('/')) {
      if (segment.isEmpty || segment == '.') {
        continue;
      }
      if (segment == '..') {
        if (segments.isEmpty) {
          throw ArgumentError.value(
            relativePath,
            'relativePath',
            '相对路径越过了项目根目录。',
          );
        }
        segments.removeLast();
        continue;
      }
      segments.add(segment);
    }
    if (segments.isEmpty) {
      throw ArgumentError.value(relativePath, 'relativePath', '相对路径不能为空。');
    }
    final rootUri = Directory(rootPath).absolute.uri;
    final fullPath = rootUri
        .resolve(segments.join('/'))
        .toFilePath(windows: Platform.isWindows);
    _assertInsideRoot(rootPath: rootPath, resolvedPath: fullPath);
    return fullPath;
  }

  String relative({required String rootPath, required String absolutePath}) {
    // 中文注释: 列目录时需要把绝对路径映射回项目相对路径，这里统一做平台兼容转换。
    final root = Directory(rootPath).absolute.path;
    final target = FileSystemEntity.isDirectorySync(absolutePath)
        ? Directory(absolutePath).absolute.path
        : File(absolutePath).absolute.path;
    final normalizedRoot = _normalizeForCompare(root);
    final normalizedTarget = _normalizeForCompare(target);
    if (normalizedTarget == normalizedRoot) {
      return '';
    }
    if (!normalizedTarget.startsWith('$normalizedRoot/')) {
      throw ArgumentError.value(absolutePath, 'absolutePath', '目标路径不在项目根目录内。');
    }
    return target.substring(root.length + 1).replaceAll('\\', '/');
  }

  void _assertInsideRoot({
    required String rootPath,
    required String resolvedPath,
  }) {
    // 中文注释: 这里做最终边界检查，防止路径标准化后仍有机会逃出项目根目录。
    final normalizedRoot = _normalizeForCompare(
      Directory(rootPath).absolute.path,
    );
    final normalizedResolved = _normalizeForCompare(
      FileSystemEntity.isDirectorySync(resolvedPath)
          ? Directory(resolvedPath).absolute.path
          : File(resolvedPath).absolute.path,
    );
    if (normalizedResolved == normalizedRoot) {
      return;
    }
    if (!normalizedResolved.startsWith('$normalizedRoot/')) {
      throw ArgumentError.value(resolvedPath, 'resolvedPath', '目标路径不在项目根目录内。');
    }
  }

  String _normalizeForCompare(String value) {
    // 中文注释: Windows 与 Unix 的路径比较语义不同，这里统一转成可前缀比较的形式。
    final normalized = value.replaceAll('\\', '/');
    return Platform.isWindows ? normalized.toLowerCase() : normalized;
  }
}
