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
    await file.writeAsString(
      const JsonEncoder.withIndent(
        '  ',
      ).convert(_codecService.encode(instance)),
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
    return _codecService.decode(ValueReaders.mapValue(document));
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
      final run = _codecService.decode(ValueReaders.mapValue(document));
      result.add(run);
    }
    result.sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
    return result;
  }

  @override
  Future<List<RunInstance>> listByProject(String projectKey) async {
    final cleanProjectKey = projectKey.trim();
    final all = await listAll();
    return all
        .where((run) => run.project.projectKey == cleanProjectKey)
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
}
