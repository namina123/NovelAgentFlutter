class SourceAnalysisStyleMetrics {
  const SourceAnalysisStyleMetrics({
    required this.sectionCount,
    required this.paragraphCount,
    required this.dialogueQuoteCount,
    required this.averageSectionLengthChars,
  });

  final int sectionCount;
  final int paragraphCount;
  final int dialogueQuoteCount;
  final int averageSectionLengthChars;
}
