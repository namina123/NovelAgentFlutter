class ProjectLongTaskStationBlockerSummary {
  const ProjectLongTaskStationBlockerSummary({
    required this.code,
    this.category = '',
    this.label = '',
    required this.note,
    required this.detail,
    required this.controlSummary,
    required this.blockingCheckpointTitles,
    required this.runRecordPath,
  });

  final String code;
  final String category;
  final String label;
  final String note;
  final String detail;
  final String controlSummary;
  final List<String> blockingCheckpointTitles;
  final String runRecordPath;
}
