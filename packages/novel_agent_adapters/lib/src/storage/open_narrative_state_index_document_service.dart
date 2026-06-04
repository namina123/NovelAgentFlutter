import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_json_document_service.dart';

class OpenNarrativeStateIndexDocumentService {
  OpenNarrativeStateIndexDocumentService({
    required ProjectJsonDocumentService jsonDocumentService,
  }) : _jsonDocumentService = jsonDocumentService;

  final ProjectJsonDocumentService _jsonDocumentService;

  Future<List<String>> readIds(
    String rootPath,
    String relativePath, {
    required String fieldName,
  }) async {
    final document = await _jsonDocumentService.readJsonMap(
      rootPath,
      relativePath,
    );
    return ValueReaders.stringList(document[fieldName]);
  }

  Future<void> writeIds(
    String rootPath,
    String relativePath, {
    required String fieldName,
    required List<String> ids,
  }) {
    final cleanIds = <String>[];
    for (final id in ids) {
      final clean = id.trim();
      if (clean.isEmpty || cleanIds.contains(clean)) {
        continue;
      }
      cleanIds.add(clean);
    }
    return _jsonDocumentService.writeJsonMap(
      rootPath,
      relativePath,
      <String, Object?>{'schema_version': 1, fieldName: cleanIds},
    );
  }
}
