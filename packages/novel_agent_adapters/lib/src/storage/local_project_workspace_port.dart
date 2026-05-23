import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_relative_path_resolver.dart';

class LocalProjectWorkspacePort implements ProjectWorkspacePort {
  LocalProjectWorkspacePort({ProjectRelativePathResolver? pathResolver})
    : _pathResolver = pathResolver ?? ProjectRelativePathResolver();

  final ProjectRelativePathResolver _pathResolver;

  @override
  Future<List<JsonMap>> listEntries(
    String rootPath, {
    bool recursive = true,
  }) async {
    // 中文注释: 本地工作区列举只负责目录快照，不承担业务筛选，让 core 自己决定上下文价值。
    final root = Directory(rootPath);
    if (!await root.exists()) {
      return const <JsonMap>[];
    }
    final entries = <JsonMap>[];
    await for (final entity in root.list(
      recursive: recursive,
      followLinks: false,
    )) {
      final absolutePath = entity.absolute.path;
      final relativePath = _pathResolver.relative(
        rootPath: root.path,
        absolutePath: absolutePath,
      );
      if (relativePath.trim().isEmpty) {
        continue;
      }
      final displayName = relativePath.split('/').last;
      entries.add(<String, Object?>{
        'relative_path': relativePath,
        'display_name': displayName,
        'is_dir': entity is Directory,
      });
    }
    entries.sort((left, right) {
      // 中文注释: 列表稳定排序可以让 CLI 输出、GUI 资源树和测试结果都保持一致。
      final leftPath = left['relative_path']?.toString() ?? '';
      final rightPath = right['relative_path']?.toString() ?? '';
      return leftPath.compareTo(rightPath);
    });
    return entries;
  }

  @override
  Future<String?> readTextFile(String rootPath, String relativePath) async {
    // 中文注释: 本地文本读取只做文件存在与编码读取，不夹带任何创作层规则。
    final resolvedPath = _pathResolver.resolve(
      rootPath: rootPath,
      relativePath: relativePath,
    );
    final file = File(resolvedPath);
    if (!await file.exists()) {
      return null;
    }
    return file.readAsString();
  }

  @override
  Future<void> writeTextFile(
    String rootPath,
    String relativePath,
    String content,
  ) async {
    // 中文注释: 写文件时由适配器保证目录存在，但具体写到哪个相对路径仍由 core 用例决定。
    final resolvedPath = _pathResolver.resolve(
      rootPath: rootPath,
      relativePath: relativePath,
    );
    final file = File(resolvedPath);
    await file.parent.create(recursive: true);
    await file.writeAsString(content, flush: true);
  }
}
