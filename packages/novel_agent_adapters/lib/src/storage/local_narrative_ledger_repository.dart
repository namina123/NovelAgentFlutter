import 'package:novel_agent_core/novel_agent_core.dart';

import 'open_narrative_state_index_document_service.dart';
import 'open_narrative_state_jsonl_document_service.dart';
import 'open_narrative_state_path_service.dart';
import 'project_json_document_service.dart';

class LocalNarrativeLedgerRepository implements NarrativeLedgerRepository {
  LocalNarrativeLedgerRepository({
    required ProjectWorkspacePort workspacePort,
    ProjectJsonDocumentService? jsonDocumentService,
    OpenNarrativeStatePathService? pathService,
    NarrativeStateLedgerCodecService? codecService,
  }) : _jsonlDocumentService = OpenNarrativeStateJsonlDocumentService(
         workspacePort: workspacePort,
       ),
       _pathService = pathService ?? OpenNarrativeStatePathService(),
       _codecService = codecService ?? const NarrativeStateLedgerCodecService(),
       _indexDocumentService = OpenNarrativeStateIndexDocumentService(
         jsonDocumentService:
             jsonDocumentService ??
             ProjectJsonDocumentService(workspacePort: workspacePort),
       );

  final OpenNarrativeStateJsonlDocumentService _jsonlDocumentService;
  final OpenNarrativeStatePathService _pathService;
  final NarrativeStateLedgerCodecService _codecService;
  final OpenNarrativeStateIndexDocumentService _indexDocumentService;

  @override
  Future<void> appendLedgerEntry(
    ProjectDescriptor project,
    NarrativeLedgerEntry entry, {
    required String ledgerId,
  }) async {
    await _jsonlDocumentService.appendJsonLine(
      project.rootPath,
      _pathService.ledgerEntriesPath(ledgerId),
      _codecService.entryToJson(entry),
    );
    await _ensureLedgerId(project, ledgerId);
  }

  @override
  Future<void> appendLedgerEvent(
    ProjectDescriptor project,
    NarrativeLedgerEvent event, {
    required String ledgerId,
  }) async {
    await _jsonlDocumentService.appendJsonLine(
      project.rootPath,
      _pathService.ledgerEventsPath(ledgerId),
      _codecService.eventToJson(event),
    );
    await _ensureLedgerId(project, ledgerId);
  }

  @override
  Future<List<NarrativeStateLedger>> listLedgers(
    ProjectDescriptor project,
  ) async {
    final result = <NarrativeStateLedger>[];
    for (final ledgerId in await _readLedgerIds(project)) {
      final ledger = await readLedger(project, ledgerId: ledgerId);
      if (ledger != null) {
        result.add(ledger);
      }
    }
    return result;
  }

  @override
  Future<NarrativeStateLedger?> readLedger(
    ProjectDescriptor project, {
    required String ledgerId,
  }) async {
    final rawEntries = await _jsonlDocumentService.readJsonLines(
      project.rootPath,
      _pathService.ledgerEntriesPath(ledgerId),
    );
    final rawEvents = await _jsonlDocumentService.readJsonLines(
      project.rootPath,
      _pathService.ledgerEventsPath(ledgerId),
    );
    if (rawEntries.isEmpty && rawEvents.isEmpty) {
      return null;
    }
    return NarrativeStateLedger(
      ledgerId: ledgerId,
      entries: rawEntries
          .map(_codecService.entryFromJson)
          .toList(growable: false),
      events: rawEvents
          .map(_codecService.eventFromJson)
          .toList(growable: false),
    );
  }

  Future<void> _ensureLedgerId(
    ProjectDescriptor project,
    String ledgerId,
  ) async {
    final existingIds = await _readLedgerIds(project);
    await _writeLedgerIds(project, <String>[
      ...existingIds.where((id) => id != ledgerId),
      ledgerId,
    ]);
  }

  Future<List<String>> _readLedgerIds(ProjectDescriptor project) {
    return _indexDocumentService.readIds(
      project.rootPath,
      _pathService.ledgersIndexPath(),
      fieldName: 'ledger_ids',
    );
  }

  Future<void> _writeLedgerIds(ProjectDescriptor project, List<String> ids) {
    return _indexDocumentService.writeIds(
      project.rootPath,
      _pathService.ledgersIndexPath(),
      fieldName: 'ledger_ids',
      ids: ids,
    );
  }
}
