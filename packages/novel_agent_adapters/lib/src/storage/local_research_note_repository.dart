import 'package:novel_agent_core/novel_agent_core.dart';

import 'open_narrative_state_index_document_service.dart';
import 'project_information_path_service.dart';
import 'project_json_document_service.dart';

class LocalResearchNoteRepository implements ResearchNoteRepository {
  LocalResearchNoteRepository({
    required ProjectWorkspacePort workspacePort,
    ProjectJsonDocumentService? jsonDocumentService,
    ProjectInformationPathService? pathService,
    ResearchNoteCodecService? codecService,
  }) : _jsonDocumentService =
           jsonDocumentService ??
           ProjectJsonDocumentService(workspacePort: workspacePort),
       _pathService = pathService ?? ProjectInformationPathService(),
       _codecService = codecService ?? const ResearchNoteCodecService(),
       _indexDocumentService = OpenNarrativeStateIndexDocumentService(
         jsonDocumentService:
             jsonDocumentService ??
             ProjectJsonDocumentService(workspacePort: workspacePort),
       );

  final ProjectJsonDocumentService _jsonDocumentService;
  final ProjectInformationPathService _pathService;
  final ResearchNoteCodecService _codecService;
  final OpenNarrativeStateIndexDocumentService _indexDocumentService;

  @override
  Future<void> appendResearchNote(
    ProjectDescriptor project,
    ResearchNote note,
  ) async {
    // 中文注释: 研究笔记先沉淀为本地 JSON 事实文档，后续是否提升为知识规则由更高层决定。
    await _jsonDocumentService.writeJsonMap(
      project.rootPath,
      _pathService.researchNotePath(note.researchId),
      _codecService.toJson(note),
    );
    await _ensureResearchId(project, note.researchId);
  }

  @override
  Future<List<ResearchNote>> listResearchNotes(
    ProjectDescriptor project, {
    String? sourceKind,
  }) async {
    final result = <ResearchNote>[];
    for (final researchId in await _readResearchIds(project)) {
      final note = await readResearchNote(project, researchId: researchId);
      if (note == null) {
        continue;
      }
      if (sourceKind != null && note.sourceKind != sourceKind) {
        continue;
      }
      result.add(note);
    }
    return result;
  }

  @override
  Future<ResearchNote?> readResearchNote(
    ProjectDescriptor project, {
    required String researchId,
  }) async {
    final document = await _jsonDocumentService.readJsonMap(
      project.rootPath,
      _pathService.researchNotePath(researchId),
    );
    if (document.isEmpty) {
      return null;
    }
    return _codecService.fromJson(document);
  }

  @override
  Future<void> updateResearchNote(
    ProjectDescriptor project,
    ResearchNote note,
  ) {
    // 中文注释: update 继续走完整写回，避免 adapter 仓储承担字段级 patch 语义。
    return appendResearchNote(project, note);
  }

  Future<void> _ensureResearchId(
    ProjectDescriptor project,
    String researchId,
  ) async {
    final existingIds = await _readResearchIds(project);
    await _writeResearchIds(project, <String>[
      ...existingIds.where((id) => id != researchId),
      researchId,
    ]);
  }

  Future<List<String>> _readResearchIds(ProjectDescriptor project) {
    return _indexDocumentService.readIds(
      project.rootPath,
      _pathService.researchNotesIndexPath(),
      fieldName: 'research_note_ids',
    );
  }

  Future<void> _writeResearchIds(ProjectDescriptor project, List<String> ids) {
    return _indexDocumentService.writeIds(
      project.rootPath,
      _pathService.researchNotesIndexPath(),
      fieldName: 'research_note_ids',
      ids: ids,
    );
  }
}
