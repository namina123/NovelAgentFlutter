import 'package:novel_agent_core/novel_agent_core.dart';

import 'open_narrative_state_index_document_service.dart';
import 'project_information_path_service.dart';
import 'project_json_document_service.dart';

class LocalDesignElementRepository implements DesignElementRepository {
  LocalDesignElementRepository({
    required ProjectWorkspacePort workspacePort,
    ProjectJsonDocumentService? jsonDocumentService,
    ProjectInformationPathService? pathService,
    DesignElementCardCodecService? codecService,
  }) : _jsonDocumentService =
           jsonDocumentService ??
           ProjectJsonDocumentService(workspacePort: workspacePort),
       _pathService = pathService ?? ProjectInformationPathService(),
       _codecService = codecService ?? const DesignElementCardCodecService(),
       _indexDocumentService = OpenNarrativeStateIndexDocumentService(
         jsonDocumentService:
             jsonDocumentService ??
             ProjectJsonDocumentService(workspacePort: workspacePort),
       );

  final ProjectJsonDocumentService _jsonDocumentService;
  final ProjectInformationPathService _pathService;
  final DesignElementCardCodecService _codecService;
  final OpenNarrativeStateIndexDocumentService _indexDocumentService;

  @override
  Future<void> appendDesignElement(
    ProjectDescriptor project,
    DesignElementCard card,
  ) async {
    // 中文注释: 设计元素以独立 JSON 文档持久化，确保巧思/结构设计不会退化成散落 Markdown 提示词。
    await _jsonDocumentService.writeJsonMap(
      project.rootPath,
      _pathService.designElementPath(card.designId),
      _codecService.toJson(card),
    );
    await _ensureDesignId(project, card.designId);
  }

  @override
  Future<List<DesignElementCard>> listDesignElements(
    ProjectDescriptor project, {
    String? designNamespace,
  }) async {
    final result = <DesignElementCard>[];
    for (final designId in await _readDesignIds(project)) {
      final card = await readDesignElement(project, designId: designId);
      if (card == null) {
        continue;
      }
      if (designNamespace != null && card.designNamespace != designNamespace) {
        continue;
      }
      result.add(card);
    }
    return result;
  }

  @override
  Future<DesignElementCard?> readDesignElement(
    ProjectDescriptor project, {
    required String designId,
  }) async {
    final document = await _jsonDocumentService.readJsonMap(
      project.rootPath,
      _pathService.designElementPath(designId),
    );
    if (document.isEmpty) {
      return null;
    }
    return _codecService.fromJson(document);
  }

  @override
  Future<void> updateDesignElement(
    ProjectDescriptor project,
    DesignElementCard card,
  ) {
    // 中文注释: update 直接覆盖最新设计元素文档，让 adapter 侧的语义保持简单稳定。
    return appendDesignElement(project, card);
  }

  Future<void> _ensureDesignId(
    ProjectDescriptor project,
    String designId,
  ) async {
    final existingIds = await _readDesignIds(project);
    await _writeDesignIds(project, <String>[
      ...existingIds.where((id) => id != designId),
      designId,
    ]);
  }

  Future<List<String>> _readDesignIds(ProjectDescriptor project) {
    return _indexDocumentService.readIds(
      project.rootPath,
      _pathService.designElementsIndexPath(),
      fieldName: 'design_element_ids',
    );
  }

  Future<void> _writeDesignIds(ProjectDescriptor project, List<String> ids) {
    return _indexDocumentService.writeIds(
      project.rootPath,
      _pathService.designElementsIndexPath(),
      fieldName: 'design_element_ids',
      ids: ids,
    );
  }
}
