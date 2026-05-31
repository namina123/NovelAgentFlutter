import 'agent_applicability_scope.dart';
import 'agent_availability_assessment.dart';
import 'agent_availability_context.dart';
import 'agent_availability_reason.dart';
import 'agent_availability_reason_code.dart';
import 'applicability_scope_matcher_service.dart';
import 'project_agent_binding.dart';
import 'agent_profile.dart';

class AgentAvailabilityResolverService {
  AgentAvailabilityResolverService({
    ApplicabilityScopeMatcherService? scopeMatcherService,
  }) : _scopeMatcherService =
           scopeMatcherService ?? const ApplicabilityScopeMatcherService();

  final ApplicabilityScopeMatcherService _scopeMatcherService;

  AgentAvailabilityAssessment resolve({
    required AgentProfile profile,
    required AgentAvailabilityContext context,
    AgentApplicabilityScope scope = const AgentApplicabilityScope(),
    ProjectAgentBinding? binding,
  }) {
    // 中文注释: 单智能体可用性解析只负责项目上下文、scope 和项目绑定，不承担 group 成员裁剪或默认候选决策。
    final reasons = <AgentAvailabilityReason>[];
    if (binding != null && !binding.enabled) {
      reasons.add(
        AgentAvailabilityReason(
          code: AgentAvailabilityReasonCode.disabledByProjectBinding,
          subjectId: binding.agentId,
        ),
      );
    }
    final matchResult = _scopeMatcherService.matchAgentScope(
      scope,
      projectTypeId: context.projectTypeId,
      projectTraits: context.projectTraits,
      modeId: context.modeId,
      stageId: context.stageId,
    );
    if (!matchResult.projectTypeAllowed) {
      reasons.add(
        AgentAvailabilityReason(
          code: AgentAvailabilityReasonCode.projectTypeMismatch,
          subjectId: profile.id,
        ),
      );
    }
    if (!matchResult.modeAllowed) {
      reasons.add(
        AgentAvailabilityReason(
          code: AgentAvailabilityReasonCode.modeMismatch,
          subjectId: profile.id,
        ),
      );
    }
    if (!matchResult.stageAllowed) {
      reasons.add(
        AgentAvailabilityReason(
          code: AgentAvailabilityReasonCode.stageMismatch,
          subjectId: profile.id,
        ),
      );
    }
    if (matchResult.missingRequiredTraitIds.isNotEmpty) {
      reasons.add(
        AgentAvailabilityReason(
          code: AgentAvailabilityReasonCode.missingRequiredTraits,
          subjectId: profile.id,
          detailIds: matchResult.missingRequiredTraitIds,
        ),
      );
    }
    if (matchResult.excludedTraitIds.isNotEmpty) {
      reasons.add(
        AgentAvailabilityReason(
          code: AgentAvailabilityReasonCode.excludedTraitsPresent,
          subjectId: profile.id,
          detailIds: matchResult.excludedTraitIds,
        ),
      );
    }
    return AgentAvailabilityAssessment(
      profile: profile,
      isSupported: reasons.isEmpty,
      reasons: List<AgentAvailabilityReason>.unmodifiable(reasons),
    );
  }
}
