class WorkflowRun {
  const WorkflowRun({
    required this.id,
    required this.projectId,
    required this.status,
  });

  final String id;
  final String projectId;
  final String status;
}
