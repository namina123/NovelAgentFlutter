enum WorkbenchPrimaryActionPlanKind { refreshProject, announce, sendPrompt }

class WorkbenchPrimaryActionPlan {
  const WorkbenchPrimaryActionPlan({
    required this.kind,
    this.prompt = '',
    this.sessionMode = '',
    this.message = '',
  });

  final WorkbenchPrimaryActionPlanKind kind;
  final String prompt;
  final String sessionMode;
  final String message;
}
