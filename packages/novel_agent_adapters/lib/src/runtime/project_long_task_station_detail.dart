import 'project_long_task_station_blocker_summary.dart';
import 'project_long_task_station_chain_summary.dart';
import 'project_long_task_station_item_summary.dart';

class ProjectLongTaskStationDetail {
  const ProjectLongTaskStationDetail({
    required this.activeTask,
    required this.chain,
    required this.latestCheckpointReview,
    required this.latestReviewReport,
    required this.latestRepairTask,
    required this.blocker,
  });

  final ProjectLongTaskStationItemSummary? activeTask;
  final ProjectLongTaskStationChainSummary? chain;
  final ProjectLongTaskStationItemSummary? latestCheckpointReview;
  final ProjectLongTaskStationItemSummary? latestReviewReport;
  final ProjectLongTaskStationItemSummary? latestRepairTask;
  final ProjectLongTaskStationBlockerSummary blocker;
}
