class ProjectReferenceExtractionExecutionResult {
  const ProjectReferenceExtractionExecutionResult({
    required this.ok,
    required this.didMutateProject,
    required this.statusMessage,
    this.normalizationNote = '',
    this.runId = '',
    this.packageId = '',
    this.packageVersionId = '',
  });

  final bool ok;
  final bool didMutateProject;
  final String statusMessage;
  final String normalizationNote;

  /// Stable identity of a publishable result. In analysis-only mode this is
  /// deliberately returned without attaching or projecting it into the
  /// project, so a later explicit confirmation can promote the same package.
  final String runId;
  final String packageId;
  final String packageVersionId;

  bool get hasStagedPackage =>
      runId.trim().isNotEmpty &&
      packageId.trim().isNotEmpty &&
      packageVersionId.trim().isNotEmpty;

  ProjectReferenceExtractionExecutionResult copyWith({
    bool? ok,
    bool? didMutateProject,
    String? statusMessage,
    String? normalizationNote,
    String? runId,
    String? packageId,
    String? packageVersionId,
  }) {
    return ProjectReferenceExtractionExecutionResult(
      ok: ok ?? this.ok,
      didMutateProject: didMutateProject ?? this.didMutateProject,
      statusMessage: statusMessage ?? this.statusMessage,
      normalizationNote: normalizationNote ?? this.normalizationNote,
      runId: runId ?? this.runId,
      packageId: packageId ?? this.packageId,
      packageVersionId: packageVersionId ?? this.packageVersionId,
    );
  }
}
