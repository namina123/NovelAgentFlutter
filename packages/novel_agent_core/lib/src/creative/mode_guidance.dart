class ModeGuidance {
  const ModeGuidance({
    required this.modeId,
    required this.title,
    required this.summary,
    this.currentStageTitle = '',
    this.confirmedFacts = const <String>[],
    this.boundaries = const <String>[],
    this.sourcePath = '',
    this.metadata = const <String, Object?>{},
  });

  final String modeId;
  final String title;
  final String summary;
  final String currentStageTitle;
  final List<String> confirmedFacts;
  final List<String> boundaries;
  final String sourcePath;
  final Map<String, Object?> metadata;

  bool get isEmpty =>
      modeId.trim().isEmpty &&
      title.trim().isEmpty &&
      summary.trim().isEmpty &&
      confirmedFacts.isEmpty &&
      boundaries.isEmpty;
}
