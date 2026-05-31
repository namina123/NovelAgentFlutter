import 'expression_constraint_profile.dart';
import 'project_expression_constraint_binding.dart';

class ProjectExpressionConstraintBindingResolverService {
  const ProjectExpressionConstraintBindingResolverService();

  List<String> resolveProfileIds(
    List<ProjectExpressionConstraintBinding> bindings, {
    required List<ExpressionConstraintProfile> availableProfiles,
    String agentId = '',
    String modeId = '',
    String stageId = '',
  }) {
    final resolvedBindings = <ProjectExpressionConstraintBinding>[];
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
      resolvedBindings.add(binding);
    }
    resolvedBindings.sort((left, right) {
      if (left.defaultForProject != right.defaultForProject) {
        return left.defaultForProject ? -1 : 1;
      }
      return right.weight.compareTo(left.weight);
    });
    final availableIds = availableProfiles
        .map((profile) => profile.id)
        .where((id) => id.trim().isNotEmpty)
        .toSet();
    final profileIds = <String>[];
    for (final binding in resolvedBindings) {
      final profileId = binding.profileId.trim();
      if (profileId.isEmpty ||
          profileIds.contains(profileId) ||
          !availableIds.contains(profileId)) {
        continue;
      }
      profileIds.add(profileId);
    }
    return profileIds;
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
