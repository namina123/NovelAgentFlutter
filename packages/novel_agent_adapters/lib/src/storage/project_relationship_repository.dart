import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_relationship_path_policy.dart';
import 'project_structured_content_bridge_service.dart';

class ProjectRelationshipRepository {
  ProjectRelationshipRepository({
    required ProjectToolHostPort hostPort,
    ProjectRelationshipPathPolicy? pathPolicy,
    RelationshipRecordMarkdownParserService? parserService,
    RelationshipRecordMarkdownCodecService? codecService,
    RelationshipRecordNormalizerService? normalizerService,
    ProjectStructuredContentBridgeService? structuredContentBridgeService,
  }) : _hostPort = hostPort,
       _pathPolicy = pathPolicy ?? ProjectRelationshipPathPolicy(),
       _parserService =
           parserService ?? RelationshipRecordMarkdownParserService(),
       _codecService = codecService ?? RelationshipRecordMarkdownCodecService(),
       _normalizerService =
           normalizerService ?? const RelationshipRecordNormalizerService(),
       _structuredContentBridgeService =
           structuredContentBridgeService ??
           ProjectStructuredContentBridgeService();

  final ProjectToolHostPort _hostPort;
  final ProjectRelationshipPathPolicy _pathPolicy;
  final RelationshipRecordMarkdownParserService _parserService;
  final RelationshipRecordMarkdownCodecService _codecService;
  final RelationshipRecordNormalizerService _normalizerService;
  final ProjectStructuredContentBridgeService _structuredContentBridgeService;

  Future<RelationshipRecord?> readById(
    ProjectDescriptor project,
    String recordId,
  ) async {
    final path = _pathPolicy.assetPath(recordId);
    final content = await _readContent(project, path);
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
    final seenIds = <String>{};
    void addRecord(String content, String path, String fallbackId) {
      if (content.trim().isEmpty) {
        return;
      }
      final record = _normalizerService.normalize(
        _parserService.parseDocument(
          content,
          fallbackId: fallbackId,
          relativePath: path,
        ),
      );
      if (record.id.trim().isEmpty || seenIds.contains(record.id)) {
        return;
      }
      seenIds.add(record.id);
      result.add(record);
    }

    final structuredDocuments = await _structuredContentBridgeService
        .listStructuredDocuments(project: project);
    for (final document in structuredDocuments) {
      final path = document.markdownPath.trim().isEmpty
          ? document.documentId
          : document.markdownPath;
      if (!path.toLowerCase().startsWith('assets/relationships/')) {
        continue;
      }
      addRecord(document.combinedText(), path, _fallbackIdFromPath(path));
    }
    for (final entry in entries) {
      final path = ValueReaders.stringValue(entry['relative_path']);
      if (ValueReaders.boolValue(entry['is_dir']) ||
          !path.toLowerCase().startsWith('assets/relationships/')) {
        continue;
      }
      final content = await _readContent(project, path);
      addRecord(content ?? '', path, _fallbackIdFromPath(path));
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
    final content = _codecService.encode(document);
    final snapshot = await _structuredContentBridgeService
        .loadStructuredDocument(project: project, documentPath: path);
    try {
      await _structuredContentBridgeService.persistStructuredDocument(
        project: project,
        documentPath: path,
        documentKind: 'relationship_record',
        title: document.displayName,
        content: content,
      );
      await _hostPort.writeTextFile(project.rootPath, path, content);
    } catch (_) {
      await _restoreStructuredSnapshot(
        project: project,
        documentPath: path,
        snapshot: snapshot,
      );
      rethrow;
    }
    return path;
  }

  Future<String?> _readContent(ProjectDescriptor project, String path) async {
    return await _structuredContentBridgeService.readProjectedBodyText(
          project,
          path,
        ) ??
        _hostPort.readTextFile(project.rootPath, path);
  }

  Future<void> _restoreStructuredSnapshot({
    required ProjectDescriptor project,
    required String documentPath,
    required SqliteProjectBodyTextDocument? snapshot,
  }) async {
    try {
      await _structuredContentBridgeService.restoreStructuredDocument(
        project: project,
        documentPath: documentPath,
        snapshot: snapshot,
      );
    } catch (_) {}
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
