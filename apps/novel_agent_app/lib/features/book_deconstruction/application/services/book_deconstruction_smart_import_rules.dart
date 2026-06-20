class BookDeconstructionSmartImportRules {
  const BookDeconstructionSmartImportRules({
    this.selectedSourcePaths = const <String>[],
    this.chapterHeadingPatterns = const <String>[],
    this.dropLineContains = const <String>[],
    this.dropLinePatterns = const <String>[],
    this.collapseBlankLines = true,
    this.insertBlankLineBetweenSources = true,
    this.trimTrailingWhitespace = true,
  });

  final List<String> selectedSourcePaths;
  final List<String> chapterHeadingPatterns;
  final List<String> dropLineContains;
  final List<String> dropLinePatterns;
  final bool collapseBlankLines;
  final bool insertBlankLineBetweenSources;
  final bool trimTrailingWhitespace;

  bool get hasAnyRule =>
      selectedSourcePaths.isNotEmpty ||
      chapterHeadingPatterns.isNotEmpty ||
      dropLineContains.isNotEmpty ||
      dropLinePatterns.isNotEmpty;
}
