class ProjectStrategy {
  const ProjectStrategy({
    required this.id,
    required this.title,
    required this.description,
    this.supportedModeIds = const <String>[],
  });

  final String id;
  final String title;
  final String description;
  final List<String> supportedModeIds;
}
