import 'agent_profile.dart';

class ResolvedAgentGroupMemberProfile {
  const ResolvedAgentGroupMemberProfile({
    required this.profile,
    required this.isPrimary,
    required this.isRequired,
  });

  final AgentProfile profile;
  final bool isPrimary;
  final bool isRequired;

  bool get isOptional => !isRequired;
}
