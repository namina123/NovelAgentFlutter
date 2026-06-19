class BookDeconstructionSmartImportResult {
  const BookDeconstructionSmartImportResult({
    required this.applied,
    required this.normalizedSourceText,
    this.reportPath = '',
    this.reportContent = '',
    this.tempWorkspaceRootPath = '',
    this.note = '',
  });

  final bool applied;
  final String normalizedSourceText;
  final String reportPath;
  final String reportContent;
  final String tempWorkspaceRootPath;
  final String note;
}
