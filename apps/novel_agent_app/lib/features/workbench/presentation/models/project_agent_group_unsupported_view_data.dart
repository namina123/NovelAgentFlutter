import 'package:flutter/foundation.dart';

@immutable
class ProjectAgentGroupUnsupportedViewData {
  const ProjectAgentGroupUnsupportedViewData({
    required this.groupId,
    required this.displayName,
    required this.description,
    required this.reasonSummary,
    required this.reasonDetails,
  });

  final String groupId;
  final String displayName;
  final String description;
  final String reasonSummary;
  final List<String> reasonDetails;
}
