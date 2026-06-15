class ReferenceSourceDocumentFileReadResult {
  const ReferenceSourceDocumentFileReadResult({
    required this.sourceFilePath,
    required this.sourceTitle,
    required this.sourceText,
    required this.decodeMode,
  });

  final String sourceFilePath;
  final String sourceTitle;
  final String sourceText;
  final String decodeMode;
}
