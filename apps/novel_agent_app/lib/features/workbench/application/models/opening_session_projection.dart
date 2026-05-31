import 'package:novel_agent_core/novel_agent_core.dart';

import 'opening_agent_group_summary.dart';
import 'opening_agent_member_summary.dart';
import 'opening_primary_agent_summary.dart';

class OpeningSessionProjection {
  const OpeningSessionProjection({
    required this.projectTypeId,
    required this.currentGroupId,
    required this.currentGroupDisplayName,
    required this.groupSummaries,
    required this.orchestration,
    this.availableAgentSummaries = const <OpeningAgentMemberSummary>[],
    this.currentPrimaryAgentSummary,
    this.derivedFromAgentBinding = false,
  });

  final String projectTypeId;
  final String currentGroupId;
  final String currentGroupDisplayName;
  final List<OpeningAgentGroupSummary> groupSummaries;
  final OpeningOrchestrationResult orchestration;
  final List<OpeningAgentMemberSummary> availableAgentSummaries;
  final OpeningPrimaryAgentSummary? currentPrimaryAgentSummary;
  final bool derivedFromAgentBinding;

  List<OpeningAgentGroupSummary> get supportedGroups => groupSummaries
      .where((summary) => summary.isSupported)
      .toList(growable: false);

  List<OpeningAgentGroupSummary> get unsupportedGroups => groupSummaries
      .where((summary) => !summary.isSupported)
      .toList(growable: false);
}
