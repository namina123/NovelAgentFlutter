import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_agent_skill_loadout_history_document_codec_service.dart';
import 'project_agent_skill_loadout_history_path_service.dart';
import 'project_json_document_service.dart';

class ProjectAgentSkillLoadoutHistoryRepository {
  ProjectAgentSkillLoadoutHistoryRepository({
    required ProjectWorkspacePort workspacePort,
    ProjectJsonDocumentService? jsonDocumentService,
    ProjectAgentSkillLoadoutHistoryDocumentCodecService? codecService,
    ProjectAgentSkillLoadoutHistoryPathService? pathService,
  }) : _jsonDocumentService =
           jsonDocumentService ??
           ProjectJsonDocumentService(workspacePort: workspacePort),
       _codecService =
           codecService ?? ProjectAgentSkillLoadoutHistoryDocumentCodecService(),
       _pathService =
           pathService ?? const ProjectAgentSkillLoadoutHistoryPathService();

  final ProjectJsonDocumentService _jsonDocumentService;
  final ProjectAgentSkillLoadoutHistoryDocumentCodecService _codecService;
  final ProjectAgentSkillLoadoutHistoryPathService _pathService;

  Future<List<AgentSkillLoadoutHistoryEntry>> listEntries(
    ProjectDescriptor project,
  ) async {
    // 中文注释: 历史快照通过显式 index 组织，避免依赖工作区公开资源树去枚举内部隐藏目录。
    final indexDocument = await _jsonDocumentService.readJsonMap(
      project.rootPath,
      ProjectAgentSkillLoadoutHistoryPathService.indexPath,
    );
    final paths = ValueReaders.stringList(indexDocument['entry_paths']);
    final result = <AgentSkillLoadoutHistoryEntry>[];
    for (final path in paths) {
      final document = await _jsonDocumentService.readJsonMap(
        project.rootPath,
        path,
      );
      if (document.isEmpty) {
        continue;
      }
      final entry = _codecService.parseDocument(document);
      if (entry.id.trim().isEmpty) {
        continue;
      }
      result.add(entry);
    }
    result.sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return result;
  }

  Future<void> saveEntry(
    ProjectDescriptor project,
    AgentSkillLoadoutHistoryEntry entry,
  ) {
    // 中文注释: 历史记录永远显式单独写入，并同步维护 index；当前装载保存不会隐式追加历史。
    final relativePath = _pathService.filePath(entry.id);
    return _writeEntryAndIndex(project, entry, relativePath: relativePath);
  }

  Future<void> _writeEntryAndIndex(
    ProjectDescriptor project,
    AgentSkillLoadoutHistoryEntry entry, {
    required String relativePath,
  }) async {
    await _jsonDocumentService.writeJsonMap(
      project.rootPath,
      relativePath,
      _codecService.toDocument(entry),
    );
    final currentIndex = await _jsonDocumentService.readJsonMap(
      project.rootPath,
      ProjectAgentSkillLoadoutHistoryPathService.indexPath,
    );
    final nextPaths = <String>[
      ...ValueReaders.stringList(currentIndex['entry_paths']),
    ];
    if (!nextPaths.contains(relativePath)) {
      nextPaths.add(relativePath);
    }
    nextPaths.sort();
    await _jsonDocumentService.writeJsonMap(
      project.rootPath,
      ProjectAgentSkillLoadoutHistoryPathService.indexPath,
      <String, Object?>{
        'schema_version': 1,
        'entry_paths': nextPaths.cast<Object?>().toList(growable: false),
      },
    );
  }
}
