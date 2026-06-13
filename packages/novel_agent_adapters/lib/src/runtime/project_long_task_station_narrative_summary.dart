import 'project_long_task_station_item_summary.dart';

class ProjectLongTaskStationNarrativeSummary {
  const ProjectLongTaskStationNarrativeSummary({
    required this.activation,
    required this.delivery,
    required this.review,
    required this.continuity,
    required this.information,
    this.expressionConstraint,
    required this.projectionItems,
    required this.permissionItems,
    required this.informationProjectionItems,
    required this.informationPermissionItems,
    this.recentExpressionConstraintItems =
        const <ProjectLongTaskStationItemSummary>[],
  });

  final ProjectLongTaskStationItemSummary? activation;
  final ProjectLongTaskStationItemSummary? delivery;
  final ProjectLongTaskStationItemSummary? review;
  final ProjectLongTaskStationItemSummary? continuity;
  final ProjectLongTaskStationItemSummary? information;
  final ProjectLongTaskStationItemSummary? expressionConstraint;
  final List<ProjectLongTaskStationItemSummary> projectionItems;
  final List<ProjectLongTaskStationItemSummary> permissionItems;
  final List<ProjectLongTaskStationItemSummary> informationProjectionItems;
  final List<ProjectLongTaskStationItemSummary> informationPermissionItems;
  final List<ProjectLongTaskStationItemSummary> recentExpressionConstraintItems;

  bool get hasContent =>
      activation != null ||
      delivery != null ||
      review != null ||
      continuity != null ||
      information != null ||
      expressionConstraint != null ||
      projectionItems.isNotEmpty ||
      permissionItems.isNotEmpty ||
      informationProjectionItems.isNotEmpty ||
      informationPermissionItems.isNotEmpty ||
      recentExpressionConstraintItems.isNotEmpty;
}
