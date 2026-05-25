class AutonomyPolicy {
  const AutonomyPolicy({
    required this.id,
    required this.title,
    required this.description,
    this.allowAutonomousPlanning = false,
    this.allowAutonomousDrafting = false,
    this.allowAutonomousRevision = false,
  });

  final String id;
  final String title;
  final String description;
  final bool allowAutonomousPlanning;
  final bool allowAutonomousDrafting;
  final bool allowAutonomousRevision;
}
