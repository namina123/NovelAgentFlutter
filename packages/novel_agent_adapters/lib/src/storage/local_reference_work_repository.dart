import 'package:novel_agent_core/novel_agent_core.dart';

import 'open_narrative_state_index_document_service.dart';
import 'project_information_path_service.dart';
import 'project_json_document_service.dart';

class LocalReferenceWorkRepository implements ReferenceWorkRepository {
  LocalReferenceWorkRepository({
    required ProjectWorkspacePort workspacePort,
    ProjectJsonDocumentService? jsonDocumentService,
    ProjectInformationPathService? pathService,
    ReferenceWorkRecordCodecService? codecService,
  }) : _jsonDocumentService =
           jsonDocumentService ??
           ProjectJsonDocumentService(workspacePort: workspacePort),
       _pathService = pathService ?? ProjectInformationPathService(),
       _codecService = codecService ?? const ReferenceWorkRecordCodecService(),
       _indexDocumentService = OpenNarrativeStateIndexDocumentService(
         jsonDocumentService:
             jsonDocumentService ??
             ProjectJsonDocumentService(workspacePort: workspacePort),
       );

  final ProjectJsonDocumentService _jsonDocumentService;
  final ProjectInformationPathService _pathService;
  final ReferenceWorkRecordCodecService _codecService;
  final OpenNarrativeStateIndexDocumentService _indexDocumentService;

  @override
  Future<void> appendReferenceWork(
    ProjectDescriptor project,
    ReferenceWorkRecord record,
  ) async {
    // 中文注释: 引用作品边界记录继续使用单文档 JSON，便于后续用户确认与风险策略读取。
    await _jsonDocumentService.writeJsonMap(
      project.rootPath,
      _pathService.referenceWorkPath(record.referenceWorkId),
      _codecService.toJson(record),
    );
    await _ensureReferenceWorkId(project, record.referenceWorkId);
  }

  @override
  Future<List<ReferenceWorkRecord>> listReferenceWorks(
    ProjectDescriptor project, {
    String? relationshipToProject,
  }) async {
    final result = <ReferenceWorkRecord>[];
    for (final referenceWorkId in await _readReferenceWorkIds(project)) {
      final record = await readReferenceWork(
        project,
        referenceWorkId: referenceWorkId,
      );
      if (record == null) {
        continue;
      }
      if (relationshipToProject != null &&
          record.relationshipToProject != relationshipToProject) {
        continue;
      }
      result.add(record);
    }
    return result;
  }

  @override
  Future<ReferenceWorkRecord?> readReferenceWork(
    ProjectDescriptor project, {
    required String referenceWorkId,
  }) async {
    final document = await _jsonDocumentService.readJsonMap(
      project.rootPath,
      _pathService.referenceWorkPath(referenceWorkId),
    );
    if (document.isEmpty) {
      return null;
    }
    return _codecService.fromJson(document);
  }

  @override
  Future<void> updateReferenceWork(
    ProjectDescriptor project,
    ReferenceWorkRecord record,
  ) {
    // 中文注释: update 与 append 统一走同一持久化通路，确保最后一次记录成为当前事实源。
    return appendReferenceWork(project, record);
  }

  Future<void> _ensureReferenceWorkId(
    ProjectDescriptor project,
    String referenceWorkId,
  ) async {
    final existingIds = await _readReferenceWorkIds(project);
    await _writeReferenceWorkIds(project, <String>[
      ...existingIds.where((id) => id != referenceWorkId),
      referenceWorkId,
    ]);
  }

  Future<List<String>> _readReferenceWorkIds(ProjectDescriptor project) {
    return _indexDocumentService.readIds(
      project.rootPath,
      _pathService.referenceWorksIndexPath(),
      fieldName: 'reference_work_ids',
    );
  }

  Future<void> _writeReferenceWorkIds(
    ProjectDescriptor project,
    List<String> ids,
  ) {
    return _indexDocumentService.writeIds(
      project.rootPath,
      _pathService.referenceWorksIndexPath(),
      fieldName: 'reference_work_ids',
      ids: ids,
    );
  }
}
