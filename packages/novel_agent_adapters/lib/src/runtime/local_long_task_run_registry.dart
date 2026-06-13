import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

import 'local_long_task_runtime_path_service.dart';
import 'run_instance_document_codec_service.dart';

class LocalLongTaskRunRegistry implements LongTaskRunRegistry {
  LocalLongTaskRunRegistry({
    required String settingsRootPath,
    LocalLongTaskRuntimePathService? pathService,
    RunInstanceDocumentCodecService? codecService,
  }) : _pathService =
           pathService ??
           LocalLongTaskRuntimePathService(settingsRootPath: settingsRootPath),
       _codecService = codecService ?? const RunInstanceDocumentCodecService();

  final LocalLongTaskRuntimePathService _pathService;
  final RunInstanceDocumentCodecService _codecService;

  @override
  Future<void> save(RunInstance instance) async {
    // 中文注释: registry 只负责全局运行实例的持久化，不判断 workflow 语义，也不承担心跳调度。
    final file = File(_pathService.runDocumentPath(instance.id));
    await file.parent.create(recursive: true);
    final persisted = _persistedInstance(instance);
    await file.writeAsString(
      const JsonEncoder.withIndent(
        '  ',
      ).convert(_codecService.encode(persisted)),
      flush: true,
    );
  }

  @override
  Future<RunInstance?> findById(String runId) async {
    final file = File(_pathService.runDocumentPath(runId));
    if (!await file.exists()) {
      return null;
    }
    final document = jsonDecode(await file.readAsString());
    return _restoredInstance(_codecService.decode(ValueReaders.mapValue(document)));
  }

  @override
  Future<List<RunInstance>> listAll() async {
    final root = Directory(_pathService.registryRootPath());
    if (!await root.exists()) {
      return const <RunInstance>[];
    }
    final result = <RunInstance>[];
    await for (final entity in root.list(
      recursive: false,
      followLinks: false,
    )) {
      if (entity is! File || !entity.path.toLowerCase().endsWith('.json')) {
        continue;
      }
      final document = jsonDecode(await entity.readAsString());
      final run = _restoredInstance(
        _codecService.decode(ValueReaders.mapValue(document)),
      );
      result.add(run);
    }
    result.sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
    return result;
  }

  @override
  Future<List<RunInstance>> listByProject(String projectKey) async {
    final cleanProjectKey = _normalizePathForCompare(projectKey);
    final all = await listAll();
    return all
        .where(
          (run) =>
              _normalizePathForCompare(run.project.projectKey) ==
              cleanProjectKey,
        )
        .toList(growable: false);
  }

  @override
  Future<List<RunInstance>> listActive() async {
    final all = await listAll();
    return all.where((run) => run.isActive).toList(growable: false);
  }

  @override
  Future<void> delete(String runId) async {
    final file = File(_pathService.runDocumentPath(runId));
    if (await file.exists()) {
      await file.delete();
    }
  }

  RunInstance _persistedInstance(RunInstance instance) {
    return instance.copyWith(
      project: RunProjectReference(
        projectId: instance.project.projectId,
        projectKey: _storedProjectPath(instance.project.projectKey),
        rootPath: _storedProjectPath(instance.project.rootPath),
        title: instance.project.title,
        projectTypeId: instance.project.projectTypeId,
        storageStrategy: instance.project.storageStrategy,
      ),
    );
  }

  RunInstance _restoredInstance(RunInstance instance) {
    return instance.copyWith(
      project: RunProjectReference(
        projectId: instance.project.projectId,
        projectKey: _resolveProjectPath(instance.project.projectKey),
        rootPath: _resolveProjectPath(instance.project.rootPath),
        title: instance.project.title,
        projectTypeId: instance.project.projectTypeId,
        storageStrategy: instance.project.storageStrategy,
      ),
    );
  }

  String _storedProjectPath(String projectPath) {
    final cleanPath = projectPath.trim();
    if (cleanPath.isEmpty) {
      return '';
    }
    final absoluteProjectPath = Directory(cleanPath).absolute.path;
    final absoluteBasePath = Directory(_pathService.settingsRootPath).absolute.path;
    final relative = _relativePathFromBase(
      absoluteTargetPath: absoluteProjectPath,
      absoluteBasePath: absoluteBasePath,
    );
    return relative ?? absoluteProjectPath;
  }

  String _resolveProjectPath(String storedPath) {
    final cleanPath = storedPath.trim();
    if (cleanPath.isEmpty) {
      return '';
    }
    if (cleanPath.startsWith('/') || RegExp(r'^[A-Za-z]:').hasMatch(cleanPath)) {
      return _normalizedAbsolutePath(cleanPath);
    }
    return _normalizedAbsolutePath(
      '${_pathService.settingsRootPath}${Platform.pathSeparator}${cleanPath.replaceAll('/', Platform.pathSeparator)}',
    );
  }

  String? _relativePathFromBase({
    required String absoluteTargetPath,
    required String absoluteBasePath,
  }) {
    final normalizedTarget = _normalizePathForCompare(absoluteTargetPath);
    final normalizedBase = _normalizePathForCompare(absoluteBasePath);
    final targetRoot = _pathRoot(normalizedTarget);
    final baseRoot = _pathRoot(normalizedBase);
    if (targetRoot != baseRoot) {
      return null;
    }
    final targetSegments = _pathSegmentsWithoutRoot(normalizedTarget);
    final baseSegments = _pathSegmentsWithoutRoot(normalizedBase);
    var common = 0;
    final limit = targetSegments.length < baseSegments.length
        ? targetSegments.length
        : baseSegments.length;
    while (common < limit && targetSegments[common] == baseSegments[common]) {
      common += 1;
    }
    final result = <String>[
      for (var index = common; index < baseSegments.length; index += 1) '..',
      ...targetSegments.sublist(common),
    ];
    return result.isEmpty ? '.' : result.join('/');
  }

  String _normalizePathForCompare(String path) {
    return Directory(path).absolute.path
        .replaceAll('\\', '/')
        .replaceAll(RegExp('/+'), '/')
        .replaceAll(RegExp('/\$'), '')
        .toLowerCase();
  }

  String _pathRoot(String normalizedPath) {
    final windowsRoot = RegExp(r'^[a-z]:').stringMatch(normalizedPath);
    if (windowsRoot != null) {
      return windowsRoot;
    }
    return normalizedPath.startsWith('/') ? '/' : '';
  }

  List<String> _pathSegmentsWithoutRoot(String normalizedPath) {
    final root = _pathRoot(normalizedPath);
    var remainder = normalizedPath;
    if (root.isNotEmpty) {
      remainder = remainder.substring(root.length);
    }
    if (remainder.startsWith('/')) {
      remainder = remainder.substring(1);
    }
    if (remainder.isEmpty) {
      return const <String>[];
    }
    return remainder
        .split('/')
        .where((segment) => segment.trim().isNotEmpty)
        .toList(growable: false);
  }

  String _normalizedAbsolutePath(String path) {
    final absolutePath = Directory(path).absolute.path.replaceAll('\\', '/');
    final root = _pathRoot(absolutePath);
    var remainder = absolutePath;
    if (root.isNotEmpty) {
      remainder = remainder.substring(root.length);
    }
    if (remainder.startsWith('/')) {
      remainder = remainder.substring(1);
    }
    final segments = <String>[];
    for (final segment in remainder.split('/')) {
      if (segment.isEmpty || segment == '.') {
        continue;
      }
      if (segment == '..') {
        if (segments.isNotEmpty) {
          segments.removeLast();
        }
        continue;
      }
      segments.add(segment);
    }
    if (root == '/') {
      return segments.isEmpty ? '/' : '/${segments.join('/')}';
    }
    if (RegExp(r'^[A-Za-z]:').hasMatch(root)) {
      final body = segments.join(Platform.pathSeparator);
      return body.isEmpty
          ? '$root${Platform.pathSeparator}'
          : '$root${Platform.pathSeparator}$body';
    }
    return segments.join(Platform.pathSeparator);
  }
}
