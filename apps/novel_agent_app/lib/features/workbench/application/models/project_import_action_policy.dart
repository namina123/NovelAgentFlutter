class ProjectImportActionPolicy {
  const ProjectImportActionPolicy({
    required this.projectType,
    required this.resolvedTargetDirectory,
    required this.sourcePaths,
    required this.autoDeconstruct,
    required this.canAutoDeconstruct,
    required this.fileSelectionHint,
    required this.outputHint,
  });

  final String projectType;
  final String resolvedTargetDirectory;
  final List<String> sourcePaths;
  final bool autoDeconstruct;
  final bool canAutoDeconstruct;
  final String fileSelectionHint;
  final String outputHint;
}
