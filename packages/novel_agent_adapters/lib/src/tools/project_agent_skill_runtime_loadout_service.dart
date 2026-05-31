import 'package:novel_agent_core/novel_agent_core.dart';

import '../storage/project_agent_skill_loadout_repository.dart';

class ProjectAgentSkillRuntimeLoadoutService {
  ProjectAgentSkillRuntimeLoadoutService({
    required ProjectAgentSkillLoadoutRepository loadoutRepository,
    AgentSkillLoadoutSelectionService? selectionService,
    AgentSkillLoadoutResolverService? resolverService,
  }) : _loadoutRepository = loadoutRepository,
       _selectionService =
           selectionService ?? const AgentSkillLoadoutSelectionService(),
       _resolverService = resolverService ?? AgentSkillLoadoutResolverService();

  final ProjectAgentSkillLoadoutRepository _loadoutRepository;
  final AgentSkillLoadoutSelectionService _selectionService;
  final AgentSkillLoadoutResolverService _resolverService;

  Future<ResolvedAgentSkillLoadout> resolveForAgent({
    required ProjectDescriptor project,
    required JsonMap agent,
    List<Object?> availableSkillGroups = const <Object?>[],
    List<String> availableSkillIds = const <String>[],
  }) async {
    // 中文注释: 运行态解析先尝试命中当前项目的 loadout；没有命中时自动退回 agent 静态默认声明。
    final agentId = ValueReaders.stringValue(agent['id']).trim();
    final loadouts = await _loadoutRepository.loadLoadouts(project);
    final matchedLoadout = _selectionService.selectBestMatch(
      agentId: agentId,
      projectTypeId: project.projectType,
      loadouts: loadouts,
    );
    return _resolverService.resolveAgentDocument(
      agent,
      loadout: matchedLoadout,
      availableSkillGroups: availableSkillGroups,
      availableSkillIds: availableSkillIds,
    );
  }
}
