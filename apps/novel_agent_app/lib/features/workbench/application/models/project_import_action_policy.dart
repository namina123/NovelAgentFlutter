class ProjectImportActionPolicy {
  const ProjectImportActionPolicy({
    required this.projectType,
    required this.resolvedTargetDirectory,
    required this.sourcePaths,
    required this.autoDeconstruct,
    required this.canAutoDeconstruct,
    required this.smartAnalysis,
    required this.canSmartAnalyze,
    required this.smartAnalysisProviderId,
    required this.smartAnalysisModelId,
    required this.smartDeconstruction,
    required this.canSmartDeconstruction,
    required this.smartDeconstructionProviderId,
    required this.smartDeconstructionModelId,
    required this.fileSelectionHint,
    required this.outputHint,
  });

  final String projectType;
  final String resolvedTargetDirectory;
  final List<String> sourcePaths;
  final bool autoDeconstruct;
  final bool canAutoDeconstruct;
  final bool smartAnalysis;
  final bool canSmartAnalyze;
  final String smartAnalysisProviderId;
  final String smartAnalysisModelId;
  final bool smartDeconstruction;
  final bool canSmartDeconstruction;
  final String smartDeconstructionProviderId;
  final String smartDeconstructionModelId;
  final String fileSelectionHint;
  final String outputHint;
}
