import 'package:flutter/foundation.dart';

@immutable
class ProjectAgentGroupPanelViewData {
  const ProjectAgentGroupPanelViewData({
    required this.currentGroupLabel,
    required this.primaryAgentLabel,
    required this.summary,
    required this.actionTitle,
    required this.actionDescription,
    required this.canConfigure,
  });

  final String currentGroupLabel;
  final String primaryAgentLabel;
  final String summary;
  final String actionTitle;
  final String actionDescription;
  final bool canConfigure;
}
