import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_relative_path_resolver.dart';

class ProjectTreeOrderStore {
  ProjectTreeOrderStore({ProjectRelativePathResolver? pathResolver})
    : _pathResolver = pathResolver ?? ProjectRelativePathResolver();

  static const String internalDirectoryPath = '.novel_agent';
  static const String internalRelativePath =
      '$internalDirectoryPath/project_tree_order.json';

  final ProjectRelativePathResolver _pathResolver;

  Future<Map<String, List<String>>> load(String rootPath) async {
    // 中文注释: 排序元数据单独落盘为内部 JSON，避免把资源树展示顺序和普通项目文档耦在一起。
    final file = File(
      _pathResolver.resolve(
        rootPath: rootPath,
        relativePath: internalRelativePath,
      ),
    );
    if (!await file.exists()) {
      return <String, List<String>>{};
    }
    try {
      final decoded = jsonDecode(await file.readAsString());
      final document = ValueReaders.mapValue(decoded);
      final directories = ValueReaders.mapValue(document['directories']);
      final result = <String, List<String>>{};
      for (final entry in directories.entries) {
        final directoryPath = _normalizeDirectoryPath(entry.key);
        final names = ValueReaders.stringList(entry.value)
            .map(_normalizeChildName)
            .where((item) => item.isNotEmpty)
            .toList(growable: false);
        if (names.isEmpty && directoryPath.isNotEmpty) {
          continue;
        }
        result[directoryPath] = names;
      }
      return result;
    } catch (_) {
      return <String, List<String>>{};
    }
  }

  Future<void> save(String rootPath, Map<String, List<String>> document) async {
    // 中文注释: 排序文档统一按稳定结构写回，便于后续 CLI、GUI 和人工排查共享同一份元数据。
    final normalized = <String, Object?>{};
    final directoryKeys = document.keys.toList(growable: false)..sort();
    for (final key in directoryKeys) {
      final names = document[key] ?? const <String>[];
      normalized[_normalizeDirectoryPath(key)] = names
          .map(_normalizeChildName)
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    final file = File(
      _pathResolver.resolve(
        rootPath: rootPath,
        relativePath: internalRelativePath,
      ),
    );
    await file.parent.create(recursive: true);
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(
      '${encoder.convert(<String, Object?>{'version': 1, 'directories': normalized})}\n',
      flush: true,
    );
  }

  Future<void> delete(String rootPath) async {
    // 中文注释: 当排序元数据为空时直接移除内部文件，避免项目根目录残留无意义配置。
    final file = File(
      _pathResolver.resolve(
        rootPath: rootPath,
        relativePath: internalRelativePath,
      ),
    );
    if (await file.exists()) {
      await file.delete();
    }
    final directory = file.parent;
    if (await directory.exists()) {
      final children = await directory.list(followLinks: false).toList();
      if (children.isEmpty) {
        await directory.delete();
      }
    }
  }

  bool isInternalPath(String relativePath) {
    // 中文注释: 内部排序目录不应暴露给资源树和常规工具列表，因此路径判定集中在这里。
    final cleanPath = relativePath.replaceAll('\\', '/').trim();
    if (cleanPath.isEmpty) {
      return false;
    }
    return cleanPath == internalDirectoryPath ||
        cleanPath.startsWith('$internalDirectoryPath/');
  }

  String _normalizeDirectoryPath(String value) {
    // 中文注释: 目录键值统一去掉首尾斜杠，根目录用空字符串表示，便于排序服务稳定命中。
    final clean = value.replaceAll('\\', '/').trim();
    if (clean.isEmpty || clean == '.') {
      return '';
    }
    return clean.replaceAll(RegExp(r'^/+|/+$'), '');
  }

  String _normalizeChildName(String value) {
    // 中文注释: 子项顺序只记录同级名字，不记录完整路径，避免父目录重命名后整份文档失效。
    final clean = value.replaceAll('\\', '/').trim();
    if (clean.isEmpty) {
      return '';
    }
    return clean.split('/').last.trim();
  }
}
