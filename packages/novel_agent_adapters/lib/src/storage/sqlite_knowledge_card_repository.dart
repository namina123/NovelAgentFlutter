import 'package:novel_agent_core/novel_agent_core.dart';

import 'sqlite_project_information_record_store.dart';

class SqliteKnowledgeCardRepository implements KnowledgeCardRepository {
  SqliteKnowledgeCardRepository({
    SqliteProjectInformationRecordStore? recordStore,
    ProjectKnowledgeCardCodecService? codecService,
  }) : _recordStore = recordStore ?? SqliteProjectInformationRecordStore(),
       _codecService = codecService ?? const ProjectKnowledgeCardCodecService();

  static const String _recordType = 'knowledge_card';

  final SqliteProjectInformationRecordStore _recordStore;
  final ProjectKnowledgeCardCodecService _codecService;

  @override
  Future<void> appendKnowledgeCard(
    ProjectDescriptor project,
    ProjectKnowledgeCard card,
  ) {
    return _recordStore.upsertRecord(
      project: project,
      recordType: _recordType,
      recordId: card.cardId,
      filterKey: card.cardNamespace,
      payload: _codecService.toJson(card),
    );
  }

  @override
  Future<List<ProjectKnowledgeCard>> listKnowledgeCards(
    ProjectDescriptor project, {
    String? cardNamespace,
  }) async {
    final records = await _recordStore.listRecords(
      project: project,
      recordType: _recordType,
      filterKey: cardNamespace,
    );
    return records.map(_codecService.fromJson).toList(growable: false);
  }

  @override
  Future<ProjectKnowledgeCard?> readKnowledgeCard(
    ProjectDescriptor project, {
    required String cardId,
  }) async {
    final record = await _recordStore.readRecord(
      project: project,
      recordType: _recordType,
      recordId: cardId,
    );
    if (record == null) {
      return null;
    }
    return _codecService.fromJson(record);
  }

  @override
  Future<void> updateKnowledgeCard(
    ProjectDescriptor project,
    ProjectKnowledgeCard card,
  ) {
    return appendKnowledgeCard(project, card);
  }
}
