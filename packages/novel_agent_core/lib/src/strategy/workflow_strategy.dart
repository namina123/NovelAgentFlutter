class WorkflowStrategy {
  const WorkflowStrategy({
    required this.id,
    required this.title,
    required this.description,
    this.supportsResumableTasks = false,
    this.supportsGuidedOpening = false,
  });

  final String id;
  final String title;
  final String description;
  final bool supportsResumableTasks;
  final bool supportsGuidedOpening;
}
