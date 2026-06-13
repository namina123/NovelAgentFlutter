import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_relative_path_resolver.dart';
import 'project_tree_order_service.dart';

class LocalProjectWorkspacePort implements ProjectWorkspacePort {
  LocalProjectWorkspacePort({
    ProjectRelativePathResolver? pathResolver,
    ProjectTreeOrderService? treeOrderService,
  }) : _pathResolver = pathResolver ?? ProjectRelativePathResolver(),
       _treeOrderService = treeOrderService ?? ProjectTreeOrderService();

  final ProjectRelativePathResolver _pathResolver;
  final ProjectTreeOrderService _treeOrderService;
  static const int _maxListEntriesAttempts = 3;

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
    FileSystemException? lastError;
    for (var attempt = 1; attempt <= _maxListEntriesAttempts; attempt++) {
      final entries = <JsonMap>[];
      try {
        await _collectEntries(
          rootPath: root.path,
          directory: root,
          recursive: recursive,
          entries: entries,
        );
        entries.sort((left, right) {
          // 中文注释: 列表稳定排序可以让 CLI 输出、GUI 资源树和测试结果都保持一致。
          final leftPath = left['relative_path']?.toString() ?? '';
          final rightPath = right['relative_path']?.toString() ?? '';
          return leftPath.compareTo(rightPath);
        });
        return _treeOrderService.sortEntries(root.path, entries);
      } on FileSystemException catch (error) {
        lastError = error;
        if (attempt >= _maxListEntriesAttempts) {
          rethrow;
        }
        await Future<void>.delayed(Duration(milliseconds: 80 * attempt));
      }
    }
    throw lastError ?? FileSystemException('列举项目目录失败。', root.path);
  }

  Future<void> _collectEntries({
    required String rootPath,
    required Directory directory,
    required bool recursive,
    required List<JsonMap> entries,
  }) async {
    await for (final entity in directory.list(
      recursive: false,
      followLinks: false,
    )) {
      final absolutePath = entity.absolute.path;
      final relativePath = _pathResolver.relative(
        rootPath: rootPath,
        absolutePath: absolutePath,
      );
      if (relativePath.trim().isEmpty) {
        continue;
      }
      if (_treeOrderService.isInternalPath(relativePath)) {
        continue;
      }
      final displayName = relativePath.split('/').last;
      entries.add(<String, Object?>{
        'relative_path': relativePath,
        'display_name': displayName,
        'is_dir': entity is Directory,
      });
      if (recursive && entity is Directory) {
        await _collectEntries(
          rootPath: rootPath,
          directory: entity,
          recursive: true,
          entries: entries,
        );
      }
    }
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
  Future<void> createDirectory(String rootPath, String relativePath) async {
    // 中文注释: 目录显式创建供项目骨架等场景使用，避免再依赖占位文件顺带把目录带出来。
    final resolvedPath = _pathResolver.resolve(
      rootPath: rootPath,
      relativePath: relativePath,
    );
    await Directory(resolvedPath).create(recursive: true);
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
