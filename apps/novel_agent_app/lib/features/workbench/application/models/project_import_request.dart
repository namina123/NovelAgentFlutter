class ProjectImportRequest {
  const ProjectImportRequest({
    required this.sourcePaths,
    required this.targetDirectory,
    required this.autoDeconstruct,
  });

  final List<String> sourcePaths;
  final String targetDirectory;
  final bool autoDeconstruct;
}
