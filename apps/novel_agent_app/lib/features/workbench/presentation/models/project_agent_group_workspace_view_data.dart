import 'package:flutter/foundation.dart';

import 'project_agent_group_option_view_data.dart';
import 'project_agent_group_unsupported_view_data.dart';

@immutable
class ProjectAgentGroupWorkspaceViewData {
  const ProjectAgentGroupWorkspaceViewData({
    required this.title,
    required this.description,
    required this.currentGroupLabel,
    required this.primaryAgentLabel,
    required this.primaryAgentDescription,
    required this.selectionHint,
    required this.supportedGroups,
    required this.unsupportedGroups,
    this.statusMessage = '',
  });

  final String title;
  final String description;
  final String currentGroupLabel;
  final String primaryAgentLabel;
  final String primaryAgentDescription;
  final String selectionHint;
  final List<ProjectAgentGroupOptionViewData> supportedGroups;
  final List<ProjectAgentGroupUnsupportedViewData> unsupportedGroups;
  final String statusMessage;

  bool get hasSelectableGroups => supportedGroups.isNotEmpty;

  ProjectAgentGroupWorkspaceViewData copyWith({
    String? title,
    String? description,
    String? currentGroupLabel,
    String? primaryAgentLabel,
    String? primaryAgentDescription,
    String? selectionHint,
    List<ProjectAgentGroupOptionViewData>? supportedGroups,
    List<ProjectAgentGroupUnsupportedViewData>? unsupportedGroups,
    String? statusMessage,
  }) {
    // 中文注释: 项目级智能体组浮层在切换过程中只更新局部状态，因此单独提供 copyWith。
    return ProjectAgentGroupWorkspaceViewData(
      title: title ?? this.title,
      description: description ?? this.description,
      currentGroupLabel: currentGroupLabel ?? this.currentGroupLabel,
      primaryAgentLabel: primaryAgentLabel ?? this.primaryAgentLabel,
      primaryAgentDescription:
          primaryAgentDescription ?? this.primaryAgentDescription,
      selectionHint: selectionHint ?? this.selectionHint,
      supportedGroups: supportedGroups ?? this.supportedGroups,
      unsupportedGroups: unsupportedGroups ?? this.unsupportedGroups,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}
