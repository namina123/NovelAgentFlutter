import 'package:flutter/foundation.dart';

import 'opening_agent_group_option_view_data.dart';
import 'opening_unsupported_group_view_data.dart';

class OpeningPanelViewData {
  const OpeningPanelViewData({
    required this.title,
    required this.summary,
    required this.currentGroupDisplayName,
    required this.selectionHint,
    required this.supportedGroups,
    required this.unsupportedGroups,
  });

  final String title;
  final String summary;
  final String currentGroupDisplayName;
  final String selectionHint;
  final List<OpeningAgentGroupOptionViewData> supportedGroups;
  final List<OpeningUnsupportedGroupViewData> unsupportedGroups;

  bool get hasSelectableGroups => supportedGroups.isNotEmpty;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is OpeningPanelViewData &&
            other.title == title &&
            other.summary == summary &&
            other.currentGroupDisplayName == currentGroupDisplayName &&
            other.selectionHint == selectionHint &&
            listEquals(other.supportedGroups, supportedGroups) &&
            listEquals(other.unsupportedGroups, unsupportedGroups);
  }

  @override
  int get hashCode => Object.hash(
    title,
    summary,
    currentGroupDisplayName,
    selectionHint,
    Object.hashAll(supportedGroups),
    Object.hashAll(unsupportedGroups),
  );
}
