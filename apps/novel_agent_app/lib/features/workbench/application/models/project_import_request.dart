class ProjectImportRequest {
  const ProjectImportRequest({
    required this.sourcePaths,
    required this.targetDirectory,
    required this.autoDeconstruct,
    this.smartAnalysis = false,
    this.smartAnalysisProviderId = '',
    this.smartAnalysisModelId = '',
    this.smartDeconstruction = false,
    this.smartDeconstructionProviderId = '',
    this.smartDeconstructionModelId = '',
  });

  final List<String> sourcePaths;
  final String targetDirectory;
  final bool autoDeconstruct;
  final bool smartAnalysis;
  final String smartAnalysisProviderId;
  final String smartAnalysisModelId;
  final bool smartDeconstruction;
  final String smartDeconstructionProviderId;
  final String smartDeconstructionModelId;
}
