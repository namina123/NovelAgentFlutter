import 'package:novel_agent_core/novel_agent_core.dart';

import 'sqlite_project_information_record_store.dart';

class SqliteResearchNoteRepository implements ResearchNoteRepository {
  SqliteResearchNoteRepository({
    SqliteProjectInformationRecordStore? recordStore,
    ResearchNoteCodecService? codecService,
  }) : _recordStore = recordStore ?? SqliteProjectInformationRecordStore(),
       _codecService = codecService ?? const ResearchNoteCodecService();

  static const String _recordType = 'research_note';

  final SqliteProjectInformationRecordStore _recordStore;
  final ResearchNoteCodecService _codecService;

  @override
  Future<void> appendResearchNote(
    ProjectDescriptor project,
    ResearchNote note,
  ) {
    return _recordStore.upsertRecord(
      project: project,
      recordType: _recordType,
      recordId: note.researchId,
      filterKey: note.sourceKind,
      payload: _codecService.toJson(note),
    );
  }

  @override
  Future<List<ResearchNote>> listResearchNotes(
    ProjectDescriptor project, {
    String? sourceKind,
  }) async {
    final records = await _recordStore.listRecords(
      project: project,
      recordType: _recordType,
      filterKey: sourceKind,
    );
    return records.map(_codecService.fromJson).toList(growable: false);
  }

  @override
  Future<ResearchNote?> readResearchNote(
    ProjectDescriptor project, {
    required String researchId,
  }) async {
    final record = await _recordStore.readRecord(
      project: project,
      recordType: _recordType,
      recordId: researchId,
    );
    if (record == null) {
      return null;
    }
    return _codecService.fromJson(record);
  }

  @override
  Future<void> updateResearchNote(
    ProjectDescriptor project,
    ResearchNote note,
  ) {
    return appendResearchNote(project, note);
  }
}
