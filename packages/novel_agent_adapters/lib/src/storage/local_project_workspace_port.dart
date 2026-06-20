import 'dart:isolate';
import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_text_file_read_service.dart';
import 'project_relative_path_resolver.dart';
import 'project_tree_order_service.dart';
import 'project_tree_order_store.dart';

class LocalProjectWorkspacePort implements ProjectWorkspacePort {
  LocalProjectWorkspacePort({
    ProjectRelativePathResolver? pathResolver,
    ProjectTreeOrderService? treeOrderService,
    ProjectTextFileReadService? textFileReadService,
  }) : _pathResolver = pathResolver ?? ProjectRelativePathResolver(),
       _treeOrderService = treeOrderService ?? ProjectTreeOrderService(),
       _textFileReadService =
           textFileReadService ?? const ProjectTextFileReadService();

  final ProjectRelativePathResolver _pathResolver;
  final ProjectTreeOrderService _treeOrderService;
  final ProjectTextFileReadService _textFileReadService;
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
      try {
        final entries = await Isolate.run(
          () => _scanProjectEntriesSync(root.path, recursive: recursive),
        );
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

  @override
  Future<String?> readTextFile(String rootPath, String relativePath) async {
    // 中文注释: 项目文本读取对 source document 走统一 reader，对其余文本保留严格读取，避免导入资料因编码差异把整条链路炸掉。
    final resolvedPath = _pathResolver.resolve(
      rootPath: rootPath,
      relativePath: relativePath,
    );
    return _textFileReadService.readFile(resolvedPath);
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

List<JsonMap> _scanProjectEntriesSync(
  String rootPath, {
  required bool recursive,
}) {
  final root = Directory(rootPath);
  if (!root.existsSync()) {
    return const <JsonMap>[];
  }
  final pathResolver = ProjectRelativePathResolver();
  final entries = <JsonMap>[];

  void collect(Directory directory) {
    final children = directory.listSync(recursive: false, followLinks: false);
    for (final entity in children) {
      final absolutePath = entity.absolute.path;
      final relativePath = pathResolver.relative(
        rootPath: root.path,
        absolutePath: absolutePath,
      );
      if (relativePath.trim().isEmpty) {
        continue;
      }
      if (_isInternalProjectPath(relativePath)) {
        continue;
      }
      entries.add(<String, Object?>{
        'relative_path': relativePath,
        'display_name': relativePath.split('/').last,
        'is_dir': entity is Directory,
      });
      if (recursive && entity is Directory) {
        collect(entity);
      }
    }
  }

  collect(root);
  entries.sort((left, right) {
    final leftPath = left['relative_path']?.toString() ?? '';
    final rightPath = right['relative_path']?.toString() ?? '';
    return leftPath.compareTo(rightPath);
  });
  return entries;
}

bool _isInternalProjectPath(String relativePath) {
  final cleanPath = relativePath.replaceAll('\\', '/').trim();
  if (cleanPath.isEmpty) {
    return false;
  }
  return cleanPath == ProjectTreeOrderStore.internalDirectoryPath ||
      cleanPath.startsWith('${ProjectTreeOrderStore.internalDirectoryPath}/');
}
