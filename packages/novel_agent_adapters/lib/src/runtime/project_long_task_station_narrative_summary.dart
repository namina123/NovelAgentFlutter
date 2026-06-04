import 'project_long_task_station_item_summary.dart';

class ProjectLongTaskStationNarrativeSummary {
  const ProjectLongTaskStationNarrativeSummary({
    required this.activation,
    required this.delivery,
    required this.review,
    required this.continuity,
    required this.projectionItems,
    required this.permissionItems,
  });

  final ProjectLongTaskStationItemSummary? activation;
  final ProjectLongTaskStationItemSummary? delivery;
  final ProjectLongTaskStationItemSummary? review;
  final ProjectLongTaskStationItemSummary? continuity;
  final List<ProjectLongTaskStationItemSummary> projectionItems;
  final List<ProjectLongTaskStationItemSummary> permissionItems;

  bool get hasContent =>
      activation != null ||
      delivery != null ||
      review != null ||
      continuity != null ||
      projectionItems.isNotEmpty ||
      permissionItems.isNotEmpty;
}
