import 'project_style_binding.dart';
import 'style_profile.dart';

class ProjectStyleBindingResolverService {
  const ProjectStyleBindingResolverService();

  List<String> resolveStyleIds(
    List<ProjectStyleBinding> bindings, {
    required List<StyleProfile> availableStyles,
    String agentId = '',
    String modeId = '',
    String stageId = '',
  }) {
    // 中文注释: 这里统一解析项目级默认风格与按智能体/阶段生效的风格，不让默认风格逻辑继续散落在各页面和工作流里。
    final result = <ProjectStyleBinding>[];
    for (final binding in bindings) {
      if (!binding.enabled) {
        continue;
      }
      if (!_matchesScope(binding.targetAgentIds, agentId)) {
        continue;
      }
      if (!_matchesScope(binding.targetModeIds, modeId)) {
        continue;
      }
      if (!_matchesScope(binding.targetStageIds, stageId)) {
        continue;
      }
      result.add(binding);
    }
    result.sort((left, right) {
      if (left.defaultForProject != right.defaultForProject) {
        return left.defaultForProject ? -1 : 1;
      }
      return right.weight.compareTo(left.weight);
    });
    final styleIds = <String>[];
    for (final binding in result) {
      final styleId = binding.styleId.trim();
      if (styleId.isEmpty || styleIds.contains(styleId)) {
        continue;
      }
      styleIds.add(styleId);
    }
    if (styleIds.isNotEmpty) {
      return styleIds;
    }
    for (final style in availableStyles) {
      if (style.defaultForProject && !styleIds.contains(style.id)) {
        styleIds.add(style.id);
      }
    }
    return styleIds;
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
