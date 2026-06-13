import 'package:novel_agent_core/novel_agent_core.dart';

import 'sqlite_project_information_record_store.dart';

class SqliteDesignElementRepository implements DesignElementRepository {
  SqliteDesignElementRepository({
    SqliteProjectInformationRecordStore? recordStore,
    DesignElementCardCodecService? codecService,
  }) : _recordStore = recordStore ?? SqliteProjectInformationRecordStore(),
       _codecService = codecService ?? const DesignElementCardCodecService();

  static const String _recordType = 'design_element';

  final SqliteProjectInformationRecordStore _recordStore;
  final DesignElementCardCodecService _codecService;

  @override
  Future<void> appendDesignElement(
    ProjectDescriptor project,
    DesignElementCard card,
  ) {
    return _recordStore.upsertRecord(
      project: project,
      recordType: _recordType,
      recordId: card.designId,
      filterKey: card.designNamespace,
      payload: _codecService.toJson(card),
    );
  }

  @override
  Future<List<DesignElementCard>> listDesignElements(
    ProjectDescriptor project, {
    String? designNamespace,
  }) async {
    final records = await _recordStore.listRecords(
      project: project,
      recordType: _recordType,
      filterKey: designNamespace,
    );
    return records.map(_codecService.fromJson).toList(growable: false);
  }

  @override
  Future<DesignElementCard?> readDesignElement(
    ProjectDescriptor project, {
    required String designId,
  }) async {
    final record = await _recordStore.readRecord(
      project: project,
      recordType: _recordType,
      recordId: designId,
    );
    if (record == null) {
      return null;
    }
    return _codecService.fromJson(record);
  }

  @override
  Future<void> updateDesignElement(
    ProjectDescriptor project,
    DesignElementCard card,
  ) {
    return appendDesignElement(project, card);
  }
}
