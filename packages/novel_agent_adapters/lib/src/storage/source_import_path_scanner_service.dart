import 'dart:io';

class SourceImportPathScannerService {
  const SourceImportPathScannerService();

  Future<List<String>> scan({
    required String sourcePath,
    bool recursive = true,
  }) async {
    // 中文注释: 扫描服务只返回文件路径，不做格式识别和内容读取，供 discovery 层统一做后续筛选。
    final trimmed = sourcePath.trim();
    if (trimmed.isEmpty) {
      return const <String>[];
    }
    final entity = await FileSystemEntity.type(trimmed, followLinks: false);
    if (entity == FileSystemEntityType.notFound) {
      return const <String>[];
    }
    if (entity == FileSystemEntityType.file) {
      return <String>[_normalizePath(File(trimmed).absolute.path)];
    }
    if (entity != FileSystemEntityType.directory) {
      return const <String>[];
    }
    final result = <String>[];
    await _collectDirectoryFiles(
      directory: Directory(trimmed),
      recursive: recursive,
      result: result,
    );
    result.sort();
    return List<String>.unmodifiable(result);
  }

  Future<void> _collectDirectoryFiles({
    required Directory directory,
    required bool recursive,
    required List<String> result,
  }) async {
    // 中文注释: 目录递归只收集普通文件，符号链接和目录本身都交给上层 discovery 决定要不要消费。
    await for (final entity in directory.list(
      recursive: false,
      followLinks: false,
    )) {
      if (entity is File) {
        result.add(_normalizePath(entity.absolute.path));
        continue;
      }
      if (recursive && entity is Directory) {
        await _collectDirectoryFiles(
          directory: entity,
          recursive: true,
          result: result,
        );
      }
    }
  }

  String _normalizePath(String value) {
    // 中文注释: 扫描结果统一使用斜杠，避免后续 discovery、测试和日志在 Windows 上出现混合分隔符。
    return value.replaceAll('\\', '/');
  }
}
