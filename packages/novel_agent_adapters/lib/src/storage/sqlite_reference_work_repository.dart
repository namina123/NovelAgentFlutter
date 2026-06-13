import 'package:novel_agent_core/novel_agent_core.dart';

import 'sqlite_project_information_record_store.dart';

class SqliteReferenceWorkRepository implements ReferenceWorkRepository {
  SqliteReferenceWorkRepository({
    SqliteProjectInformationRecordStore? recordStore,
    ReferenceWorkRecordCodecService? codecService,
  }) : _recordStore = recordStore ?? SqliteProjectInformationRecordStore(),
       _codecService = codecService ?? const ReferenceWorkRecordCodecService();

  static const String _recordType = 'reference_work';

  final SqliteProjectInformationRecordStore _recordStore;
  final ReferenceWorkRecordCodecService _codecService;

  @override
  Future<void> appendReferenceWork(
    ProjectDescriptor project,
    ReferenceWorkRecord record,
  ) {
    return _recordStore.upsertRecord(
      project: project,
      recordType: _recordType,
      recordId: record.referenceWorkId,
      filterKey: record.relationshipToProject,
      payload: _codecService.toJson(record),
    );
  }

  @override
  Future<List<ReferenceWorkRecord>> listReferenceWorks(
    ProjectDescriptor project, {
    String? relationshipToProject,
  }) async {
    final records = await _recordStore.listRecords(
      project: project,
      recordType: _recordType,
      filterKey: relationshipToProject,
    );
    return records.map(_codecService.fromJson).toList(growable: false);
  }

  @override
  Future<ReferenceWorkRecord?> readReferenceWork(
    ProjectDescriptor project, {
    required String referenceWorkId,
  }) async {
    final record = await _recordStore.readRecord(
      project: project,
      recordType: _recordType,
      recordId: referenceWorkId,
    );
    if (record == null) {
      return null;
    }
    return _codecService.fromJson(record);
  }

  @override
  Future<void> updateReferenceWork(
    ProjectDescriptor project,
    ReferenceWorkRecord record,
  ) {
    return appendReferenceWork(project, record);
  }
}
