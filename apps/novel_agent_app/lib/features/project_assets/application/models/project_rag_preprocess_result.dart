class ProjectRagPreprocessResult {
  const ProjectRagPreprocessResult({
    required this.ok,
    required this.normalizedSourceText,
    required this.displaySourceName,
    required this.recentSourcePath,
    this.note = '',
    this.usedSmartNormalization = false,
  });

  final bool ok;
  final String normalizedSourceText;
  final String displaySourceName;
  final String recentSourcePath;
  final String note;
  final bool usedSmartNormalization;
}
