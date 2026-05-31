import 'package:flutter/foundation.dart';

import '../../application/models/opening_agent_member_summary.dart';

class OpeningAgentGroupOptionViewData {
  const OpeningAgentGroupOptionViewData({
    required this.groupId,
    required this.displayName,
    required this.description,
    required this.isCurrent,
    required this.isDegraded,
    required this.isStarterGroup,
    this.members = const <OpeningAgentMemberSummary>[],
  });

  final String groupId;
  final String displayName;
  final String description;
  final bool isCurrent;
  final bool isDegraded;
  final bool isStarterGroup;
  final List<OpeningAgentMemberSummary> members;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is OpeningAgentGroupOptionViewData &&
            other.groupId == groupId &&
            other.displayName == displayName &&
            other.description == description &&
            other.isCurrent == isCurrent &&
            other.isDegraded == isDegraded &&
            other.isStarterGroup == isStarterGroup &&
            listEquals(other.members, members);
  }

  @override
  int get hashCode => Object.hash(
    groupId,
    displayName,
    description,
    isCurrent,
    isDegraded,
    isStarterGroup,
    Object.hashAll(members),
  );
}
