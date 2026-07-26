import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_structured_content_bridge_service.dart';
import 'project_timeline_path_policy.dart';

class ProjectTimelineRepository {
  ProjectTimelineRepository({
    required ProjectToolHostPort hostPort,
    ProjectTimelinePathPolicy? pathPolicy,
    TimelineRecordMarkdownParserService? parserService,
    TimelineRecordMarkdownCodecService? codecService,
    TimelineRecordNormalizerService? normalizerService,
    ProjectStructuredContentBridgeService? structuredContentBridgeService,
  }) : _hostPort = hostPort,
       _pathPolicy = pathPolicy ?? ProjectTimelinePathPolicy(),
       _parserService = parserService ?? TimelineRecordMarkdownParserService(),
       _codecService = codecService ?? TimelineRecordMarkdownCodecService(),
       _normalizerService =
           normalizerService ?? const TimelineRecordNormalizerService(),
       _structuredContentBridgeService =
           structuredContentBridgeService ??
           ProjectStructuredContentBridgeService();

  final ProjectToolHostPort _hostPort;
  final ProjectTimelinePathPolicy _pathPolicy;
  final TimelineRecordMarkdownParserService _parserService;
  final TimelineRecordMarkdownCodecService _codecService;
  final TimelineRecordNormalizerService _normalizerService;
  final ProjectStructuredContentBridgeService _structuredContentBridgeService;

  Future<TimelineRecord?> readById(
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

  Future<List<TimelineRecord>> list(ProjectDescriptor project) async {
    final entries = await _hostPort.listEntries(project.rootPath);
    final result = <TimelineRecord>[];
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
      if (!path.toLowerCase().startsWith('assets/timeline/')) {
        continue;
      }
      addRecord(document.combinedText(), path, _fallbackIdFromPath(path));
    }
    for (final entry in entries) {
      final path = ValueReaders.stringValue(entry['relative_path']);
      if (ValueReaders.boolValue(entry['is_dir']) ||
          !path.toLowerCase().startsWith('assets/timeline/')) {
        continue;
      }
      final content = await _readContent(project, path);
      addRecord(content ?? '', path, _fallbackIdFromPath(path));
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
    final content = _codecService.encode(document);
    final snapshot = await _structuredContentBridgeService
        .loadStructuredDocument(project: project, documentPath: path);
    try {
      await _structuredContentBridgeService.persistStructuredDocument(
        project: project,
        documentPath: path,
        documentKind: 'timeline_record',
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
    if (name.toLowerCase().endsWith('.timeline.md')) {
      name = name.substring(0, name.length - '.timeline.md'.length);
    } else if (name.toLowerCase().endsWith('.md')) {
      name = name.substring(0, name.length - '.md'.length);
    }
    return name.trim();
  }
}
