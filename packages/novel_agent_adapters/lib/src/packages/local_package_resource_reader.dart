import 'dart:io';

class LocalPackageResourceReader {
  const LocalPackageResourceReader();

  Future<String?> readTextResource(
    String entryFilePath,
    String relativePath,
  ) async {
    // 中文注释: 技能 reference 读取只允许访问包目录内已声明的相对资源，不扩张到任意磁盘路径。
    final normalizedRelativePath = _normalizeRelativePath(relativePath);
    if (entryFilePath.trim().isEmpty || normalizedRelativePath.isEmpty) {
      return null;
    }
    final segments = normalizedRelativePath.split('/');
    if (segments.any((segment) => segment == '..' || segment == '.')) {
      return null;
    }
    final packageDirectory = File(entryFilePath).parent.path;
    final resolvedPath = [
      packageDirectory,
      ...segments,
    ].join(Platform.pathSeparator);
    final file = File(resolvedPath);
    if (!await file.exists()) {
      return null;
    }
    return file.readAsString();
  }

  String normalizeResourcePath(String value) {
    return _normalizeRelativePath(value);
  }

  String _normalizeRelativePath(String value) {
    final normalized = value.trim().replaceAll('\\', '/');
    return normalized.replaceFirst(RegExp(r'^/+'), '');
  }
}
