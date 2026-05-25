class InspirationPremise {
  const InspirationPremise({
    required this.id,
    required this.displayName,
    required this.summary,
    this.corePromise = '',
    this.mainConflict = '',
    this.boundaries = const <String>[],
    this.sourcePath = '',
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String displayName;
  final String summary;
  final String corePromise;
  final String mainConflict;
  final List<String> boundaries;
  final String sourcePath;
  final Map<String, Object?> metadata;
}
