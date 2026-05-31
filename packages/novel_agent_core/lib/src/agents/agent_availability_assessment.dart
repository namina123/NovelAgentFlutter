import 'agent_availability_reason.dart';
import 'agent_profile.dart';

class AgentAvailabilityAssessment {
  const AgentAvailabilityAssessment({
    required this.profile,
    required this.isSupported,
    this.reasons = const <AgentAvailabilityReason>[],
  });

  final AgentProfile profile;
  final bool isSupported;
  final List<AgentAvailabilityReason> reasons;
}
