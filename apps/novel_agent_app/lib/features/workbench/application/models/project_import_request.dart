class ProjectImportRequest {
  const ProjectImportRequest({
    required this.sourcePaths,
    required this.targetDirectory,
    required this.autoDeconstruct,
    this.smartAnalysis = false,
    this.analysisAgentId = '',
    this.analysisAgentGroupId = '',
  });

  final List<String> sourcePaths;
  final String targetDirectory;
  final bool autoDeconstruct;
  final bool smartAnalysis;
  final String analysisAgentId;
  final String analysisAgentGroupId;
}
