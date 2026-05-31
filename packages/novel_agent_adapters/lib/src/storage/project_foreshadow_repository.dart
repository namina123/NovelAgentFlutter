import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_foreshadow_path_policy.dart';

class ProjectForeshadowRepository {
  ProjectForeshadowRepository({
    required ProjectToolHostPort hostPort,
    ProjectForeshadowPathPolicy? pathPolicy,
    ForeshadowRecordMarkdownParserService? parserService,
    ForeshadowRecordMarkdownCodecService? codecService,
    ForeshadowRecordNormalizerService? normalizerService,
  }) : _hostPort = hostPort,
       _pathPolicy = pathPolicy ?? ProjectForeshadowPathPolicy(),
       _parserService = parserService ?? ForeshadowRecordMarkdownParserService(),
       _codecService = codecService ?? ForeshadowRecordMarkdownCodecService(),
       _normalizerService =
           normalizerService ?? const ForeshadowRecordNormalizerService();

  final ProjectToolHostPort _hostPort;
  final ProjectForeshadowPathPolicy _pathPolicy;
  final ForeshadowRecordMarkdownParserService _parserService;
  final ForeshadowRecordMarkdownCodecService _codecService;
  final ForeshadowRecordNormalizerService _normalizerService;

  Future<ForeshadowRecord?> readById(
    ProjectDescriptor project,
    String recordId,
  ) async {
    // 中文注释: 伏笔读取先看新资产路径，再兼容旧路径，避免运行链再次把旧目录当作主存储。
    for (final path in <String>[
      _pathPolicy.assetPath(recordId),
      _pathPolicy.legacyPath(recordId),
    ]) {
      final content = await _hostPort.readTextFile(project.rootPath, path);
      if ((content ?? '').trim().isEmpty) {
        continue;
      }
      return _normalizerService.normalize(
        _parserService.parseDocument(
          content!,
          fallbackId: recordId,
          relativePath: path,
        ),
      );
    }
    return null;
  }

  Future<List<ForeshadowRecord>> list(ProjectDescriptor project) async {
    final entries = await _hostPort.listEntries(project.rootPath);
    final result = <ForeshadowRecord>[];
    final seenIds = <String>{};
    for (final entry in entries) {
      final path = ValueReaders.stringValue(entry['relative_path']);
      if (ValueReaders.boolValue(entry['is_dir']) || !_isForeshadowPath(path)) {
        continue;
      }
      final content = await _hostPort.readTextFile(project.rootPath, path);
      if ((content ?? '').trim().isEmpty) {
        continue;
      }
      final parsed = _normalizerService.normalize(
        _parserService.parseDocument(
          content!,
          fallbackId: _fallbackIdFromPath(path),
          relativePath: path,
        ),
      );
      if (parsed.id.trim().isEmpty || seenIds.contains(parsed.id)) {
        continue;
      }
      seenIds.add(parsed.id);
      result.add(parsed);
    }
    return result;
  }

  Future<String> save(ProjectDescriptor project, ForeshadowRecord record) async {
    final path = _pathPolicy.assetPath(record.id);
    final document = ForeshadowRecord(
      id: record.id,
      title: record.title,
      status: record.status,
      summary: record.summary,
      plantedChapterPath: record.plantedChapterPath,
      targetPayoffPath: record.targetPayoffPath,
      relatedEntityIds: record.relatedEntityIds,
      relatedTimelineIds: record.relatedTimelineIds,
      relatedRelationshipIds: record.relatedRelationshipIds,
      relatedPaths: record.relatedPaths,
      triggerConditions: record.triggerConditions,
      payoffExpectations: record.payoffExpectations,
      tags: record.tags,
      notes: record.notes,
      sourcePath: path,
      metadata: record.metadata,
    );
    await _hostPort.writeTextFile(
      project.rootPath,
      path,
      _codecService.encode(document),
    );
    return path;
  }

  bool _isForeshadowPath(String relativePath) {
    final lower = relativePath.toLowerCase();
    return lower.startsWith('assets/foreshadows/') ||
        lower.startsWith('world/foreshadows/');
  }

  String _fallbackIdFromPath(String relativePath) {
    var name = relativePath.split('/').last;
    if (name.toLowerCase().endsWith('.foreshadow.md')) {
      name = name.substring(0, name.length - '.foreshadow.md'.length);
    } else if (name.toLowerCase().endsWith('.md')) {
      name = name.substring(0, name.length - '.md'.length);
    }
    return name.trim();
  }
}
