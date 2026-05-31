import 'package:novel_agent_core/novel_agent_core.dart';

class ProjectSkillLoadoutSaveAsGroupService {
  ProjectSkillLoadoutSaveAsGroupService({
    required ProjectWorkspacePort workspacePort,
    SkillGroupFileCodecService? codecService,
    AgentIdService? idService,
  }) : _workspacePort = workspacePort,
       _codecService = codecService ?? SkillGroupFileCodecService(),
       _idService = idService ?? AgentIdService();

  final ProjectWorkspacePort _workspacePort;
  final SkillGroupFileCodecService _codecService;
  final AgentIdService _idService;

  Future<String> saveAsGroup({
    required ProjectDescriptor project,
    required ResolvedAgentSkillLoadout loadout,
    required String groupId,
    String displayName = '',
    String description = '',
    JsonMap metadata = const <String, Object?>{},
  }) async {
    // 中文注释: 显式保存为技能组是单独动作，不自动复用历史快照，也不修改当前 loadout 文档。
    final safeGroupId = _idService.safeAgentId(groupId);
    if (safeGroupId.trim().isEmpty) {
      return '';
    }
    final relativePath = 'skill_groups/$safeGroupId/skill_group.json';
    final content = _codecService.encodeSkillGroup(<String, Object?>{
      'id': safeGroupId,
      'name': displayName.trim().isEmpty ? safeGroupId : displayName.trim(),
      'description': description.trim(),
      'source': 'project',
      'skills': loadout.finalSkillIds,
      'metadata': <String, Object?>{
        ...metadata,
        'generated_from_agent_id': loadout.agentId,
        'generated_from_loadout_source': loadout.source.id,
      },
    });
    await _workspacePort.writeTextFile(project.rootPath, relativePath, content);
    return relativePath;
  }
}
