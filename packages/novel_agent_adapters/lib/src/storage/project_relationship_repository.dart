import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_relationship_path_policy.dart';

class ProjectRelationshipRepository {
  ProjectRelationshipRepository({
    required ProjectToolHostPort hostPort,
    ProjectRelationshipPathPolicy? pathPolicy,
    RelationshipRecordMarkdownParserService? parserService,
    RelationshipRecordMarkdownCodecService? codecService,
    RelationshipRecordNormalizerService? normalizerService,
  }) : _hostPort = hostPort,
       _pathPolicy = pathPolicy ?? ProjectRelationshipPathPolicy(),
       _parserService =
           parserService ?? RelationshipRecordMarkdownParserService(),
       _codecService = codecService ?? RelationshipRecordMarkdownCodecService(),
       _normalizerService =
           normalizerService ?? const RelationshipRecordNormalizerService();

  final ProjectToolHostPort _hostPort;
  final ProjectRelationshipPathPolicy _pathPolicy;
  final RelationshipRecordMarkdownParserService _parserService;
  final RelationshipRecordMarkdownCodecService _codecService;
  final RelationshipRecordNormalizerService _normalizerService;

  Future<RelationshipRecord?> readById(
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

  Future<List<RelationshipRecord>> list(ProjectDescriptor project) async {
    final entries = await _hostPort.listEntries(project.rootPath);
    final result = <RelationshipRecord>[];
    for (final entry in entries) {
      final path = ValueReaders.stringValue(entry['relative_path']);
      if (ValueReaders.boolValue(entry['is_dir']) ||
          !path.toLowerCase().startsWith('assets/relationships/')) {
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

  Future<String> save(
    ProjectDescriptor project,
    RelationshipRecord record,
  ) async {
    final path = _pathPolicy.assetPath(record.id);
    final document = RelationshipRecord(
      id: record.id,
      displayName: record.displayName,
      leftEntityId: record.leftEntityId,
      rightEntityId: record.rightEntityId,
      summary: record.summary,
      relationshipType: record.relationshipType,
      status: record.status,
      relatedEntityIds: record.relatedEntityIds,
      relatedForeshadowIds: record.relatedForeshadowIds,
      relatedTimelineIds: record.relatedTimelineIds,
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

  String _fallbackIdFromPath(String relativePath) {
    var name = relativePath.split('/').last;
    if (name.toLowerCase().endsWith('.relationship.md')) {
      name = name.substring(0, name.length - '.relationship.md'.length);
    } else if (name.toLowerCase().endsWith('.md')) {
      name = name.substring(0, name.length - '.md'.length);
    }
    return name.trim();
  }
}
