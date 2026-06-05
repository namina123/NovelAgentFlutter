import 'package:novel_agent_core/novel_agent_core.dart';

import 'open_narrative_state_jsonl_document_service.dart';
import 'project_information_path_service.dart';

class LocalInformationEventRepository implements InformationEventRepository {
  LocalInformationEventRepository({
    required ProjectWorkspacePort workspacePort,
    ProjectInformationPathService? pathService,
  }) : _jsonlDocumentService = OpenNarrativeStateJsonlDocumentService(
         workspacePort: workspacePort,
       ),
       _pathService = pathService ?? ProjectInformationPathService();

  final OpenNarrativeStateJsonlDocumentService _jsonlDocumentService;
  final ProjectInformationPathService _pathService;

  @override
  Future<void> appendInformationEvent(
    ProjectDescriptor project,
    InformationEvent event,
  ) {
    // 中文注释: 生命周期事件天然是日志型结构，适配器层只负责把开放 JSON 稳定追加到隐藏事件流。
    return _jsonlDocumentService.appendJsonLine(
      project.rootPath,
      _pathService.informationEventsLogPath(),
      event.toJson(),
    );
  }

  @override
  Future<List<InformationEvent>> listInformationEvents(
    ProjectDescriptor project, {
    String? eventType,
    String? lifecycleStatus,
    String? subjectRefId,
  }) async {
    final latestById = <String, InformationEvent>{};
    for (final raw in await _jsonlDocumentService.readJsonLines(
      project.rootPath,
      _pathService.informationEventsLogPath(),
    )) {
      final event = InformationEvent.fromJson(raw);
      if (event.eventId.trim().isEmpty) {
        continue;
      }
      latestById.remove(event.eventId);
      latestById[event.eventId] = event;
    }
    return latestById.values
        .where((event) => eventType == null || event.eventType == eventType)
        .where(
          (event) =>
              lifecycleStatus == null ||
              event.lifecycleStatus == lifecycleStatus,
        )
        .where(
          (event) =>
              subjectRefId == null || event.subjectRef.refId == subjectRefId,
        )
        .toList(growable: false);
  }

  @override
  Future<InformationEvent?> readInformationEvent(
    ProjectDescriptor project, {
    required String eventId,
  }) async {
    final rows = await _jsonlDocumentService.readJsonLines(
      project.rootPath,
      _pathService.informationEventsLogPath(),
    );
    for (var index = rows.length - 1; index >= 0; index -= 1) {
      final event = InformationEvent.fromJson(rows[index]);
      if (event.eventId == eventId) {
        return event;
      }
    }
    return null;
  }

  @override
  Future<void> updateInformationEvent(
    ProjectDescriptor project,
    InformationEvent event,
  ) {
    // 中文注释: event update 也通过追加新日志记录表达，保持日志可审计与读取语义简单。
    return appendInformationEvent(project, event);
  }
}
