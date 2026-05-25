import 'project_agent_binding.dart';

class ProjectAgentBindingResolverService {
  const ProjectAgentBindingResolverService();

  List<ProjectAgentBinding> resolveActiveBindings(
    List<ProjectAgentBinding> bindings, {
    String modeId = '',
    String stageId = '',
  }) {
    // 中文注释: 绑定解析统一在这里判断 mode/stage 作用域，避免不同工作流各写一套“这个智能体当前算不算生效”。
    final result = <ProjectAgentBinding>[];
    for (final binding in bindings) {
      if (!binding.enabled) {
        continue;
      }
      if (!_matchesScope(binding.modeIds, modeId)) {
        continue;
      }
      if (!_matchesScope(binding.stageIds, stageId)) {
        continue;
      }
      result.add(binding);
    }
    result.sort((left, right) {
      if (left.selectedByDefault == right.selectedByDefault) {
        return left.agentId.compareTo(right.agentId);
      }
      return left.selectedByDefault ? -1 : 1;
    });
    return result;
  }

  ProjectAgentBinding? resolvePreferredBinding(
    List<ProjectAgentBinding> bindings, {
    String modeId = '',
    String stageId = '',
  }) {
    final active = resolveActiveBindings(
      bindings,
      modeId: modeId,
      stageId: stageId,
    );
    if (active.isEmpty) {
      return null;
    }
    return active.first;
  }

  bool _matchesScope(List<String> scopedIds, String currentId) {
    if (scopedIds.isEmpty) {
      return true;
    }
    final cleanCurrentId = currentId.trim();
    if (cleanCurrentId.isEmpty) {
      return false;
    }
    return scopedIds.contains(cleanCurrentId);
  }
}
