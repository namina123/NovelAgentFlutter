import 'agent_skill_loadout.dart';

class AgentSkillLoadoutSelectionService {
  const AgentSkillLoadoutSelectionService();

  AgentSkillLoadout? selectBestMatch({
    required String agentId,
    required String projectTypeId,
    List<AgentSkillLoadout> loadouts = const <AgentSkillLoadout>[],
  }) {
    // 中文注释: 当前运行链只拥有 agent_id 与 project_type，上层尚未提供 group/mode/stage，因此这里先做保守匹配。
    AgentSkillLoadout? bestMatch;
    var bestScore = -1;
    for (var index = 0; index < loadouts.length; index += 1) {
      final loadout = loadouts[index];
      if (!loadout.appliesToAgent(agentId)) {
        continue;
      }
      final score = _matchScore(loadout, projectTypeId: projectTypeId);
      if (score < 0) {
        continue;
      }
      final tieBreakerScore = score * 1000 + index;
      if (tieBreakerScore > bestScore) {
        bestScore = tieBreakerScore;
        bestMatch = loadout;
      }
    }
    return bestMatch;
  }

  int _matchScore(AgentSkillLoadout loadout, {required String projectTypeId}) {
    // 中文注释: 一旦 scope 里出现当前运行链无法确认的维度，就宁可暂时不命中，也不做冒进套用。
    if (loadout.scope.agentGroupIds.isNotEmpty ||
        loadout.scope.modeIds.isNotEmpty ||
        loadout.scope.stageIds.isNotEmpty) {
      return -1;
    }
    if (loadout.scope.projectTypeIds.isEmpty) {
      return 1;
    }
    final normalizedProjectTypeId = projectTypeId.trim();
    if (normalizedProjectTypeId.isEmpty) {
      return -1;
    }
    return loadout.scope.projectTypeIds.contains(normalizedProjectTypeId)
        ? 2
        : -1;
  }
}
