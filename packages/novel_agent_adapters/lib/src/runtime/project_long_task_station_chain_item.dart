class ProjectLongTaskStationChainItem {
  const ProjectLongTaskStationChainItem({
    required this.id,
    required this.title,
    required this.relativePath,
    required this.status,
    required this.taskType,
    required this.sortOrder,
    required this.isActive,
    required this.isNextRunnable,
    required this.isBlockingCheckpoint,
  });

  final String id;
  final String title;
  final String relativePath;
  final String status;
  final String taskType;
  final int sortOrder;
  final bool isActive;
  final bool isNextRunnable;
  final bool isBlockingCheckpoint;
}
