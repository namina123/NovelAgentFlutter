import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_agent_skill_loadout_document_codec_service.dart';
import 'project_agent_skill_loadout_path_service.dart';
import 'project_json_document_service.dart';

class ProjectAgentSkillLoadoutRepository {
  ProjectAgentSkillLoadoutRepository({
    required ProjectWorkspacePort workspacePort,
    ProjectJsonDocumentService? jsonDocumentService,
    ProjectAgentSkillLoadoutDocumentCodecService? codecService,
  }) : _jsonDocumentService =
           jsonDocumentService ??
           ProjectJsonDocumentService(workspacePort: workspacePort),
       _codecService =
           codecService ?? ProjectAgentSkillLoadoutDocumentCodecService();

  final ProjectJsonDocumentService _jsonDocumentService;
  final ProjectAgentSkillLoadoutDocumentCodecService _codecService;

  Future<List<AgentSkillLoadout>> loadLoadouts(
    ProjectDescriptor project,
  ) async {
    // 中文注释: 当前项目技能装载永远从项目隐藏设置目录读取，确保不会串到别的项目。
    final document = await _jsonDocumentService.readJsonMap(
      project.rootPath,
      ProjectAgentSkillLoadoutPathService.relativePath,
    );
    if (document.isEmpty) {
      return const <AgentSkillLoadout>[];
    }
    return _codecService.parseDocument(document);
  }

  Future<void> saveLoadouts(
    ProjectDescriptor project,
    List<AgentSkillLoadout> loadouts,
  ) {
    // 中文注释: 持久化时统一走 loadout codec，后续 GUI/CLI 只操作强类型装载对象。
    return _jsonDocumentService.writeJsonMap(
      project.rootPath,
      ProjectAgentSkillLoadoutPathService.relativePath,
      _codecService.toDocument(loadouts),
    );
  }
}
