import '../common/value_readers.dart';
import 'agent_availability_assessment.dart';
import 'agent_availability_context.dart';
import 'agent_availability_reason.dart';
import 'agent_availability_reason_code.dart';
import 'agent_group_applicability_scope.dart';
import 'agent_group_availability_assessment.dart';
import 'applicability_scope_matcher_service.dart';
import 'resolved_agent_group_member_profile.dart';
import 'resolved_agent_group_profile.dart';

class AgentGroupAvailabilityResolverService {
  AgentGroupAvailabilityResolverService({
    ApplicabilityScopeMatcherService? scopeMatcherService,
  }) : _scopeMatcherService =
           scopeMatcherService ?? const ApplicabilityScopeMatcherService();

  final ApplicabilityScopeMatcherService _scopeMatcherService;

  AgentGroupAvailabilityAssessment resolve({
    required ResolvedAgentGroupProfile group,
    required AgentAvailabilityContext context,
    required List<AgentAvailabilityAssessment> memberAssessments,
    AgentGroupApplicabilityScope scope = const AgentGroupApplicabilityScope(),
  }) {
    // 中文注释: group 可用性在这里统一处理 scope、成员支持情况和降级运行策略，后续 UI 只消费结果对象。
    final reasons = <AgentAvailabilityReason>[];
    final scopeResult = _scopeMatcherService.matchAgentGroupScope(
      scope,
      projectTypeId: context.projectTypeId,
      projectTraits: context.projectTraits,
      modeId: context.modeId,
      stageId: context.stageId,
    );
    if (!scopeResult.projectTypeAllowed) {
      reasons.add(
        AgentAvailabilityReason(
          code: AgentAvailabilityReasonCode.projectTypeMismatch,
          subjectId: group.id,
        ),
      );
    }
    if (!scopeResult.modeAllowed) {
      reasons.add(
        AgentAvailabilityReason(
          code: AgentAvailabilityReasonCode.modeMismatch,
          subjectId: group.id,
        ),
      );
    }
    if (!scopeResult.stageAllowed) {
      reasons.add(
        AgentAvailabilityReason(
          code: AgentAvailabilityReasonCode.stageMismatch,
          subjectId: group.id,
        ),
      );
    }
    if (scopeResult.missingRequiredTraitIds.isNotEmpty) {
      reasons.add(
        AgentAvailabilityReason(
          code: AgentAvailabilityReasonCode.missingRequiredTraits,
          subjectId: group.id,
          detailIds: scopeResult.missingRequiredTraitIds,
        ),
      );
    }
    if (scopeResult.excludedTraitIds.isNotEmpty) {
      reasons.add(
        AgentAvailabilityReason(
          code: AgentAvailabilityReasonCode.excludedTraitsPresent,
          subjectId: group.id,
          detailIds: scopeResult.excludedTraitIds,
        ),
      );
    }

    final supportedMembers = <ResolvedAgentGroupMemberProfile>[];
    final prunedMembers = <ResolvedAgentGroupMemberProfile>[];
    final missingRequiredMembers = <String>[];
    var primarySupported = false;
    for (final member in group.members) {
      final assessment = _findAssessment(member.profile.id, memberAssessments);
      if (assessment == null || !assessment.isSupported) {
        prunedMembers.add(member);
        if (member.isRequired) {
          missingRequiredMembers.add(member.profile.id);
        }
        continue;
      }
      supportedMembers.add(member);
      if (member.isPrimary) {
        primarySupported = true;
      }
    }

    final allowDegradedRun = ValueReaders.boolValue(
      group.metadata['allow_degraded_run'],
    );
    final requirePrimaryMember = ValueReaders.boolValue(
      group.metadata['require_primary_member'],
      true,
    );
    if (supportedMembers.isEmpty) {
      reasons.add(
        AgentAvailabilityReason(
          code: AgentAvailabilityReasonCode.noSupportedMembers,
          subjectId: group.id,
        ),
      );
    }
    if (requirePrimaryMember && !primarySupported) {
      reasons.add(
        AgentAvailabilityReason(
          code: AgentAvailabilityReasonCode.primaryMemberUnavailable,
          subjectId: group.id,
          detailIds: group.primaryMember == null
              ? const <String>[]
              : <String>[group.primaryMember!.profile.id],
        ),
      );
    }
    if (missingRequiredMembers.isNotEmpty) {
      reasons.add(
        AgentAvailabilityReason(
          code: AgentAvailabilityReasonCode.missingRequiredMembers,
          subjectId: group.id,
          detailIds: missingRequiredMembers,
        ),
      );
    }

    final hardScopeFailure = reasons.any(
      (reason) =>
          reason.code == AgentAvailabilityReasonCode.projectTypeMismatch ||
          reason.code == AgentAvailabilityReasonCode.modeMismatch ||
          reason.code == AgentAvailabilityReasonCode.stageMismatch ||
          reason.code == AgentAvailabilityReasonCode.missingRequiredTraits ||
          reason.code == AgentAvailabilityReasonCode.excludedTraitsPresent,
    );
    final canRunWithoutDegrade =
        !hardScopeFailure &&
        supportedMembers.isNotEmpty &&
        (!requirePrimaryMember || primarySupported) &&
        missingRequiredMembers.isEmpty;
    if (!canRunWithoutDegrade &&
        supportedMembers.isNotEmpty &&
        allowDegradedRun &&
        (!requirePrimaryMember || primarySupported) &&
        !hardScopeFailure) {
      return AgentGroupAvailabilityAssessment(
        group: group,
        isSupported: true,
        isDegraded: true,
        supportedMembers: List<ResolvedAgentGroupMemberProfile>.unmodifiable(
          supportedMembers,
        ),
        prunedMembers: List<ResolvedAgentGroupMemberProfile>.unmodifiable(
          prunedMembers,
        ),
        reasons: List<AgentAvailabilityReason>.unmodifiable(reasons),
      );
    }
    if (!canRunWithoutDegrade && !allowDegradedRun) {
      reasons.add(
        AgentAvailabilityReason(
          code: AgentAvailabilityReasonCode.degradedRunNotAllowed,
          subjectId: group.id,
        ),
      );
    }
    return AgentGroupAvailabilityAssessment(
      group: group,
      isSupported: canRunWithoutDegrade,
      isDegraded: false,
      supportedMembers: List<ResolvedAgentGroupMemberProfile>.unmodifiable(
        supportedMembers,
      ),
      prunedMembers: List<ResolvedAgentGroupMemberProfile>.unmodifiable(
        prunedMembers,
      ),
      reasons: List<AgentAvailabilityReason>.unmodifiable(reasons),
    );
  }

  AgentAvailabilityAssessment? _findAssessment(
    String agentId,
    List<AgentAvailabilityAssessment> assessments,
  ) {
    for (final assessment in assessments) {
      if (assessment.profile.id == agentId) {
        return assessment;
      }
    }
    return null;
  }
}
