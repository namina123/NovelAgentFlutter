class TaskCenterContractActionViewData {
  const TaskCenterContractActionViewData({
    required this.id,
    required this.label,
    required this.note,
    required this.tone,
    required this.invocationKind,
    required this.enabled,
    required this.disabledReason,
    required this.ownerTaskPath,
    required this.checkpointReviewPath,
    this.isRecommended = false,
  });

  final String id;
  final String label;
  final String note;
  final String tone;
  final String invocationKind;
  final bool enabled;
  final String disabledReason;
  final String ownerTaskPath;
  final String checkpointReviewPath;
  final bool isRecommended;
}
