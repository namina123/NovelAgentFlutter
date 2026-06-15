class ProjectImportExecutionResult {
  const ProjectImportExecutionResult({
    required this.ok,
    required this.summary,
    required this.importedPaths,
    required this.skippedPaths,
    required this.autoDeconstructionApplied,
    required this.autoDeconstructionPreviewPath,
    required this.smartAnalysisApplied,
    required this.smartAnalysisReportPath,
  });

  final bool ok;
  final String summary;
  final List<String> importedPaths;
  final List<String> skippedPaths;
  final bool autoDeconstructionApplied;
  final String autoDeconstructionPreviewPath;
  final bool smartAnalysisApplied;
  final String smartAnalysisReportPath;
}
