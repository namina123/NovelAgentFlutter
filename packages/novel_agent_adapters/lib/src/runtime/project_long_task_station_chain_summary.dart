import 'project_long_task_station_chain_item.dart';

class ProjectLongTaskStationChainSummary {
  const ProjectLongTaskStationChainSummary({
    required this.title,
    required this.subtitle,
    required this.nextRunnableTitle,
    required this.blockingCheckpointTitles,
    required this.items,
  });

  final String title;
  final String subtitle;
  final String nextRunnableTitle;
  final List<String> blockingCheckpointTitles;
  final List<ProjectLongTaskStationChainItem> items;
}
