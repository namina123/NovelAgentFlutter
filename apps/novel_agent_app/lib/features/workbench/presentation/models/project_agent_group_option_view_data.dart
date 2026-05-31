import 'package:flutter/foundation.dart';

import '../../application/models/opening_agent_member_summary.dart';

@immutable
class ProjectAgentGroupOptionViewData {
  const ProjectAgentGroupOptionViewData({
    required this.groupId,
    required this.displayName,
    required this.description,
    required this.isCurrent,
    required this.isDegraded,
    this.members = const <OpeningAgentMemberSummary>[],
  });

  final String groupId;
  final String displayName;
  final String description;
  final bool isCurrent;
  final bool isDegraded;
  final List<OpeningAgentMemberSummary> members;
}
