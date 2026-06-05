import 'project_long_task_station_item_summary.dart';

class ProjectLongTaskStationNarrativeSummary {
  const ProjectLongTaskStationNarrativeSummary({
    required this.activation,
    required this.delivery,
    required this.review,
    required this.continuity,
    required this.information,
    required this.projectionItems,
    required this.permissionItems,
    required this.informationProjectionItems,
    required this.informationPermissionItems,
  });

  final ProjectLongTaskStationItemSummary? activation;
  final ProjectLongTaskStationItemSummary? delivery;
  final ProjectLongTaskStationItemSummary? review;
  final ProjectLongTaskStationItemSummary? continuity;
  final ProjectLongTaskStationItemSummary? information;
  final List<ProjectLongTaskStationItemSummary> projectionItems;
  final List<ProjectLongTaskStationItemSummary> permissionItems;
  final List<ProjectLongTaskStationItemSummary> informationProjectionItems;
  final List<ProjectLongTaskStationItemSummary> informationPermissionItems;

  bool get hasContent =>
      activation != null ||
      delivery != null ||
      review != null ||
      continuity != null ||
      information != null ||
      projectionItems.isNotEmpty ||
      permissionItems.isNotEmpty ||
      informationProjectionItems.isNotEmpty ||
      informationPermissionItems.isNotEmpty;
}
