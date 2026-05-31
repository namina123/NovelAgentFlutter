import 'agent_availability_reason_code.dart';

class AgentAvailabilityReason {
  const AgentAvailabilityReason({
    required this.code,
    this.subjectId = '',
    this.detailIds = const <String>[],
  });

  final AgentAvailabilityReasonCode code;
  final String subjectId;
  final List<String> detailIds;
}
