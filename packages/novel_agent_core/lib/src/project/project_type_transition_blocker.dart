class ProjectTypeTransitionBlocker {
  const ProjectTypeTransitionBlocker({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;
}

abstract final class ProjectTypeTransitionBlockerCodes {
  static const String unsupportedSourceProjectType =
      'unsupported_source_project_type';
  static const String unsupportedTargetProjectType =
      'unsupported_target_project_type';
  static const String sourceProjectTypeDisabled =
      'source_project_type_disabled';
  static const String targetProjectTypeDisabled =
      'target_project_type_disabled';
  static const String sameProjectType = 'same_project_type';
  static const String transitionNotInFirstPhase =
      'transition_not_in_first_phase';
  static const String storageStrategyNotSupported =
      'storage_strategy_not_supported';
  static const String missingRuntimeBaseline = 'missing_runtime_baseline';
  static const String activeLongTaskNotArchived =
      'active_long_task_not_archived';
}
