class ProjectReferenceExtractionExecutionResult {
  const ProjectReferenceExtractionExecutionResult({
    required this.ok,
    required this.didMutateProject,
    required this.statusMessage,
    this.normalizationNote = '',
  });

  final bool ok;
  final bool didMutateProject;
  final String statusMessage;
  final String normalizationNote;
}
