import 'package:novel_agent_core/novel_agent_core.dart';

import 'open_narrative_state_index_document_service.dart';
import 'project_json_document_service.dart';

class OpenNarrativeStateRecordDocumentService {
  OpenNarrativeStateRecordDocumentService({
    required ProjectWorkspacePort workspacePort,
    ProjectJsonDocumentService? jsonDocumentService,
  }) : _jsonDocumentService =
           jsonDocumentService ??
           ProjectJsonDocumentService(workspacePort: workspacePort),
       _indexDocumentService = OpenNarrativeStateIndexDocumentService(
         jsonDocumentService:
             jsonDocumentService ??
             ProjectJsonDocumentService(workspacePort: workspacePort),
       );

  final ProjectJsonDocumentService _jsonDocumentService;
  final OpenNarrativeStateIndexDocumentService _indexDocumentService;

  Future<void> writeIndexedRecord({
    required String rootPath,
    required String recordPath,
    required JsonMap document,
    required String indexPath,
    required String fieldName,
    required String recordId,
  }) async {
    await _jsonDocumentService.writeJsonMap(rootPath, recordPath, document);
    final existingIds = await _indexDocumentService.readIds(
      rootPath,
      indexPath,
      fieldName: fieldName,
    );
    await _indexDocumentService.writeIds(
      rootPath,
      indexPath,
      fieldName: fieldName,
      ids: <String>[...existingIds.where((id) => id != recordId), recordId],
    );
  }
}
