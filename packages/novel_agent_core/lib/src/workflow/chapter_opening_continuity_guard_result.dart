class ChapterOpeningContinuityGuardResult {
  const ChapterOpeningContinuityGuardResult({
    required this.blocked,
    this.reason = '',
    this.summary = '',
    this.openingExcerpt = '',
    this.previousExcerpt = '',
    this.longestCommonSpan = 0,
    this.openingCoverage = 0,
    this.previousCoverage = 0,
    this.replayedClauses = const <String>[],
    this.replayedActionAnchors = const <String>[],
  });

  final bool blocked;
  final String reason;
  final String summary;
  final String openingExcerpt;
  final String previousExcerpt;
  final int longestCommonSpan;
  final double openingCoverage;
  final double previousCoverage;
  final List<String> replayedClauses;
  final List<String> replayedActionAnchors;

  bool get hasSignal =>
      longestCommonSpan > 0 ||
      openingCoverage > 0 ||
      previousCoverage > 0 ||
      replayedClauses.isNotEmpty ||
      replayedActionAnchors.isNotEmpty;
}
