class BookDeconstructionSmartImportResult {
  const BookDeconstructionSmartImportResult({
    required this.applied,
    required this.normalizedSourceText,
    this.rulesPath = '',
    this.rulesContent = '',
    this.reportPath = '',
    this.reportContent = '',
    this.tempWorkspaceRootPath = '',
    this.note = '',
  });

  final bool applied;
  final String normalizedSourceText;
  final String rulesPath;
  final String rulesContent;
  final String reportPath;
  final String reportContent;
  final String tempWorkspaceRootPath;
  final String note;

  BookDeconstructionSmartImportResult copyWith({
    bool? applied,
    String? normalizedSourceText,
    String? rulesPath,
    String? rulesContent,
    String? reportPath,
    String? reportContent,
    String? tempWorkspaceRootPath,
    String? note,
  }) {
    return BookDeconstructionSmartImportResult(
      applied: applied ?? this.applied,
      normalizedSourceText: normalizedSourceText ?? this.normalizedSourceText,
      rulesPath: rulesPath ?? this.rulesPath,
      rulesContent: rulesContent ?? this.rulesContent,
      reportPath: reportPath ?? this.reportPath,
      reportContent: reportContent ?? this.reportContent,
      tempWorkspaceRootPath: tempWorkspaceRootPath ?? this.tempWorkspaceRootPath,
      note: note ?? this.note,
    );
  }
}
