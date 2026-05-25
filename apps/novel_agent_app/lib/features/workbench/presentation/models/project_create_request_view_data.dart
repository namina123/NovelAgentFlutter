class ProjectCreateRequestViewData {
  const ProjectCreateRequestViewData({
    required this.title,
    required this.projectTypeId,
    required this.storageStrategyId,
    this.runtimeBaselineId = '',
  });

  final String title;
  final String projectTypeId;
  final String storageStrategyId;
  final String runtimeBaselineId;
}
