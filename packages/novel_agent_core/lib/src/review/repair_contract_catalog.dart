abstract final class RepairTaskStatuses {
  static const String queued = 'queued';
  static const String inProgress = 'in_progress';
  static const String waitingUser = 'waiting_user';
  static const String completed = 'completed';
  static const String failed = 'failed';
  static const String cancelled = 'cancelled';

  static const List<String> knownValues = <String>[
    queued,
    inProgress,
    waitingUser,
    completed,
    failed,
    cancelled,
  ];
}

abstract final class RepairOutcomeStatuses {
  static const String completed = 'completed';
  static const String noteOnly = 'note_only';
  static const String waitingUser = 'waiting_user';
  static const String manualAttention = 'manual_attention';
  static const String failed = 'failed';
  static const String cancelled = 'cancelled';

  static const List<String> knownValues = <String>[
    completed,
    noteOnly,
    waitingUser,
    manualAttention,
    failed,
    cancelled,
  ];
}

abstract final class RepairHandoffActions {
  static const String none = 'none';
  static const String noteOnly = 'note_only';
  static const String adjustNext = 'adjust_next';
  static const String createBlockingRepair = 'create_blocking_repair';
  static const String waitingUser = 'waiting_user';
  static const String manualAttention = 'manual_attention';

  static const List<String> knownValues = <String>[
    none,
    noteOnly,
    adjustNext,
    createBlockingRepair,
    waitingUser,
    manualAttention,
  ];
}

abstract final class RepairContractValidationCodes {
  static const String missingRepairRequestId = 'missing_repair_request_id';
  static const String missingRepairSourceReviewId =
      'missing_repair_source_review_id';
  static const String missingRepairSourceDisposition =
      'missing_repair_source_disposition';
  static const String missingRepairBrief = 'missing_repair_brief';
  static const String missingRepairTargetPaths = 'missing_repair_target_paths';
  static const String missingRepairFindingIds = 'missing_repair_finding_ids';
  static const String missingRepairTaskId = 'missing_repair_task_id';
  static const String missingRepairTaskRequestId =
      'missing_repair_task_request_id';
  static const String invalidRepairTaskStatus = 'invalid_repair_task_status';
  static const String missingRepairTaskTitle = 'missing_repair_task_title';
  static const String missingRepairTaskGoal = 'missing_repair_task_goal';
  static const String missingRepairOutcomeRequestId =
      'missing_repair_outcome_request_id';
  static const String invalidRepairOutcomeStatus =
      'invalid_repair_outcome_status';
  static const String missingRepairOutcomeSummary =
      'missing_repair_outcome_summary';
  static const String invalidRepairHandoffAction =
      'invalid_repair_handoff_action';
  static const String repairHandoffRequiresRequest =
      'repair_handoff_requires_request';
  static const String invalidRepairBlockingResolution =
      'invalid_repair_blocking_resolution';
}
