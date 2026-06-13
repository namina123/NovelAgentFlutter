class ProjectLongTaskSummaryViewData {
  const ProjectLongTaskSummaryViewData({
    required this.title,
    required this.summary,
    required this.isLoading,
    required this.totalCount,
    required this.activeCount,
    required this.attentionCount,
    required this.runs,
  });

  final String title;
  final String summary;
  final bool isLoading;
  final int totalCount;
  final int activeCount;
  final int attentionCount;
  final List<ProjectLongTaskRunSummaryViewData> runs;

  bool get hasRuns => runs.isNotEmpty;
}

class ProjectLongTaskRunSummaryViewData {
  const ProjectLongTaskRunSummaryViewData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.taskLabel,
    required this.recentActivityLabel,
    required this.requiresAttention,
    required this.isActive,
    this.attentionCalloutTitle = '',
    this.attentionCalloutSummary = '',
    this.diagnosisLabel = '',
    this.diagnosisSummary = '',
    this.nextStepLabel = '',
    this.nextStepSummary = '',
    this.reviewSummaryLine = '',
    this.repairSummaryLine = '',
    this.checkpointSummaryLine = '',
    this.pendingSummaryLine = '',
  });

  final String id;
  final String title;
  final String subtitle;
  final String statusLabel;
  final String taskLabel;
  final String recentActivityLabel;
  final bool requiresAttention;
  final bool isActive;
  final String attentionCalloutTitle;
  final String attentionCalloutSummary;
  final String diagnosisLabel;
  final String diagnosisSummary;
  final String nextStepLabel;
  final String nextStepSummary;
  final String reviewSummaryLine;
  final String repairSummaryLine;
  final String checkpointSummaryLine;
  final String pendingSummaryLine;
}
