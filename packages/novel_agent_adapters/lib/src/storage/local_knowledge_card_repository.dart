import 'package:novel_agent_core/novel_agent_core.dart';

import 'open_narrative_state_index_document_service.dart';
import 'project_information_path_service.dart';
import 'project_json_document_service.dart';

class LocalKnowledgeCardRepository implements KnowledgeCardRepository {
  LocalKnowledgeCardRepository({
    required ProjectWorkspacePort workspacePort,
    ProjectJsonDocumentService? jsonDocumentService,
    ProjectInformationPathService? pathService,
    ProjectKnowledgeCardCodecService? codecService,
  }) : _jsonDocumentService =
           jsonDocumentService ??
           ProjectJsonDocumentService(workspacePort: workspacePort),
       _pathService = pathService ?? ProjectInformationPathService(),
       _codecService = codecService ?? const ProjectKnowledgeCardCodecService(),
       _indexDocumentService = OpenNarrativeStateIndexDocumentService(
         jsonDocumentService:
             jsonDocumentService ??
             ProjectJsonDocumentService(workspacePort: workspacePort),
       );

  final ProjectJsonDocumentService _jsonDocumentService;
  final ProjectInformationPathService _pathService;
  final ProjectKnowledgeCardCodecService _codecService;
  final OpenNarrativeStateIndexDocumentService _indexDocumentService;

  @override
  Future<void> appendKnowledgeCard(
    ProjectDescriptor project,
    ProjectKnowledgeCard card,
  ) async {
    // 中文注释: 知识卡属于结构化事实源，适配器层只负责稳定写入 JSON 与 index，不解释业务语义。
    await _jsonDocumentService.writeJsonMap(
      project.rootPath,
      _pathService.knowledgeCardPath(card.cardId),
      _codecService.toJson(card),
    );
    await _ensureCardId(project, card.cardId);
  }

  @override
  Future<List<ProjectKnowledgeCard>> listKnowledgeCards(
    ProjectDescriptor project, {
    String? cardNamespace,
  }) async {
    final result = <ProjectKnowledgeCard>[];
    for (final cardId in await _readCardIds(project)) {
      final card = await readKnowledgeCard(project, cardId: cardId);
      if (card == null) {
        continue;
      }
      if (cardNamespace != null && card.cardNamespace != cardNamespace) {
        continue;
      }
      result.add(card);
    }
    return result;
  }

  @override
  Future<ProjectKnowledgeCard?> readKnowledgeCard(
    ProjectDescriptor project, {
    required String cardId,
  }) async {
    final document = await _jsonDocumentService.readJsonMap(
      project.rootPath,
      _pathService.knowledgeCardPath(cardId),
    );
    if (document.isEmpty) {
      return null;
    }
    return _codecService.fromJson(document);
  }

  @override
  Future<void> updateKnowledgeCard(
    ProjectDescriptor project,
    ProjectKnowledgeCard card,
  ) {
    // 中文注释: update 在本地 JSON 仓储里与 append 同口径，确保事实源始终以最后一次完整文档为准。
    return appendKnowledgeCard(project, card);
  }

  Future<void> _ensureCardId(ProjectDescriptor project, String cardId) async {
    final existingIds = await _readCardIds(project);
    await _writeCardIds(project, <String>[
      ...existingIds.where((id) => id != cardId),
      cardId,
    ]);
  }

  Future<List<String>> _readCardIds(ProjectDescriptor project) {
    return _indexDocumentService.readIds(
      project.rootPath,
      _pathService.knowledgeCardsIndexPath(),
      fieldName: 'knowledge_card_ids',
    );
  }

  Future<void> _writeCardIds(ProjectDescriptor project, List<String> ids) {
    return _indexDocumentService.writeIds(
      project.rootPath,
      _pathService.knowledgeCardsIndexPath(),
      fieldName: 'knowledge_card_ids',
      ids: ids,
    );
  }
}
