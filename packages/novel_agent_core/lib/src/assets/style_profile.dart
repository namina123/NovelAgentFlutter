class StyleProfile {
  const StyleProfile({
    required this.id,
    required this.displayName,
    required this.summary,
    this.genre = '',
    this.tone = '',
    this.audience = '',
    this.guardrails = const <String>[],
    this.tags = const <String>[],
    this.examplePaths = const <String>[],
    this.inheritedFromIds = const <String>[],
    this.defaultForProject = false,
    this.sourcePath = '',
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String displayName;
  final String summary;
  final String genre;
  final String tone;
  final String audience;
  final List<String> guardrails;
  final List<String> tags;
  final List<String> examplePaths;
  final List<String> inheritedFromIds;
  final bool defaultForProject;
  final String sourcePath;
  final Map<String, Object?> metadata;
}
