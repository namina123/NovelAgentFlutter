class ProjectConstitution {
  const ProjectConstitution({
    required this.id,
    required this.title,
    required this.summary,
    this.principles = const <String>[],
    this.prohibitions = const <String>[],
    this.naturalExpressionRules = const <String>[],
    this.sourcePath = '',
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String title;
  final String summary;
  final List<String> principles;
  final List<String> prohibitions;
  final List<String> naturalExpressionRules;
  final String sourcePath;
  final Map<String, Object?> metadata;

  bool get isEmpty =>
      id.trim().isEmpty &&
      title.trim().isEmpty &&
      summary.trim().isEmpty &&
      principles.isEmpty &&
      prohibitions.isEmpty &&
      naturalExpressionRules.isEmpty;
}
