abstract final class WritingExecutionOutcomeStatuses {
  static const String success = 'success';
  static const String recoverableFailure = 'recoverable_failure';
  static const String userActionRequired = 'user_action_required';
  static const String contentQualityIssue = 'content_quality_issue';
  static const String technicalFailure = 'technical_failure';

  static const List<String> knownValues = <String>[
    success,
    recoverableFailure,
    userActionRequired,
    contentQualityIssue,
    technicalFailure,
  ];
}
