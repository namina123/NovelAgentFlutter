class ProjectReferenceExtractionExecutionResult {
  const ProjectReferenceExtractionExecutionResult({
    required this.ok,
    required this.didMutateProject,
    required this.statusMessage,
  });

  final bool ok;
  final bool didMutateProject;
  final String statusMessage;
}
