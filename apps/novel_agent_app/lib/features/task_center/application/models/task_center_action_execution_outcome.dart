class TaskCenterActionExecutionOutcome {
  const TaskCenterActionExecutionOutcome({
    required this.statusMessage,
    required this.nextSelectedTaskId,
  });

  final String statusMessage;
  final String nextSelectedTaskId;
}
