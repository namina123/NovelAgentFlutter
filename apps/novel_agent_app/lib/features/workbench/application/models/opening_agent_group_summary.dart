import 'opening_agent_member_summary.dart';

class OpeningAgentGroupSummary {
  const OpeningAgentGroupSummary({
    required this.groupId,
    required this.displayName,
    required this.description,
    required this.isSupported,
    required this.isDegraded,
    required this.isCurrent,
    required this.isStarterGroup,
    this.reasonCodes = const <String>[],
    this.members = const <OpeningAgentMemberSummary>[],
  });

  final String groupId;
  final String displayName;
  final String description;
  final bool isSupported;
  final bool isDegraded;
  final bool isCurrent;
  final bool isStarterGroup;
  final List<String> reasonCodes;
  final List<OpeningAgentMemberSummary> members;
}
