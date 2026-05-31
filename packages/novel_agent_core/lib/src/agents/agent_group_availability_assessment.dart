import 'agent_availability_reason.dart';
import 'resolved_agent_group_member_profile.dart';
import 'resolved_agent_group_profile.dart';

class AgentGroupAvailabilityAssessment {
  const AgentGroupAvailabilityAssessment({
    required this.group,
    required this.isSupported,
    required this.isDegraded,
    this.supportedMembers = const <ResolvedAgentGroupMemberProfile>[],
    this.prunedMembers = const <ResolvedAgentGroupMemberProfile>[],
    this.reasons = const <AgentAvailabilityReason>[],
  });

  final ResolvedAgentGroupProfile group;
  final bool isSupported;
  final bool isDegraded;
  final List<ResolvedAgentGroupMemberProfile> supportedMembers;
  final List<ResolvedAgentGroupMemberProfile> prunedMembers;
  final List<AgentAvailabilityReason> reasons;
}
