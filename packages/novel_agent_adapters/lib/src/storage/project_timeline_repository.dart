import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_timeline_path_policy.dart';

class ProjectTimelineRepository {
  ProjectTimelineRepository({
    required ProjectToolHostPort hostPort,
    ProjectTimelinePathPolicy? pathPolicy,
    TimelineRecordMarkdownParserService? parserService,
    TimelineRecordMarkdownCodecService? codecService,
    TimelineRecordNormalizerService? normalizerService,
  }) : _hostPort = hostPort,
       _pathPolicy = pathPolicy ?? ProjectTimelinePathPolicy(),
       _parserService = parserService ?? TimelineRecordMarkdownParserService(),
       _codecService = codecService ?? TimelineRecordMarkdownCodecService(),
       _normalizerService =
           normalizerService ?? const TimelineRecordNormalizerService();

  final ProjectToolHostPort _hostPort;
  final ProjectTimelinePathPolicy _pathPolicy;
  final TimelineRecordMarkdownParserService _parserService;
  final TimelineRecordMarkdownCodecService _codecService;
  final TimelineRecordNormalizerService _normalizerService;

  Future<TimelineRecord?> readById(
    ProjectDescriptor project,
    String recordId,
  ) async {
    final path = _pathPolicy.assetPath(recordId);
    final content = await _hostPort.readTextFile(project.rootPath, path);
    if ((content ?? '').trim().isEmpty) {
      return null;
    }
    return _normalizerService.normalize(
      _parserService.parseDocument(
        content!,
        fallbackId: recordId,
        relativePath: path,
      ),
    );
  }

  Future<List<TimelineRecord>> list(ProjectDescriptor project) async {
    final entries = await _hostPort.listEntries(project.rootPath);
    final result = <TimelineRecord>[];
    for (final entry in entries) {
      final path = ValueReaders.stringValue(entry['relative_path']);
      if (ValueReaders.boolValue(entry['is_dir']) ||
          !path.toLowerCase().startsWith('assets/timeline/')) {
        continue;
      }
      final content = await _hostPort.readTextFile(project.rootPath, path);
      if ((content ?? '').trim().isEmpty) {
        continue;
      }
      result.add(
        _normalizerService.normalize(
          _parserService.parseDocument(
            content!,
            fallbackId: _fallbackIdFromPath(path),
            relativePath: path,
          ),
        ),
      );
    }
    return result;
  }

  Future<String> save(ProjectDescriptor project, TimelineRecord record) async {
    final path = _pathPolicy.assetPath(record.id);
    final document = TimelineRecord(
      id: record.id,
      displayName: record.displayName,
      summary: record.summary,
      eventType: record.eventType,
      status: record.status,
      phaseLabel: record.phaseLabel,
      sequence: record.sequence,
      relatedEntityIds: record.relatedEntityIds,
      relatedForeshadowIds: record.relatedForeshadowIds,
      relatedRelationshipIds: record.relatedRelationshipIds,
      relatedPaths: record.relatedPaths,
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

  String _fallbackIdFromPath(String relativePath) {
    var name = relativePath.split('/').last;
    if (name.toLowerCase().endsWith('.timeline.md')) {
      name = name.substring(0, name.length - '.timeline.md'.length);
    } else if (name.toLowerCase().endsWith('.md')) {
      name = name.substring(0, name.length - '.md'.length);
    }
    return name.trim();
  }
}
