import 'package:novel_agent_core/novel_agent_core.dart';

import 'open_narrative_state_jsonl_document_service.dart';
import 'project_information_path_service.dart';

class LocalInformationLinkRepository implements InformationLinkRepository {
  LocalInformationLinkRepository({
    required ProjectWorkspacePort workspacePort,
    ProjectInformationPathService? pathService,
  }) : _jsonlDocumentService = OpenNarrativeStateJsonlDocumentService(
         workspacePort: workspacePort,
       ),
       _pathService = pathService ?? ProjectInformationPathService();

  final OpenNarrativeStateJsonlDocumentService _jsonlDocumentService;
  final ProjectInformationPathService _pathService;

  @override
  Future<void> appendInformationLink(
    ProjectDescriptor project,
    InformationLink link,
  ) {
    // 中文注释: 链路和事件都采用 JSONL 追加日志，保留可审计历史并通过最后一条同 ID 记录表示当前状态。
    return _jsonlDocumentService.appendJsonLine(
      project.rootPath,
      _pathService.informationLinksLogPath(),
      link.toJson(),
    );
  }

  @override
  Future<List<InformationLink>> listInformationLinks(
    ProjectDescriptor project, {
    String? linkType,
    String? sourceRefId,
    String? targetRefId,
  }) async {
    final latestById = <String, InformationLink>{};
    for (final raw in await _jsonlDocumentService.readJsonLines(
      project.rootPath,
      _pathService.informationLinksLogPath(),
    )) {
      final link = InformationLink.fromJson(raw);
      if (link.linkId.trim().isEmpty) {
        continue;
      }
      latestById.remove(link.linkId);
      latestById[link.linkId] = link;
    }
    return latestById.values
        .where((link) => linkType == null || link.linkType == linkType)
        .where(
          (link) => sourceRefId == null || link.sourceRef.refId == sourceRefId,
        )
        .where(
          (link) => targetRefId == null || link.targetRef.refId == targetRefId,
        )
        .toList(growable: false);
  }

  @override
  Future<InformationLink?> readInformationLink(
    ProjectDescriptor project, {
    required String linkId,
  }) async {
    final rows = await _jsonlDocumentService.readJsonLines(
      project.rootPath,
      _pathService.informationLinksLogPath(),
    );
    for (var index = rows.length - 1; index >= 0; index -= 1) {
      final link = InformationLink.fromJson(rows[index]);
      if (link.linkId == linkId) {
        return link;
      }
    }
    return null;
  }

  @override
  Future<void> updateInformationLink(
    ProjectDescriptor project,
    InformationLink link,
  ) {
    // 中文注释: update 对 JSONL 仓储来说就是一次新的追加记录，读取侧只取最后一条同 ID 状态。
    return appendInformationLink(project, link);
  }
}
