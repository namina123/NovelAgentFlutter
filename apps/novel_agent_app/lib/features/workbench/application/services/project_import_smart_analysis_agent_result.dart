class ProjectImportSmartAnalysisAgentResult {
  const ProjectImportSmartAnalysisAgentResult({
    required this.applied,
    this.reportPath = '',
    this.reportContent = '',
    this.resolvedModelId = '',
    this.note = '',
  });

  final bool applied;
  final String reportPath;
  final String reportContent;
  final String resolvedModelId;
  final String note;
}
