import '../project/project_trait_set.dart';
import 'agent_applicability_scope.dart';
import 'agent_group_applicability_scope.dart';
import 'applicability_match_result.dart';

class ApplicabilityScopeMatcherService {
  const ApplicabilityScopeMatcherService();

  ApplicabilityMatchResult matchAgentScope(
    AgentApplicabilityScope scope, {
    required String projectTypeId,
    required ProjectTraitSet projectTraits,
    String modeId = '',
    String stageId = '',
  }) {
    // 中文注释: 智能体适用性判断保持纯领域层，只基于项目语义和当前模式/阶段上下文判断是否可用。
    return _match(
      allowedProjectTypeIds: scope.allowedProjectTypeIds,
      requiredTraitIds: scope.requiredTraitIds,
      excludedTraitIds: scope.excludedTraitIds,
      allowedModeIds: scope.allowedModeIds,
      allowedStageIds: scope.allowedStageIds,
      projectTypeId: projectTypeId,
      projectTraits: projectTraits,
      modeId: modeId,
      stageId: stageId,
    );
  }

  ApplicabilityMatchResult matchAgentGroupScope(
    AgentGroupApplicabilityScope scope, {
    required String projectTypeId,
    required ProjectTraitSet projectTraits,
    String modeId = '',
    String stageId = '',
  }) {
    // 中文注释: 智能体组适用性与单智能体走同一套匹配逻辑，避免后续出现两套不同的作用域判断。
    return _match(
      allowedProjectTypeIds: scope.allowedProjectTypeIds,
      requiredTraitIds: scope.requiredTraitIds,
      excludedTraitIds: scope.excludedTraitIds,
      allowedModeIds: scope.allowedModeIds,
      allowedStageIds: scope.allowedStageIds,
      projectTypeId: projectTypeId,
      projectTraits: projectTraits,
      modeId: modeId,
      stageId: stageId,
    );
  }

  ApplicabilityMatchResult _match({
    required List<String> allowedProjectTypeIds,
    required List<String> requiredTraitIds,
    required List<String> excludedTraitIds,
    required List<String> allowedModeIds,
    required List<String> allowedStageIds,
    required String projectTypeId,
    required ProjectTraitSet projectTraits,
    required String modeId,
    required String stageId,
  }) {
    final cleanProjectTypeId = projectTypeId.trim();
    final cleanModeId = modeId.trim();
    final cleanStageId = stageId.trim();
    final projectTypeAllowed = _matchesScopedIds(
      allowedProjectTypeIds,
      cleanProjectTypeId,
    );
    final modeAllowed = _matchesScopedIds(allowedModeIds, cleanModeId);
    final stageAllowed = _matchesScopedIds(allowedStageIds, cleanStageId);
    final missingRequiredTraitIds = requiredTraitIds
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty && !projectTraits.containsId(item))
        .toList(growable: false);
    final blockedTraitIds = excludedTraitIds
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty && projectTraits.containsId(item))
        .toList(growable: false);
    return ApplicabilityMatchResult(
      matches:
          projectTypeAllowed &&
          modeAllowed &&
          stageAllowed &&
          missingRequiredTraitIds.isEmpty &&
          blockedTraitIds.isEmpty,
      projectTypeAllowed: projectTypeAllowed,
      modeAllowed: modeAllowed,
      stageAllowed: stageAllowed,
      missingRequiredTraitIds: missingRequiredTraitIds,
      excludedTraitIds: blockedTraitIds,
    );
  }

  bool _matchesScopedIds(List<String> scopedIds, String currentId) {
    if (scopedIds.isEmpty) {
      return true;
    }
    if (currentId.isEmpty) {
      return false;
    }
    return scopedIds.any((item) => item.trim() == currentId);
  }
}
