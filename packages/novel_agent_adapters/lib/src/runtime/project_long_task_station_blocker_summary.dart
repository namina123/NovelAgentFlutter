class ProjectLongTaskStationBlockerSummary {
  const ProjectLongTaskStationBlockerSummary({
    required this.code,
    required this.note,
    required this.detail,
    required this.controlSummary,
    required this.blockingCheckpointTitles,
    required this.runRecordPath,
  });

  final String code;
  final String note;
  final String detail;
  final String controlSummary;
  final List<String> blockingCheckpointTitles;
  final String runRecordPath;
}
